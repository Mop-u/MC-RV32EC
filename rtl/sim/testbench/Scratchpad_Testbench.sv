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

integer Cycle = 0;
integer Stop = 2048;
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
    $display("x%d => %h",RfIntf.Rs1Addr,RfIntf.Rs1Data);
    $display("x%d => %h",RfIntf.Rs2Addr,RfIntf.Rs2Data);
    $display("x%d <= %h",RfIntf.RdAddr, RfIntf.RdData);
    if(CtrlPCMode==PCBRCH) case(IntegerUnitFlag)
        1'b1: $display("Branch Taken");
        1'b0: $display("Branch Not Taken");
    endcase
end

rf_drsw_intf #(.embedded(0)) RfIntf();

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
    .Rs1             (RfIntf.Rs1Addr),
    .Rs2             (RfIntf.Rs2Addr),
    .Rd              (RfIntf.RdAddr),
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
    .RegDirect     (RfIntf.Rs1Data),
    .ImmOffset     (DecodedImmPC),
    .Flag          (IntegerUnitFlag),
    .AddressOut    (InstructionAddress),
    .LinkOut       (LinkAddress)
);
assign RfIntf.RdData = CtrlPCWriteback ? LinkAddress :
             (CtrlALUOp[3:2] == ALUSH) ? ShiftUnitRd 
                                       : IntegerUnitRd;
Regfile #(.embedded(0))
regfile (
    .clk(clk),
    .RfIntf(RfIntf)//,
    //.RdAddr (RfIntf.RdAddr),
    //.Rs1Addr(RfIntf.Rs1Addr),
    //.Rs2Addr(RfIntf.Rs2Addr),
    //.RdData (RfIntf.RdData),
    //.Rs1Data(RfIntf.Rs1Data),
    //.Rs2Data(RfIntf.Rs2Data)
);
wire [31:0] Rs2IntMux = CtrlALUImm ? DecodedImmALU : RfIntf.Rs2Data;
wire [31:0] IntegerUnitRd;
wire        IntegerUnitFlag;
IntegerUnit int_unit (
    .Rs1        (RfIntf.Rs1Data),
    .Rs2        (Rs2IntMux),
    .CtrlALUOp  (CtrlALUOp),
    .CtrlFlagInv(CtrlFlagInv),
    .Rd         (IntegerUnitRd),
    .Flag       (IntegerUnitFlag)
);
wire [31:0] ShiftUnitRd;
ShiftUnit shift_unit (
    .Word      (RfIntf.Rs1Data),
    .Shamt     (Rs2IntMux[4:0]),
    .SignExtend(CtrlALUOp[0]),
    .ShiftRight(CtrlALUOp[1]),
    .Result    (ShiftUnitRd)
);
endmodule