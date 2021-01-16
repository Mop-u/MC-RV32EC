module CompressedInstructionDecode (
    input [15:0] InstructionIn,
    output [3:0] Rs1,
    output [3:0] Rs2,
    output [3:0] Rd,
    output       ImmRs1,
    output       ImmRs2,
    output [31:0] ImmOut
);
wire [15:0] i = InstructionIn;

// Derivation of raw instruction-embedded register address
wire [3:0] BigRs2 = i[5:2];
wire [3:0] BigRs1 = i[10:7];
// Map 3-bit register addresses to 4-bit range x8-x15
wire [3:0] SmallRs2 = {1'b1,BigRs2[2:0]};
wire [3:0] SmallRs1 = {1'b1,BigRs1[2:0]};
// Select which register address format to use
wire UsingBigRs = i[1] | (i[0]&~i[15]);
wire [3:0] RawRs1 = UsingBigRs ? BigRs1 : SmallRs1;
wire [3:0] RawRs2 = UsingBigRs ? BigRs2 : SmallRs2;
// Select which register address maps to rd
wire WritesRs2 = Inst_ADDI4SPN | Inst_LW;
wire [3:0] RdRaw = WritesRs2 ? RawRs2 : RawRs1;

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

// PC Ops
wire Inst_J           = (OpcodeMain==ALUMAIN_J)             & i[13];                          
wire Inst_JAL         = (OpcodeMain==ADDI_NOP_JAL)          & i[13];                          
wire Inst_JR          = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==JR);          
wire Inst_JALR_EBREAK = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==JALR_EBREAK); // EBREAK is JALR with rs1==0
wire Inst_BEQZ_BNEZ   = (OpcodeMain==BEQZ_BNEZ); // Option bit: i[13]

// Memory Ops
wire Inst_LW          = (OpcodeMain==LW);                                                     
wire Inst_SW          = (OpcodeMain==SW);                                                     
wire Inst_LWSP        = (OpcodeMain==LWSP);                                                   
wire Inst_SWSP        = (OpcodeMain==SWSP);                                                   

// ALU Ops
wire Inst_ALUMAIN     = (OpcodeMain==ALUMAIN_J)             & !i[13] & (i[11:10]==2'b11); // Option bits: i[6:5]
wire Inst_ANDI        = (OpcodeMain==ALUMAIN_J)             & !i[13] & (i[11:10]==2'b10);     
wire Inst_SRAI_SRLI   = (OpcodeMain==ALUMAIN_J)             & !i[13] & !i[11]; // Option bit: i[10]

wire Inst_ADDI_NOP    = (OpcodeMain==ADDI_NOP_JAL)          & !i[13]; // NOP is a metainstruction
wire Inst_SLLI        = (OpcodeMain==SLLI);                                                   
wire Inst_LI          = (OpcodeMain==LI_LUI_ADDI16SP)       & (BigRs1!=2) & !i[13];           
wire Inst_LUI         = (OpcodeMain==LI_LUI_ADDI16SP)       & (BigRs1!=2) & i[13];            
wire Inst_MV          = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==MV);          
wire Inst_ADD         = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==ADD);         

// SP Write Ops
wire Inst_ADDI4SPN    = (OpcodeMain==ADDI4SPN);                                               
wire Inst_ADDI16SP    = (OpcodeMain==LI_LUI_ADDI16SP) & (BigRs1==2);                          

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
    OH_LI,
    OH_LUI,
    OH_MV,
    OH_ADD,
    OH_ADDI4SPN,
    OH_ADDI16SP
} OneHotIndices;

wire [19:0] OneHotOp;
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
assign OneHotOp[OH_LI         ] = Inst_LI;
assign OneHotOp[OH_LUI        ] = Inst_LUI;
assign OneHotOp[OH_MV         ] = Inst_MV;
assign OneHotOp[OH_ADD        ] = Inst_ADD;
assign OneHotOp[OH_ADDI4SPN   ] = Inst_ADDI4SPN;
assign OneHotOp[OH_ADDI16SP   ] = Inst_ADDI16SP;

