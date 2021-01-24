module IntegerInstructionDecode #(
    parameter embedded = 1
)(
    input [31:0] InstructionIn,
    output logic [raddr_w-1:0] Rs1,
    output logic [raddr_w-1:0] Rs2,
    output logic [raddr_w-1:0] Rd,
    output [31:0] Immediate,
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

// Immediate format multiplex
wire ImmB = Major_BRANCH;
wire ImmS = Spicy_LOAD_STORE & i[5];
wire ImmI = ~(ImmB|ImmS|ImmJ|ImmU);
wire ImmJ = Major_JAL;
wire ImmU = Major_LUI | Major_AUIPC;

wire [31:0] RawImm;
assign RawImm[0]     = (i[7]&ImmS) | (i[20]&ImmI);
assign RawImm[4:1]   = (i[11:8]&(ImmB|ImmS)) | (i[24:21]&(ImmI|ImmJ));
assign RawImm[10:5]  = (i[30:25]&~ImmU);
assign RawImm[11]    = (i[7]&ImmB) | (i[20]&ImmJ) | (i[31]&(ImmS|ImmI));
assign RawImm[19:12] = (ImmJ|ImmU) ? i[19:12] : {(8){i[31]}};
assign RawImm[30:20] = (ImmU)      ? i[30:20] : {(11){i[31]}};
assign RawImm[31]    = i[31];

assign Immediate = RawImm;

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
wire Spicy_FLAGMAIN   = (i[14:13] == 2'b01);                // SLTI/SLT/SLTIU/SLTU
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
 00|Bitwise ALUBT|Undefined|Signed Sub AFSUBS|SLL SHSLL|Inc      PCINC |LSU Nop LSN|
 01|Add/Sub ALUAS|XOR BTXOR|       Add AFADD |Undefined|Branch   PCBRCH|Word    LSW|
 10|Shift   ALUSH|OR  BTOR |Unsign Sub AFSUBU|SRL SHSRL|Jump Reg PCJREG|Half    LSH|
 11|Flag    ALUFL|AND BTAND|Equality   AFEQU |SRA SHSRA|Jump Imm PCJIMM|Byte    LSB|
   \------------------------------------------------------------------------------/
*/
// Instruction bit passthrough
wire [1:0] EncShift = {i[14],i[30]};

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
        end
        Inst_ALUMAIN   : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     ~i[5],   2'b00,   2'b00, LO,    LO,       PCINC   };
        end
        Inst_FLAGMAIN  : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     ~i[5],   2'b00,   2'b00, LO,    LO,       PCINC   };
        end
        Inst_LUI       : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     HI,      2'b00,   2'b00, LO,    LO,       PCINC   };
        end
        Inst_AUIPC     : begin // When the PC is in increment mode, the LinkOut value is PC+Imm
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    HI,       PCINC   };
        end
        Inst_JAL       : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    HI,       PCJIMM  };
        end
        Inst_JALR      : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCJREG  };
        end
        Inst_BRANCH    : begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCBRCH  };
        end
        Inst_LOAD_STORE: begin
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCINC   };
        end
        Inst_FENCE     : begin // Unimplemented for now
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCINC   };
            ValidLookup = 1'b0;
        end
        Inst_SYSTEM    : begin // Unimplemented for now
            CtrlSigLookup = {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCINC   };
            ValidLookup = 1'b0;
        end
        default: begin
            CtrlSigLookup = '0;
            ValidLookup = 1'b0;
        end
    endcase
end
endmodule