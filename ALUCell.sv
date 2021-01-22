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
wire PartialSum = Or ? AoB : AxB;
assign CarryOut = PartialSum & CarryIn;
assign OutC     = PartialSum ^ (CarryIn|FloodCarry);
endmodule