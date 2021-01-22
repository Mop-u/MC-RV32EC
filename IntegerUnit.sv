module IntegerUnit (
    input  [31:0] Rs1,
    input  [31:0] Rs2,
    input  [3:0]  CtrlALUOp,
    input         CtrlFlagInv,
    output [31:0] Rd,
    output        Flag
);
wire [1:0] ALUCat = CtrlALUOp[3:2];
wire [1:0] ALUSel = CtrlALUOp[1:0];

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
  
                        | ALU ALU
     !A  !B  Cin OR  FC | Cat Sel
 ADD  0   0   0   0   0 | x 1 0 1
 EQU  1   0   x   0   1 | x 1 1 1
 SUB  0   1   1   0   0 | x 1 x 0
 AND  1   1   x   1   1 | x 0 1 1
  OR  0   0   0   1   0 | x 0 1 0
 XOR  0   1   x   0   1 | x 0 0 1
*/
wire InvertA     = ALUSel[0] & ALUSel[1];
wire InvertB     = ALUSel[0] ^ ALUCat[0];
wire CarryIn     = ALUSel[0] ^ ALUCat[0];
wire Or          = ALUSel[1] & ~ALUCat[0];
wire FloodCarry  = ALUSel[0] & (ALUSel[1]|~ALUCat[0]);

wire [31:0] OutC;
wire        CarryOut;
ArithmeticLogicUnit #(.width(32))
integer_core_alu (
    .InA       (Rs1),
    .InB       (Rs2),
    .CarryIn   (CarryIn),
    .Or        (Or),
    .FloodCarry(FloodCarry),
    .InvertA   (InvertA),
    .InvertB   (InvertB),
    .CarryOut  (CarryOut),
    .OutC      (OutC)
);

wire SignedCheck   = (ALUSel == AFSUBS);
wire EqualityCheck = (ALUSel == AFEQU);
wire IsZero = ~|OutC;
wire DiffSigns = SignedCheck & (Rs1[31] ^ Rs2[31]);
wire Rs1GreaterEqualRs2 = DiffSigns ? Rs2[31] : CarryOut;
wire SelectedFlag = EqualityCheck ? IsZero : Rs1GreaterEqualRs2;

assign Flag = SelectedFlag ^ CtrlFlagInv;
assign Rd = ALUCat[1] ? {31'b0,Flag} : OutC;


endmodule