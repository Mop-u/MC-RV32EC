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
/*   !A  !B  Cin OR  FC
 ADD  0   0   0   0   0
 SUB  0   1   1   0   0
 AND  1   1   x   1   1
NAND  1   1   0   1   0
  OR  0   0   0   1   0
 NOR  0   0   x   1   1
XNOR  0   0   x   0   1
XNOR  1   1   x   0   1
 XOR  0   1   x   0   1
 XOR  1   0   x   0   1 */

wire CondInvertA = InA ^ InvertA;
wire CondInvertB = InB ^ InvertB;
wire InOR  = CondInvertA | CondInvertB;
wire InAND = CondInvertA & CondInvertB & ~Or;
wire InXOR = ~(InAND|~InOR);

assign CarryOut = (InOR & CarryIn) | InAND;
assign OutC     = InXOR ^ (CarryIn | FloodCarry);
endmodule