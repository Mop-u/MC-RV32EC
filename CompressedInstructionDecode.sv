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

wire [1:0] OpcodeUpper  = i[1:0];
wire [2:0] OpcodeLower  = i[15:14];
wire       OpcodeOption = i[13];
wire [3:0] OpcodeMain = {OpcodeUpper,OpcodeLower};
enum [3:0] {
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
enum [1:0] {
/* 0,0 */ MV,
/* 0,1 */ ADD,
/* 1,0 */ JR,
/* 1,1 */ JALR_EBREAK
} OpcodeJumpOrALULookup;

// PC Ops
wire Inst_J           = (OpcodeMain==ALUMAIN_J)             & OpcodeOption;                   // C
wire Inst_JAL         = (OpcodeMain==ADDI_NOP_JAL)          & OpcodeOption;                   // C
wire Inst_JR          = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==JR);          // No Imm
wire Inst_JALR_EBREAK = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==JALR_EBREAK); // No Imm
wire Inst_BEQZ_BNEZ   = (OpcodeMain==BEQZ_BNEZ);                                              // D

// Memory Ops
wire Inst_LW          = (OpcodeMain==LW);                                                     // G
wire Inst_SW          = (OpcodeMain==SW);                                                     // G
wire Inst_LWSP        = (OpcodeMain==LWSP);                                                   // B
wire Inst_SWSP        = (OpcodeMain==SWSP);                                                   // H

// ALU Ops
wire Inst_ALUMAIN     = (OpcodeMain==ALUMAIN_J)             & !OpcodeOption;                  // A/I/NoImm
wire Inst_ADDI_NOP    = (OpcodeMain==ADDI_NOP_JAL)          & !OpcodeOption;                  // A
wire Inst_SLLI        = (OpcodeMain==SLLI);                                                   // A
wire Inst_LI          = (OpcodeMain==LI_LUI_ADDI16SP)       & (BigRs1!=2) & !OpcodeOption;    // A
wire Inst_LUI         = (OpcodeMain==LI_LUI_ADDI16SP)       & (BigRs1!=2) & OpcodeOption;     // J
wire Inst_MV          = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==MV);          // No Imm
wire Inst_ADD         = (OpcodeMain==MV_JR_ADD_JALR_EBREAK) & (OpcodeJumpOrALU==ADD);         // No Imm

// SP Write Ops
wire Inst_ADDI4SPN    = (OpcodeMain==ADDI4SPN);                                               // F
wire Inst_ADDI16SP    = (OpcodeMain==LI_LUI_ADDI16SP) & (BigRs1==2);                          // E

//wire [7:0][11:0] ImmLower = {
////     11      10    09     08     07    06      05       04       03      02      01     00
//    {i[12],  i[12], i[12], i[12], i[12], i[12],  i[12],  i[6],    i[5],   i[4],   i[3],  i[2]}, // A
//    {1'b0,   1'b0,  1'b0,  1'b0,  i[3],  i[2],   i[12],  i[6],    i[5],   i[4],   1'b0,  1'b0}, // B
//    {i[12],  i[8],  i[10], i[9],  i[6],  i[7],   i[2],   i[11],   i[5],   i[4],   i[3],  1'b0}, // C
//    {i[12],  i[12], i[12], i[12], i[6],  i[5],   i[2],   i[11],   i[10],  i[4],   i[3],  1'b0}, // D
//    {i[12],  i[12], i[12], i[4],  i[3],  i[5],   i[2],   i[6],    1'b0,   1'b0,   1'b0,  1'b0}, // E
//    {1'b0,   1'b0,  i[10], i[9],  i[8],  i[7],   i[12],  i[11],   i[5],   i[6],   1'b0,  1'b0}, // F
//    {1'b0,   1'b0,  1'b0,  1'b0,  1'b0,  i[5],   i[12],  i[11],   i[10],  i[6],   1'b0,  1'b0}, // G
//    {1'b0,   1'b0,  1'b0,  1'b0,  i[8],  i[7],   i[12],  i[11],   i[10],  i[9],   1'b0,  1'b0}, // H
//    {1'b0,   1'b0,  1'b0,  1'b0,  1'b0,  1'b0,   i[12],  i[6],    i[5],   i[4],   i[3],  i[2]}  // I
////   ACDE:12  C:8   CF:10  CF:9   BE:3    B:2 ABFGHI:12  ABEI:6  ABCFI:5 ABCDI:4 ACDI:3  AI:2
////          ADE:12 ADE:12   E:4   CD:6  DEG:5   ECD:2  CDFGH:11  DGH:10  FG:6 
////                         AD:12  FH:8  CFH:7                            H:9 
////                                 A:12   A:12
//};

wire ImmA = Inst_ADDI_NOP | Inst_LI;
wire ImmB = Inst_LWSP;
wire ImmC = Inst_J | Inst_JAL;
wire ImmD = Inst_BEQZ_BNEZ;
wire ImmE = Inst_ADDI16SP;
wire ImmF = Inst_ADDI4SPN;
wire ImmG = Inst_LW | Inst_SW;
wire ImmH = Inst_SWSP;
wire ImmI = (Inst_ALUMAIN & ~i[11]) | Inst_SLLI;
wire ImmJ = Inst_LUI;

wire ImmSignADEC = i[12]&(ImmA|ImmD|ImmE|ImmC);
wire ImmSignADECJ = i[12]&(ImmA|ImmD|ImmE|ImmC|ImmJ);

wire [31:0] RawImm;
assign RawImm[0]  = (i[2]&(ImmA|ImmI));
assign RawImm[1]  = (i[3]&(ImmA|ImmC|ImmD|ImmI));
assign RawImm[2]  = (i[4]&(ImmA|ImmB|ImmC|ImmD|ImmI))       | (i[9]&ImmH)             | (i[6]&(ImmF|ImmG));
assign RawImm[3]  = (i[5]&(ImmA|ImmB|ImmC|ImmF|ImmI))       | (i[10]&(ImmD|ImmG|ImmH));
assign RawImm[4]  = (i[6]&(ImmA|ImmB|ImmE|ImmI))            | (i[11]&(ImmC|ImmD|ImmF|ImmG|ImmH));
assign RawImm[5]  = (i[12]&(ImmA|ImmB|ImmF|ImmG|ImmH|ImmI)) | (i[2]&(ImmE|ImmC|ImmD));
assign RawImm[6]  = (i[12]&ImmA)       | (i[2]&ImmB)        | (i[5]&(ImmD|ImmE|ImmG)) | (i[7]&(ImmC|ImmF|ImmH));
assign RawImm[7]  = (i[12]&ImmA)       | (i[6]&(ImmC|ImmD)) | (i[3]&(ImmB|ImmE))      | (i[8]&(ImmF|ImmH));
assign RawImm[8]  = (i[12]&(ImmA|ImmD))                     | (i[4]&ImmE)             | (i[9]&(ImmC|ImmF));
assign RawImm[9]  = (i[12]&(ImmA|ImmD|ImmE))                | (i[10]&(ImmC|ImmF));
assign RawImm[10] = (i[12]&(ImmA|ImmD|ImmE))                | (i[8]&ImmC);
assign RawImm[11] = (i[12]&(ImmA|ImmD|ImmE|ImmC));
assign RawImm[16:12] = ImmJ ? i[6:2] : {(5){ImmSignADEC}};
assign RawImm[31:17] = {(15){ImmSignADECJ}};


wire AluMainImmOp = i[11:10];
wire AluMainRegOp = i[6:5];

endmodule