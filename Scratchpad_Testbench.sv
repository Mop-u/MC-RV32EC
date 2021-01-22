module Scratchpad_Testbench ();

reg rst=0, clk=0;
initial begin
    #10 rst = 1;
    #10 rst = 0;
end
always #100 clk = ~clk;

wire [15:0] Inst;
Cursed_Live_Assembler_ROM cursed_live_assembler_rom (
    .Address(Cycle),
    .Instruction(Inst)
);

integer Cycle = 0;
integer Stop = 10;
always_ff @(posedge clk, posedge rst) begin
    if     (rst)         Cycle <= 0;
    else if(Cycle>=Stop) $finish();
    else                 Cycle <= Cycle + 1;
end
always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
    end
    else begin

    end
end

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
wire [4:0]  DecodedRs1;
wire [4:0]  DecodedRs2;
wire [4:0]  DecodedRd;
wire [31:0] DecodedImm;
wire [3:0]  CtrlLSU;
wire        CtrlMultiCycle;
wire        CtrlALUImm;
wire [3:0]  CtrlALUOp;
wire        CtrlFlagInv;
wire        CtrlPCWriteback;
wire [1:0]  CtrlPCMode;
CompressedInstructionDecode #(.embedded(0)) 
decoder (
    .InstructionIn  (Inst),
    .Rs1            (DecodedRs1),
    .Rs2            (DecodedRs2),
    .Rd             (DecodedRd),
    .Immediate      (DecodedImm),
    .CtrlLSU        (CtrlLSU),
    .CtrlMultiCycle (CtrlMultiCycle),
    .CtrlALUImm     (CtrlALUImm),
    .CtrlALUOp      (CtrlALUOp),
    .CtrlFlagInv    (CtrlFlagInv),
    .CtrlPCWriteback(CtrlPCWriteback),
    .CtrlPCMode     (CtrlPCMode)
);
wire [31:0] RdData = (CtrlALUOp[3:2] == ALUSH) ? ShiftUnitRd : IntegerUnitRd;
wire [31:0] Rs1Data;
wire [31:0] Rs2Data;
Regfile #(.embedded(0))
regfile (
    .clk(clk),
    .RdAddr (DecodedRd),
    .Rs1Addr(DecodedRs1),
    .Rs2Addr(DecodedRs2),
    .RdData (RdData),
    .Rs1Data(Rs1Data),
    .Rs2Data(Rs2Data)
);
wire [31:0] Rs2IntMux = CtrlALUImm ? DecodedImm : Rs2Data;
wire [31:0] IntegerUnitRd;
wire        IntegerUnitFlag;
IntegerUnit int_unit (
    .Rs1        (Rs1Data),
    .Rs2        (Rs2IntMux),
    .CtrlALUOp  (CtrlALUOp),
    .CtrlFlagInv(CtrlFlagInv),
    .Rd         (IntegerUnitRd),
    .Flag       (IntegerUnitFlag)
);
wire [31:0] ShiftUnitRd;
ShiftUnit shift_unit (
    .Word      (Rs1Data),
    .Shamt     (Rs2IntMux[4:0]),
    .SignExtend(CtrlALUOp[0]),
    .ShiftRight(CtrlALUOp[1]),
    .Result    (ShiftUnitRd)
);
endmodule