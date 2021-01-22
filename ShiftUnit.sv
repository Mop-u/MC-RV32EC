module ShiftUnit (
    input  [31:0] Word,
    input  [4:0]  Shamt,
    input         SignExtend,
    input         ShiftRight,
    output [31:0] Result
);
wire [4:0]  LeftShamt  = 32-Shamt;

wire [31:0] ShiftLower = ShiftRight ? Word : '0;

wire [31:0] ShiftUpper = ShiftRight ? (SignExtend ? {32{Word[31]}}:'0)   
                                    : Word;

wire [4:0] ShiftAmount = ShiftRight ? Shamt : LeftShamt;
assign Result = {ShiftUpper,ShiftLower} >> ShiftAmount;
endmodule