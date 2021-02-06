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

mem_if #(
    .read_ports (2),
    .write_ports(1),
    .addr_w     (5),
    .data_w     (32)
) RfIf();

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
    $display("x%d => %h",RfIf.Read[0].Addr, RfIf.Read[0].Data);
    $display("x%d => %h",RfIf.Read[1].Addr, RfIf.Read[1].Data);
    $display("x%d <= %h",RfIf.Write[0].Addr,RfIf.Write[0].Data);
    if(CtrlPCMode==PCBRCH) case(IntegerUnitFlag)
        1'b1: $display("Branch Taken");
        1'b0: $display("Branch Not Taken");
    endcase
end

assign RfIf.Read[0].Enable = 1;
assign RfIf.Read[1].Enable = 1;
assign RfIf.Write[0].Enable = 1;

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
    .Rs1             (RfIf.Read[0].Addr),
    .Rs2             (RfIf.Read[1].Addr),
    .Rd              (RfIf.Write[0].Addr),
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
    .RegDirect     (RfIf.Read[0].Data),
    .ImmOffset     (DecodedImmPC),
    .Flag          (IntegerUnitFlag),
    .AddressOut    (InstructionAddress),
    .LinkOut       (LinkAddress)
);
assign RfIf.Write[0].Data = CtrlPCWriteback ? LinkAddress :
             (CtrlALUOp[3:2] == ALUSH) ? ShiftUnitRd 
                                       : IntegerUnitRd;
Regfile #(.addr_w(5),.data_w(32))
regfile (
    .clk (clk),
    .RfIf(RfIf)
);
wire [31:0] Rs2IntMux = CtrlALUImm ? DecodedImmALU : RfIf.Read[1].Data;
wire [31:0] IntegerUnitRd;
wire        IntegerUnitFlag;
IntegerUnit int_unit (
    .Rs1        (RfIf.Read[0].Data),
    .Rs2        (Rs2IntMux),
    .CtrlALUOp  (CtrlALUOp),
    .CtrlFlagInv(CtrlFlagInv),
    .Rd         (IntegerUnitRd),
    .Flag       (IntegerUnitFlag)
);
wire [31:0] ShiftUnitRd;
ShiftUnit shift_unit (
    .Word      (RfIf.Read[0].Data),
    .Shamt     (Rs2IntMux[4:0]),
    .SignExtend(CtrlALUOp[0]),
    .ShiftRight(CtrlALUOp[1]),
    .Result    (ShiftUnitRd)
);
endmodule