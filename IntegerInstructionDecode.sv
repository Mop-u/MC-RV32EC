module IntegerInstructionDecode #(
    parameter embedded = 1
)(
    input [31:0] InstructionIn,
    output logic [raddr_w-1:0] Rs1,
    output logic [raddr_w-1:0] Rs2,
    output logic [raddr_w-1:0] Rd,
    output [31:0] ImmALU, // goes downstream
    output [31:0] ImmPC,  // critical path!
    output [3:0]  CtrlLSU,
    output        CtrlMultiCycle,
    output        CtrlALUImm,
    output [3:0]  CtrlALUOp,
    output        CtrlFlagInv,
    output        CtrlPCWriteback,
    output [1:0]  CtrlPCMode,
    output        ValidDecode
);
wire NotCompressed = (i[1:0] == 2'b11);
assign ValidDecode = NotCompressed & ValidLookup;
localparam raddr_w = embedded ? 4 : 5;
wire [31:0] i = InstructionIn;


wire [raddr_w-1:0] RawRs1 = i[19:15];
wire [raddr_w-1:0] RawRs2 = i[24:20];
wire [raddr_w-1:0] RawRd  = i[11:07];

// Sort immediate format types by associated instuction
wire ImmB = Major_BRANCH;
wire ImmS = Spicy_LOAD_STORE & i[5];
wire ImmI = ~(ImmB|ImmS|ImmJ|ImmU);
wire ImmJ = Major_JAL;
wire ImmU = Major_LUI | Major_AUIPC;

// Main immediate output
assign ImmALU[0]     = (i[7]&ImmS) | (i[20]&ImmI);
assign ImmALU[4:1]   = (i[11:8]&{4{ImmB|ImmS}}) | (i[24:21]&{4{ImmI|ImmJ}});
assign ImmALU[10:5]  = (i[30:25]&{6{~ImmU}});
assign ImmALU[11]    = (i[7]&ImmB) | (i[20]&ImmJ) | (i[31]&(ImmS|ImmI));
assign ImmALU[19:12] = (ImmJ|ImmU) ? i[19:12] : {8{i[31]}};
assign ImmALU[30:20] = (ImmU)      ? i[30:20] : {11{i[31]}};
assign ImmALU[31]    = i[31];

// Just the jump-relative immediates to ease the critical path
assign ImmPC[0]     = 1'b0;
assign ImmPC[4:1]   = (i[11:8]&{4{ImmB}}) | (i[24:21]&{4{ImmJ}});
assign ImmPC[10:5]  = i[30:25];
assign ImmPC[11]    = (i[7]&ImmB) | (i[20]&ImmJ);
assign ImmPC[19:12] = ImmJ ? i[19:12] : {8{i[31]}};
assign ImmPC[31:20] = {12{i[31]}};

// Major decode flags
wire Major_LUI     = i[6:2] == 5'b01101;
wire Major_AUIPC   = i[6:2] == 5'b00101;
wire Major_JAL     = i[6:2] == 5'b11011;
wire Major_JALR    = i[6:2] == 5'b11001;
wire Major_BRANCH  = i[6:2] == 5'b11000;
wire Major_MISCMEM = i[6:2] == 5'b00011;
wire Major_SYSTEM  = i[6:2] == 5'b11100;

// Spicy decode flags
wire Spicy_OP_OPIMM_LOAD_STORE = (i[3:2] == 2'b00) & ~i[6]; // 3-bit general decode
wire Spicy_OP_OPIMM   = Spicy_OP_OPIMM_LOAD_STORE & i[4];   // filter to just ALU-adjacent ops
wire Spicy_LOAD_STORE = Spicy_OP_OPIMM_LOAD_STORE & ~i[4];  // filter to just load/store ops
wire Spicy_FLAGMAIN   = (i[14:13] == 2'b01);                // All SLT operations
wire Spicy_SHIFTMAIN  = (i[13:12] == 2'b01);                // All shift operations
wire Spicy_ALUMAIN    = ~(Spicy_FLAGMAIN|Spicy_SHIFTMAIN);  // anything else the ALU can do

// Refined decode
wire Inst_SHIFTMAIN  = Spicy_OP_OPIMM & Spicy_SHIFTMAIN;
wire Inst_ALUMAIN    = Spicy_OP_OPIMM & Spicy_ALUMAIN;
wire Inst_FLAGMAIN   = Spicy_OP_OPIMM & Spicy_FLAGMAIN;
wire Inst_LUI        = Major_LUI;
wire Inst_AUIPC      = Major_AUIPC;
wire Inst_JAL        = Major_JAL;
wire Inst_JALR       = Major_JALR;
wire Inst_BRANCH     = Major_BRANCH;
wire Inst_LOAD_STORE = Spicy_LOAD_STORE;
wire Inst_FENCE      = Major_MISCMEM;
wire Inst_SYSTEM     = Major_SYSTEM;

`include "CtrlSigEnums.sv"
/*  _______________________________________________________________________________
   |                          2-bit control signal tables                          |
   |-------------------------------------------------------------------------------|
   |    ALUOP    | Bitwise |     Arith &     |  Shift  |   PC Write    |    LSU    |
   |   Category  |  ALUOP  |    Flag ALUOP   |  ALUOP  |     Mode      |   Width   |
   |-------------|---------|-----------------|---------|---------------|-----------|
 00|Bitwise ALUBT| ALU_NOP |Signed Sub AFSUBS|SLL SHSLL|Inc      PCINC |LSU Nop LSN|
 01|Add/Sub ALUAS|XOR BTXOR|       Add AFADD |Undefined|Branch   PCBRCH|Word    LSW|
 10|Shift   ALUSH|OR  BTOR |Unsign Sub AFSUBU|SRL SHSRL|Jump Reg PCJREG|Half    LSH|
 11|Flag    ALUFL|AND BTAND|Equality   AFEQU |SRA SHSRA|Jump Imm PCJIMM|Byte    LSB|
   \------------------------------------------------------------------------------/
*/
// Instruction bit passthrough
wire [1:0] EncShift  = {i[14],i[30]}; // i[14] ? SR : SL, i[30] ? sign-extend : zero-extend
wire [1:0] EncFlag   = {i[12],1'b0};  // i[12] ? unsigned : signed
wire [1:0] EncALUCat = {1'b0,~i[14]}; // i[14] ? bitwise : arithmetic
wire [1:0] EncBrch   = {(i[13]|~i[14]),~i[14]}; // BRANCH instruction controls map almost directly
wire [1:0] EncALUOp  = i[14] ? {i[13],(i[12]|~i[13])} // if(i[14]) Map i[13:12] to bitwise controls
                             : {1'b0,~(i[30]&i[5])};  // else      Select subtraction mode if necessary

logic [13:0] CtrlSigLookup;
logic        ValidLookup;
assign CtrlLSU         = CtrlSigLookup[10+:4];
assign CtrlMultiCycle  = CtrlSigLookup[9];
assign CtrlALUImm      = CtrlSigLookup[8];
assign CtrlALUOp       = CtrlSigLookup[4+:4];
assign CtrlFlagInv     = CtrlSigLookup[3];
assign CtrlPCWriteback = CtrlSigLookup[2];
assign CtrlPCMode      = CtrlSigLookup[0+:2];
always_comb begin
    // Set default reg addresses
    Rd  = RawRd;
    Rs1 = RawRs1;
    Rs2 = RawRs2;
    ValidLookup = 1'b1;
    unique case(1'b1)
                          //|LSU Mode ?|LSU Sign| LSU | Multi |ALUInB ?| ALUOP  |ALUOP | Flag |Link Reg |PC Write|
                          //|Load:Store| Extend |Width| Cycle |IMM : r2|Category|Opcode|Invert|Writeback|  Mode  |
        Inst_SHIFTMAIN : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     ~i[5],   ALUSH, EncShift,LO,    LO,       PCINC   };
            if(~i[5]) Rs2 = 0;
        end
        Inst_ALUMAIN   : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     ~i[5],EncALUCat,EncALUOp,LO,    LO,       PCINC   };
            if(~i[5]) Rs2 = 0;
        end
        Inst_FLAGMAIN  : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     ~i[5],   ALUFL, EncFlag, LO,    LO,       PCINC   };
            if(~i[5]) Rs2 = 0;
        end
        Inst_LUI       : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     HI,      ALUBT,   BTOR,  LO,    LO,       PCINC   };
            Rs1 = 0;
            Rs2 = 0;
        end
        Inst_AUIPC     : begin // When the PC is in increment mode, the LinkOut value is PC+Imm. ALU isn't used.
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      ALU_NOP,ALU_NOP,LO,    HI,       PCINC   };
            Rs1 = 0;
            Rs2 = 0;
        end
        Inst_JAL       : begin // ALU isn't used for immediate jumps.
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      ALU_NOP,ALU_NOP,LO,    HI,       PCJIMM  };
            Rs1 = 0;
            Rs2 = 0;
        end
        Inst_JALR      : begin // ALU not used.
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      ALU_NOP,ALU_NOP,LO,    HI,       PCJREG  };
            Rs2 = 0;
        end
        Inst_BRANCH    : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      ALUFL,  EncBrch,i[12], LO,       PCBRCH  };
            Rd = 0;
        end
        Inst_LOAD_STORE: begin
            CtrlSigLookup = {~i[5],    ~i[14],~i[13:12],LO,    HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
            if(~i[5]) Rs2 = 0;
            else      Rd  = 0;
        end
        Inst_FENCE     : begin // Unimplemented for now
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCINC   };
            ValidLookup = 1'b0;
        end
        Inst_SYSTEM    : begin // Unimplemented for now
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCINC   };
            ValidLookup = 1'b0;
        end               //|LSU Mode ?|LSU Sign| LSU | Multi |ALUInB ?| ALUOP  |ALUOP | Flag |Link Reg |PC Write|
        default: begin    //|Load:Store| Extend |Width| Cycle |IMM : r2|Category|Opcode|Invert|Writeback|  Mode  |
            CtrlSigLookup = '0;
            ValidLookup = 1'b0;
        end
    endcase
end
endmodule