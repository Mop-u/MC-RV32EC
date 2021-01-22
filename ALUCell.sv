module ALUCell (
    input  InA,
    input  InB,
    input  CarryIn,
    input  FloodCarry, // FC bypasses the carry chain for better timing
    input  Or,
    input  InvertA,
    input  InvertB,
    output CarryOut,
    output OutC
);
// Input inverters
wire InA0 = InA ^ InvertA;
wire InB0 = InB ^ InvertB;
// Input OR
wire AoB  = InA0 | InB0;
// Input XOR
wire AxB  = ~((InA0&InB0)|~AoB);
// OR / XOR select
wire PartialSum = (AoB & Or) | AxB;
assign CarryOut = (PartialSum & CarryIn) | (InA0 & InB0 & ~Or);
assign OutC     = PartialSum ^ (CarryIn|FloodCarry);
endmodule