module Scratchpad_Testbench ();

reg rst=0, clk=0;
initial begin
    #10 rst = 1;
    #10 rst = 0;
end
always #100 clk = ~clk;

wire [31:0] Inst;
BinaryLoader binary_loader (
    .Address(InstructionAddress),
    .Instruction(Inst)
);

integer Cycle = 0;
integer Stop = 1024;
always_ff @(posedge clk, posedge rst) begin
    if     (rst)         Cycle <= 0;
    else if(Cycle>=Stop) $finish();
    else                 Cycle <= Cycle + 1;
end
always_ff @(posedge clk) begin
    $display("\nCycle %0d:",Cycle);
    $display("PC: %h",InstructionAddress);
    $display("EncALUCat %b, EncALUOp %b, ImmEN %b", CtrlALUOp[3:2], CtrlALUOp[1:0], CtrlALUImm);
    if(CtrlALUImm) $display("Imm => %h",DecodedImmALU);
    $display("x%d => %h",DecodedRs1,RegfileRs1);
    $display("x%d => %h",DecodedRs2,RegfileRs2);
    $display("x%d <= %h",DecodedRd, RegfileRd);
    if(CtrlPCMode==PCBRCH) case(IntegerUnitFlag)
        1'b1: $display("Branch Taken");
        1'b0: $display("Branch Not Taken");
    endcase
end
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
wire [4:0]  DecodedRs1;
wire [4:0]  DecodedRs2;
wire [4:0]  DecodedRd;
wire [31:0] DecodedImmALU;
wire [31:0] DecodedImmPC;
wire [3:0]  CtrlLSU;
wire        CtrlMultiCycle;
wire        CtrlALUImm;
wire [3:0]  CtrlALUOp;
wire        CtrlFlagInv;
wire        CtrlPCWriteback;
wire [1:0]  CtrlPCMode;
wire        ValidDecode_C;
MainDecode #(.embedded(0)) 
decoder (
    .InstructionIn   (Inst),
    .Rs1             (DecodedRs1),
    .Rs2             (DecodedRs2),
    .Rd              (DecodedRd),
    .ImmALU          (DecodedImmALU),
    .ImmPC           (DecodedImmPC),
    .CtrlLSU         (CtrlLSU),
    .CtrlMultiCycle  (CtrlMultiCycle),
    .CtrlALUImm      (CtrlALUImm),
    .CtrlALUOp       (CtrlALUOp),
    .CtrlFlagInv     (CtrlFlagInv),
    .CtrlPCWriteback (CtrlPCWriteback),
    .CtrlPCMode      (CtrlPCMode),
    .ValidDecode     (),
    .CompressedDecode(ValidDecode_C)
);
wire [31:0] InstructionAddress;
wire [31:0] LinkAddress;
ProgramCounter program_counter (
    .clk(clk),
    .rst(rst),
    .Compressed    (ValidDecode_C),
    .CtrlPCMode    (CtrlPCMode),
    .CtrlMultiCycle(CtrlMultiCycle),
    .RegDirect     (RegfileRs1),
    .ImmOffset     (DecodedImmPC),
    .Flag          (IntegerUnitFlag),
    .AddressOut    (InstructionAddress),
    .LinkOut       (LinkAddress)
);
wire [31:0] RegfileRd = CtrlPCWriteback ? LinkAddress :
              (CtrlALUOp[3:2] == ALUSH) ? ShiftUnitRd 
                                        : IntegerUnitRd;
wire [31:0] RegfileRs1;
wire [31:0] RegfileRs2;
Regfile #(.embedded(0))
regfile (
    .clk(clk),
    .RdAddr (DecodedRd),
    .Rs1Addr(DecodedRs1),
    .Rs2Addr(DecodedRs2),
    .RdData (RegfileRd),
    .Rs1Data(RegfileRs1),
    .Rs2Data(RegfileRs2)
);
wire [31:0] Rs2IntMux = CtrlALUImm ? DecodedImmALU : RegfileRs2;
wire [31:0] IntegerUnitRd;
wire        IntegerUnitFlag;
IntegerUnit int_unit (
    .Rs1        (RegfileRs1),
    .Rs2        (Rs2IntMux),
    .CtrlALUOp  (CtrlALUOp),
    .CtrlFlagInv(CtrlFlagInv),
    .Rd         (IntegerUnitRd),
    .Flag       (IntegerUnitFlag)
);
wire [31:0] ShiftUnitRd;
ShiftUnit shift_unit (
    .Word      (RegfileRs1),
    .Shamt     (Rs2IntMux[4:0]),
    .SignExtend(CtrlALUOp[0]),
    .ShiftRight(CtrlALUOp[1]),
    .Result    (ShiftUnitRd)
);
endmodule