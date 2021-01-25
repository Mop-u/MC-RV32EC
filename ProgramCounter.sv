module ProgramCounter (
    input clk,
    input rst,
    input         Compressed,
    input  [1:0]  CtrlPCMode,
    input         CtrlMultiCycle,
    input  [31:0] RegDirect,
    input  [31:0] ImmOffset,
    input         Flag,
    output [31:0] AddressOut,
    output [31:0] LinkOut
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
// Choose between 2 and 4 byte increments based on instruction width
wire [2:0]  IncrementOffset = Compressed ? 2 : 4;
wire [31:0] LinkCalc = CurrentValue + ((CtrlPCMode == PCINC) ? ImmOffset : IncrementOffset);

wire [31:0] AddA = (CtrlPCMode == PCJREG) ? RegDirect : CurrentValue;

logic [31:0] AddB;
always_comb case(CtrlPCMode)
    PCINC:  AddB = IncrementOffset;
    PCBRCH: AddB = Flag ? ImmOffset : IncrementOffset;
    PCJREG: AddB = '0;
    PCJIMM: AddB = ImmOffset;
endcase

reg [31:0] CurrentValue;
always @(posedge clk, posedge rst) begin
    if(rst) begin
        CurrentValue <= '0;
    end
    else if(~CtrlMultiCycle) begin
        CurrentValue <= AddA + AddB;
    end
end
assign AddressOut = CurrentValue;
assign LinkOut    = LinkCalc;
endmodule