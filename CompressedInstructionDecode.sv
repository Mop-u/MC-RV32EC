module CompressedInstructionDecode #(
    parameter embedded = 1
)(
    input clk,
    input [15:0] InstructionIn,
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
    output [1:0]  CtrlPCMode
);
always_ff @(posedge clk) begin
    //$display("InstructionIn: %b",InstructionIn);
    case(1'b1) 
        OneHotOp[OH_J          ]: $display("Decode: J");
        OneHotOp[OH_JAL        ]: $display("Decode: JAL");
        OneHotOp[OH_JR         ]: $display("Decode: JR");
        OneHotOp[OH_JALR_EBREAK]: $display("Decode: JALR_EBREAK");
        OneHotOp[OH_BEQZ_BNEZ  ]: $display("Decode: BEQZ_BNEZ");
        OneHotOp[OH_LW         ]: $display("Decode: LW");
        OneHotOp[OH_SW         ]: $display("Decode: SW");
        OneHotOp[OH_LWSP       ]: $display("Decode: LWSP");
        OneHotOp[OH_SWSP       ]: $display("Decode: SWSP");
        OneHotOp[OH_ALUMAIN    ]: $display("Decode: ALUMAIN");
        OneHotOp[OH_ANDI       ]: $display("Decode: ANDI");
        OneHotOp[OH_SRAI_SRLI  ]: $display("Decode: SRAI_SRLI");
        OneHotOp[OH_ADDI_NOP   ]: $display("Decode: ADDI_NOP");
        OneHotOp[OH_SLLI       ]: $display("Decode: SLLI");
        OneHotOp[OH_LI_LUI     ]: $display("Decode: LI_LUI");
        OneHotOp[OH_MV         ]: $display("Decode: MV");
        OneHotOp[OH_ADD        ]: $display("Decode: ADD");
        OneHotOp[OH_ADDI4SPN   ]: $display("Decode: ADDI4SPN");
        OneHotOp[OH_ADDI16SP   ]: $display("Decode: ADDI16SP");
    endcase
end

localparam raddr_w = embedded ? 4 : 5;
wire [15:0] i = InstructionIn;

// Derivation of raw instruction-embedded register address
wire [raddr_w-1:0] BigRs2 = i[6:2];
wire [raddr_w-1:0] BigRs1 = i[11:7];
// Map 3-bit register addresses to addr range x8-x15
wire [raddr_w-1:0] SmallRs2 = {2'b01,BigRs2[2:0]};
wire [raddr_w-1:0] SmallRs1 = {2'b01,BigRs1[2:0]};
// Select which register address format to use
wire UsingBigRs = i[1] | (i[0]&~i[15]);
wire [raddr_w-1:0] RawRs1 = UsingBigRs ? BigRs1 : SmallRs1;
wire [raddr_w-1:0] RawRs2 = UsingBigRs ? BigRs2 : SmallRs2;
// Select which register address maps to rd
wire WritesRs2 = Inst_ADDI4SPN | Inst_LW;
wire [raddr_w-1:0] RawRd = WritesRs2 ? RawRs2 : RawRs1;

//  Immediate lower 12 bits format map
//     11      10    09     08     07    06      05       04       03      02      01     00
//  {i[12],  i[12], i[12], i[12], i[12], i[12],  i[12],  i[6],    i[5],   i[4],   i[3],  i[2]} // A
//  {1'b0,   1'b0,  1'b0,  1'b0,  i[3],  i[2],   i[12],  i[6],    i[5],   i[4],   1'b0,  1'b0} // B
//  {i[12],  i[8],  i[10], i[9],  i[6],  i[7],   i[2],   i[11],   i[5],   i[4],   i[3],  1'b0} // C
//  {i[12],  i[12], i[12], i[12], i[6],  i[5],   i[2],   i[11],   i[10],  i[4],   i[3],  1'b0} // D
//  {i[12],  i[12], i[12], i[4],  i[3],  i[5],   i[2],   i[6],    1'b0,   1'b0,   1'b0,  1'b0} // E
//  {1'b0,   1'b0,  i[10], i[9],  i[8],  i[7],   i[12],  i[11],   i[5],   i[6],   1'b0,  1'b0} // F
//  {1'b0,   1'b0,  1'b0,  1'b0,  1'b0,  i[5],   i[12],  i[11],   i[10],  i[6],   1'b0,  1'b0} // G
//  {1'b0,   1'b0,  1'b0,  1'b0,  i[8],  i[7],   i[12],  i[11],   i[10],  i[9],   1'b0,  1'b0} // HI
//  {1'b0,   1'b0,  1'b0,  1'b0,  1'b0,  1'b0,   i[12],  i[6],    i[5],   i[4],   i[3],  i[2]} // I
//   ACDE:12  C:8   CF:10  CF:9   BE:3    B:2 ABFGHI:12  ABEI:6  ABCFI:5 ABCDI:4 ACDI:3  AI:2
//          ADE:12 ADE:12   E:4   CD:6  DEG:5   ECD:2  CDFGH:11  DGH:10  FG:6 
//                         AD:12  FH:8  CFH:7                            HI:9 
//                                 A:12   A:12

// Sort immediate format types by associated instuction
wire ImmA = Inst_ANDI | Inst_ADDI_NOP | Inst_LI;
wire ImmB = Inst_LWSP;
wire ImmC = Inst_J | Inst_JAL;
wire ImmD = Inst_BEQZ_BNEZ;
wire ImmE = Inst_ADDI16SP;
wire ImmF = Inst_ADDI4SPN;
wire ImmG = Inst_LW | Inst_SW;
wire ImmH = Inst_SWSP;
wire ImmI = Inst_SRAI_SRLI | Inst_SLLI;
wire ImmJ = Inst_LUI;

// ImmA and ImmI only differ by sign extension
wire ImmAI = ImmA | ImmI;

// Conditional sign extension
wire ImmSignADEC = i[12]&(ImmA|ImmD|ImmE|ImmC);
wire ImmSignADECJ = i[12]&(ImmA|ImmD|ImmE|ImmC|ImmJ);

// Per-bit immediate format multiplex
wire [31:0] RawImm;
assign RawImm[0]     = (i[02]&ImmAI);
assign RawImm[1]     = (i[03]&(ImmAI|ImmC|ImmD));
assign RawImm[2]     = (i[04]&(ImmAI|ImmB|ImmC|ImmD))        | (i[09]&ImmH)             | (i[06]&(ImmF|ImmG));
assign RawImm[3]     = (i[05]&(ImmAI|ImmB|ImmC|ImmF))        | (i[10]&(ImmD|ImmG|ImmH));
assign RawImm[4]     = (i[06]&(ImmAI|ImmB|ImmE))             | (i[11]&(ImmC|ImmD|ImmF|ImmG|ImmH));
assign RawImm[5]     = (i[12]&(ImmAI|ImmB|ImmF|ImmG|ImmH))   | (i[02]&(ImmE|ImmC|ImmD));
assign RawImm[6]     = (i[12]&ImmA) |(i[05]&(ImmD|ImmE|ImmG))| (i[02]&ImmB) | (i[07]&(ImmC|ImmF|ImmH));
assign RawImm[7]     = (i[12]&ImmA) | (i[06]&(ImmC|ImmD))    | (i[03]&(ImmB|ImmE))      | (i[08]&(ImmF|ImmH));
assign RawImm[8]     = (i[12]&(ImmA|ImmD))                   | (i[04]&ImmE)             | (i[09]&(ImmC|ImmF));
assign RawImm[9]     = (i[12]&(ImmA|ImmD|ImmE))              | (i[10]&(ImmC|ImmF));
assign RawImm[10]    = (i[12]&(ImmA|ImmD|ImmE))              | (i[08]&ImmC);
assign RawImm[11]    = ImmSignADEC;
assign RawImm[16:12] = ImmJ ? i[6:2] : {(5){ImmSignADEC}};
assign RawImm[31:17] = {(15){ImmSignADECJ}};

assign Immediate = RawImm;

// Main instruction decode
wire [3:0] OpcodeMain = {i[1:0],i[15:14]};
typedef enum bit[3:0] {
/* 00,00 */ ADDI4SPN, 
/* 00,01 */ LW,       
/* 00,10 */ BAD_2,    
/* 00,11 */ SW,       
/* 01,00 */ ADDI_NOP_JAL,
/* 01,01 */ LI_LUI_ADDI16SP,
/* 01,10 */ ALUMAIN_J,
/* 01,11 */ BEQZ_BNEZ,
/* 10,00 */ SLLI,
/* 10,01 */ LWSP,
/* 10,10 */ MV_JR_ADD_JALR_EBREAK,
/* 10,11 */ SWSP
} OpcodeMainLookup;

wire OpcodeJumpOrALU = {~|i[6:2],i[12]};
typedef enum bit[1:0] {
/* 0,0 */ MV,
/* 0,1 */ ADD,
/* 1,0 */ JR,
/* 1,1 */ JALR_EBREAK
} OpcodeJumpOrALULookup;

// Partial decodes
wire PartDec_ALUMAIN_J             = OpcodeMain == ALUMAIN_J;
wire PartDec_ADDI_NOP_JAL          = OpcodeMain == ADDI_NOP_JAL;
wire PartDec_LI_LUI_ADDI16SP       = OpcodeMain == LI_LUI_ADDI16SP;
wire PartDec_MV_JR_ADD_JALR_EBREAK = OpcodeMain == MV_JR_ADD_JALR_EBREAK;

// PC Ops
wire Inst_J           = PartDec_ALUMAIN_J    & i[13];                          
wire Inst_JAL         = PartDec_ADDI_NOP_JAL & i[13];                          
wire Inst_JR          = PartDec_MV_JR_ADD_JALR_EBREAK & (OpcodeJumpOrALU==JR);          
wire Inst_JALR_EBREAK = PartDec_MV_JR_ADD_JALR_EBREAK & (OpcodeJumpOrALU==JALR_EBREAK); // EBREAK is JALR with rs1==0
wire Inst_BEQZ_BNEZ   = (OpcodeMain==BEQZ_BNEZ); // Option bit: i[13]

// Memory Ops
wire Inst_LW          = (OpcodeMain==LW);                                                     
wire Inst_SW          = (OpcodeMain==SW);                                                     
wire Inst_LWSP        = (OpcodeMain==LWSP);                                                   
wire Inst_SWSP        = (OpcodeMain==SWSP);                                                   

// ALU Ops
wire Inst_ALUMAIN     = PartDec_ALUMAIN_J & !i[13] & (i[11:10]==2'b11); // Option bits: i[6:5]
wire Inst_ANDI        = PartDec_ALUMAIN_J & !i[13] & (i[11:10]==2'b10);     
wire Inst_SRAI_SRLI   = PartDec_ALUMAIN_J & !i[13] & !i[11]; // Option bit: i[10]

wire Inst_ADDI_NOP    = PartDec_ADDI_NOP_JAL & !i[13]; // NOP is a metainstruction
wire Inst_SLLI        = (OpcodeMain==SLLI);                                                   
wire Inst_LI          = PartDec_LI_LUI_ADDI16SP & !i[13];               // LI Signal only useful for immediate muxing
wire Inst_LUI         = PartDec_LI_LUI_ADDI16SP & (BigRs1!=2) & i[13];  // LUI Signal only useful for immediate muxing
wire Inst_LI_LUI      = PartDec_LI_LUI_ADDI16SP & ((BigRs1!=2)|!i[13]); // LI == LUI for control signal lookups.
wire Inst_MV          = PartDec_MV_JR_ADD_JALR_EBREAK & (OpcodeJumpOrALU==MV);          
wire Inst_ADD         = PartDec_MV_JR_ADD_JALR_EBREAK & (OpcodeJumpOrALU==ADD);         

// SP Write Ops
wire Inst_ADDI4SPN    = (OpcodeMain==ADDI4SPN);                                               
wire Inst_ADDI16SP    = PartDec_LI_LUI_ADDI16SP & (BigRs1==2) & i[13];                          

// Map main decode to a one-hot vector
typedef enum {
    OH_J,
    OH_JAL,
    OH_JR,
    OH_JALR_EBREAK,
    OH_BEQZ_BNEZ,
    OH_LW,
    OH_SW,
    OH_LWSP,
    OH_SWSP,
    OH_ALUMAIN,
    OH_ANDI,
    OH_SRAI_SRLI,
    OH_ADDI_NOP,
    OH_SLLI,
    OH_LI_LUI,
    OH_MV,
    OH_ADD,
    OH_ADDI4SPN,
    OH_ADDI16SP
} OneHotIndices;

wire [18:0] OneHotOp;
assign OneHotOp[OH_J          ] = Inst_J;
assign OneHotOp[OH_JAL        ] = Inst_JAL;
assign OneHotOp[OH_JR         ] = Inst_JR;
assign OneHotOp[OH_JALR_EBREAK] = Inst_JALR_EBREAK;
assign OneHotOp[OH_BEQZ_BNEZ  ] = Inst_BEQZ_BNEZ;
assign OneHotOp[OH_LW         ] = Inst_LW;
assign OneHotOp[OH_SW         ] = Inst_SW;
assign OneHotOp[OH_LWSP       ] = Inst_LWSP;
assign OneHotOp[OH_SWSP       ] = Inst_SWSP;
assign OneHotOp[OH_ALUMAIN    ] = Inst_ALUMAIN;
assign OneHotOp[OH_ANDI       ] = Inst_ANDI;
assign OneHotOp[OH_SRAI_SRLI  ] = Inst_SRAI_SRLI;
assign OneHotOp[OH_ADDI_NOP   ] = Inst_ADDI_NOP;
assign OneHotOp[OH_SLLI       ] = Inst_SLLI;
assign OneHotOp[OH_LI_LUI     ] = Inst_LI_LUI;
assign OneHotOp[OH_MV         ] = Inst_MV;
assign OneHotOp[OH_ADD        ] = Inst_ADD;
assign OneHotOp[OH_ADDI4SPN   ] = Inst_ADDI4SPN;
assign OneHotOp[OH_ADDI16SP   ] = Inst_ADDI16SP;


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
wire [1:0] EncALUCat = {1'b0,~|i[6:5]}; // This check determines if ALUMAIN instruction group is doing a subtraction or bitwise op.
wire [1:0] EncALUOp  = i[6:5];          // Opcodes from ALUMAIN instruction group map directly to the dataloop's control signals.
wire [1:0] EncSRMode = {1'b1,i[10]};    // Logical/Arithmetic mode select for SRAI/SRLI

// Control signal clean base LUT
logic [13:0] CtrlSigLookup;
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
    unique case(1'b1)
        // Main Dataloop Ops
        OneHotOp[OH_ALUMAIN]:  // EncALUCat = {1'b0,~|i[6:5]}, EncALUOp = i[6:5]. All register-register instructions.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,    EncALUCat,EncALUOp,LO,   LO,       PCINC   };
        OneHotOp[OH_ANDI]:     // Imm goes to ALUInB.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     HI,      ALUBT,   BTAND, LO,    LO,       PCINC   };
        OneHotOp[OH_SRAI_SRLI]:// Choice between SRAI and SRLI is decided by raw instruction bit i[10] @ ALUOpcode lsb. Imm goes to ALUInB.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     HI,      ALUSH,EncSRMode,LO,    LO,       PCINC   };
        OneHotOp[OH_ADDI_NOP]: // Imm goes to ALUInB.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
        OneHotOp[OH_SLLI]:     // Imm goes to ALUInB.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     HI,      ALUSH,   SHSLL, LO,    LO,       PCINC   };
        OneHotOp[OH_ADD]:      // Straightforward addition (rd = rs1 + rs2)
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,      ALUAS,   AFADD, LO,    LO,       PCINC   };
                                //|LSU Mode ?|LSU Sign| LSU | Multi |ALUInB ?| ALUOP  |ALUOP | Flag |Link Reg |PC Write|
                                //|Load:Store| Extend |Width| Cycle |IMM : r2|Category|Opcode|Invert|Writeback|  Mode  |
        
        OneHotOp[OH_LI_LUI]: begin // Imm goes to ALUInB. Set rs1 to 0 to pass rs2 through the ALU to rd. Diff between LI and LUI already determined by imm formatting
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     HI,      ALUBT,   BTOR,  LO,    LO,       PCINC   }; 
            Rs1 = 0;
        end
        OneHotOp[OH_MV]: begin // Set rs1 to 0 to pass rs2 through the ALU to rd (rd = rs2 | 0)
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,      ALUBT,   BTOR,  LO,    LO,       PCINC   };
            Rs1 = 0;
        end
        
        // Stack Pointer Ops
        OneHotOp[OH_ADDI16SP]: // Imm goes to ALUInB.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
        OneHotOp[OH_ADDI4SPN]: begin // Change rs1 to x2, imm goes to ALUInB. Unsigned addition.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
            Rs1 = 2;            //|LSU Mode ?|LSU Sign| LSU | Multi |ALUInB ?| ALUOP  |ALUOP | Flag |Link Reg |PC Write|
        end                     //|Load:Store| Extend |Width| Cycle |IMM : r2|Category|Opcode|Invert|Writeback|  Mode  |


        // Program Counter Ops
        OneHotOp[OH_J]: begin // ALU is not used, Imm feeds directly to PC in PCJIMM ops.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    LO,       PCJIMM  };
            Rd = 0;
        end
        OneHotOp[OH_JAL]: begin // ALU is not used, Imm feeds directly to PC in PCJIMM ops. Rd is set to x1 for storing the link result.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,      2'b00,   2'b00, LO,    HI,       PCJIMM  };
            Rd = 1;             //|LSU Mode ?|LSU Sign| LSU | Multi |ALUInB ?| ALUOP  |ALUOP | Flag |Link Reg |PC Write|
        end                     //|Load:Store| Extend |Width| Cycle |IMM : r2|Category|Opcode|Invert|Writeback|  Mode  |
        OneHotOp[OH_JR]: begin
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,      ALUAS,   AFADD, LO,    LO,       PCJREG  };
            Rd = 0;
        end
        OneHotOp[OH_JALR_EBREAK]: begin // Rd is set to x1 for storing the link result.
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,      ALUAS,   AFADD, LO,    HI,       PCJREG  };
            Rd = 1; // Note: EBREAK if rs1==0
        end
        OneHotOp[OH_BEQZ_BNEZ]: begin // Sets rs2 to 0 and passes rs1 through a flag check. i[13] chooses between EQZ/NEZ
            CtrlSigLookup =       {LO,        LO,      LSN,  LO,     LO,      ALUFL,   AFEQU, i[13], LO,       PCBRCH  };
            Rs2 = 0;            //|LSU Mode ?|LSU Sign| LSU | Multi |ALUInB ?| ALUOP  |ALUOP | Flag |Link Reg |PC Write|
            Rd = 0;             //|Load:Store| Extend |Width| Cycle |IMM : r2|Category|Opcode|Invert|Writeback|  Mode  |
        end
                                
        // Load/Store Ops
        OneHotOp[OH_LW]:       // Note: rd is written to later by the load/store unit. (Due to multicycle flag)
            CtrlSigLookup =       {HI,        LO,      LSW,  HI,     HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
        OneHotOp[OH_SW]: begin // Note: r2 still passes to the load/store unit. Only the ALU sees the immediate instead of r2.
            CtrlSigLookup =       {LO,        LO,      LSW,  LO,     HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
            Rd = 0;
        end
        OneHotOp[OH_LWSP]:     // Set rs1 to stack pointer x2. Note: rd is written to later by the load/store unit. (Due to multicycle flag)
            CtrlSigLookup =       {HI,        LO,      LSW,  HI,     HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
        OneHotOp[OH_SWSP]: begin // Set rs1 to stack pointer x2. Note: r2 still passes to the load/store unit. Only the ALU sees the immediate instead of r2.
            CtrlSigLookup =       {LO,        LO,      LSW,  LO,     HI,      ALUAS,   AFADD, LO,    LO,       PCINC   };
            Rs1 = 2;            //|LSU Mode ?|LSU Sign| LSU | Multi |ALUInB ?| ALUOP  |ALUOP | Flag |Link Reg |PC Write|
            Rd  = 0;            //|Load:Store| Extend |Width| Cycle |IMM : r2|Category|Opcode|Invert|Writeback|  Mode  |
        end
        
        // Zero the lookup when no valid instruction
        default: CtrlSigLookup = '0;
    endcase
end


endmodule