/*  __________________________________________________________
   |                2-bit control signal tables               |
   |----------------------------------------------------------|
   |  ALUOP   | Bitwise |Arith &   |  Shift  |PC Write|  LSU  |
   | Category |  ALUOP  |Flag ALUOP|  ALUOP  |  Mode  | Width |
   |----------|---------|----------|---------|--------|-------|
 00|Bitwise   |Undefined|Signed Sub|Undefined|Inc     |LSU Nop|
 01|Arithmetic|XOR      |Signed Add|SLL      |Branch  |Word   |
 10|Shift     |OR       |Unsign Sub|SRL      |Jump Reg|Half   |
 11|Flag      |AND      |Unsign Add|SRA      |Jump Imm|Byte   |
   \----------------------------------------------------------/
*/
typedef enum bit[1:0] {
    ALUBT,
    ALUAS,
    ALUSH,
    ALUF
} LookupALUOPCategory;
typedef enum bit[1:0] {
    BT_BAD_BITWISE,
    BTXOR,
    BTOR,
    BTAND
} LookupBitwiseALUOP;
typedef enum bit[1:0] {
    ASSUBS,
    ASADDS,
    ASSUBU,
    ASADDU
} LookupArithALUOP;
typedef enum bit[1:0] {
    SH_BAD_SHIFT,
    SHSLL,
    SHSRL,
    SHSRA
} LookupShiftALUOP;
typedef enum bit[1:0] {
    PCINC,
    PCBRCH,
    PCJREG,
    PCJIMM
} LookupPCWriteMode;
typedef enum bit[1:0] {
    LSN,
    LSW,
    LSH,
    LSB
} LookupLSUWidth;
typedef enum bit {
    LO,
    HI
} LookupSingleBit;

wire [1:0] Inst_ALUMAIN_ALUCAT_LSB = ~|i[6:5];
wire [1:0] Inst_ALUMAIN_ALUOP = i[6:5];

// Control signal LUT
logic [15:0] CtrlSigLookup;
always_comb unique case(1'b1)

    // Main Dataloop Ops
    OneHotOp[OH_ALUMAIN]:  // ALUOP Category = {1'b0,~|i[6:5]}, ALUOP Opcode = i[6:5]. All register-register instructions.
        CtrlSigLookup =       {LO,        LO,      LSN,  LO,    LO,    LO,    LO,      LO,      2'b00,   2'b00, LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_ANDI]:     // Imm goes to ALUIN1.
        CtrlSigLookup =       {LO,        LO,      LSN,  HI,    LO,    LO,    HI,      LO,      ALUBT,   BTAND, LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_SRAI_SRLI]:// Choice between SRAI and SRLI is decided by raw instruction bit i[10]. Imm goes to ALUIN1.
        CtrlSigLookup =       {LO,        LO,      LSN,  HI,    LO,    LO,    HI,      LO,      ALUSH,   SHSRL, LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_ADDI_NOP]: // Imm goes to ALUIN1.
        CtrlSigLookup =       {LO,        LO,      LSN,  HI,    LO,    LO,    HI,      LO,      ALUAS,   ASADDS,LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_SLLI]:     // Imm goes to ALUIN1.
        CtrlSigLookup =       {LO,        LO,      LSN,  HI,    LO,    LO,    HI,      LO,      ALUSH,   SHSLL, LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_LI]:       // Imm goes to ALUIN1.
        CtrlSigLookup =       {LO,        LO,      LSN,  HI,    LO,    LO,    HI,      LO,      ALUBT,   BTOR,  LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_LUI]:      // Imm goes to ALUIN1.
        CtrlSigLookup =       {LO,        LO,      LSN,  HI,    LO,    LO,    HI,      LO,      ALUBT,   BTOR,  LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_MV]:       // Set rs1 to 0 to pass rs2 through the ALU to rd (rd = rs2 | 0)
        CtrlSigLookup =       {LO,        LO,      LSN,  LO,    HI,    LO,    LO,      LO,      ALUBT,   BTOR,  LO,      LO,    LO,       LO,       PCINC   };
    OneHotOp[OH_ADD]:      // Straightforward addition (rd = rs1 + rs2)
        CtrlSigLookup =       {LO,        LO,      LSN,  LO,    LO,    LO,    LO,      LO,      ALUAS,   ASADDS,LO,      LO,    LO,       LO,       PCINC   };
                            //|LSU Mode ?|LSU Sign| LSU |Change|Change|Change|ALUIN1 ?|ALUIN0 ?| ALUOP  |ALUOP | Flag ? | Flag |Link Reg |  AUIPC  |PC Write|
                            //|Load:Store| Extend |Width| rs2  | rs1  |  rd  |IMM : r2|IMM : r1|Category|Opcode|EQ : CMP|Invert|Writeback|Writeback|  Mode  |
    // Stack Pointer Ops
    OneHotOp[OH_ADDI4SPN]:
        CtrlSigLookup =       {LO,        LO,       LSN,  1'b0,  1'b0,  1'b0,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCINC   };
    OneHotOp[OH_ADDI16SP]:    
        CtrlSigLookup =       {LO,        LO,       LSN,  1'b0,  1'b0,  1'b0,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCINC   };
                            //|LSU Mode ?|LSU Sign| LSU |Change|Change|Change|ALUIN1 ?|ALUIN0 ?| ALUOP  |ALUOP | Flag ? | Flag |Link Reg |  AUIPC  |PC Write|
                            //|Load:Store| Extend |Width| rs2  | rs1  |  rd  |IMM : r2|IMM : r1|Category|Opcode|EQ : CMP|Invert|Writeback|Writeback|  Mode  |
    // Program Counter Ops
    OneHotOp[OH_J]:
        CtrlSigLookup =       {LO,        LO,       LSN,  1'b1,  1'b1,  1'b1,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCJIMM  };
    OneHotOp[OH_JAL]:         
        CtrlSigLookup =       {LO,        LO,       LSN,  1'b1,  1'b1,  1'b1,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b1,     1'b0,     PCJIMM  };
    OneHotOp[OH_JR]:          
        CtrlSigLookup =       {LO,        LO,       LSN,  1'b0,  1'b0,  1'b1,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCJREG  };
    OneHotOp[OH_JALR_EBREAK]: 
        CtrlSigLookup =       {LO,        LO,       LSN,  1'b1,  1'b0,  1'b1,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCJREG  };
    OneHotOp[OH_BEQZ_BNEZ]:   
        CtrlSigLookup =       {LO,        LO,       LSN,  1'b0,  1'b0,  1'b0,  1'b0,    1'b0,    ALUF,    BTXOR, 1'b0,    1'b0,  1'b0,     1'b0,     PCBRCH  };
                            //|LSU Mode ?|LSU Sign| LSU |Change|Change|Change|ALUIN1 ?|ALUIN0 ?| ALUOP  |ALUOP | Flag ? | Flag |Link Reg |  AUIPC  |PC Write|
                            //|Load:Store| Extend |Width| rs2  | rs1  |  rd  |IMM : r2|IMM : r1|Category|Opcode|EQ : CMP|Invert|Writeback|Writeback|  Mode  |
    // Load/Store Ops
    OneHotOp[OH_LW]:
        CtrlSigLookup =       {HI,        LO,       LSW,  1'b0,  1'b0,  1'b0,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCINC   };
    OneHotOp[OH_SW]:          
        CtrlSigLookup =       {LO,        LO,       LSW,  1'b0,  1'b0,  1'b0,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCINC   };
    OneHotOp[OH_LWSP]:        
        CtrlSigLookup =       {HI,        LO,       LSW,  1'b0,  1'b0,  1'b0,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCINC   };
    OneHotOp[OH_SWSP]:        
        CtrlSigLookup =       {LO,        LO,       LSW,  1'b0,  1'b0,  1'b0,  1'b0,    1'b0,    2'b00,   2'b00, 1'b0,    1'b0,  1'b0,     1'b0,     PCINC   };
                            //|LSU Mode ?|LSU Sign| LSU |Change|Change|Change|ALUIN1 ?|ALUIN0 ?| ALUOP  |ALUOP | Flag ? | Flag |Link Reg |  AUIPC  |PC Write|
                            //|Load:Store| Extend |Width| rs2  | rs1  |  rd  |IMM : r2|IMM : r1|Category|Opcode|EQ : CMP|Invert|Writeback|Writeback|  Mode  |

    // Zero the lookup when no valid instruction
    default: CtrlSigLookup = '0;
endcase

endmodule