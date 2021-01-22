module ArithmeticLogicUnit #(
    parameter width = 32
)(
    input  [width-1:0] InA,
    input  [width-1:0] InB,
    input              CarryIn,
    input              Or,
    input              FloodCarry,
    input              InvertA,
    input              InvertB,
    output             CarryOut,
    output [width-1:0] OutC
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
 XOR  1   0   x   0   1
*/

genvar i;
generate
    wire [width:0] AllCarries;
    assign AllCarries[0] = CarryIn;
    assign AllCarries[width] = CarryOut;
    for(i=0;i<width;i=i+1) begin : gen_alu
        ALUCell alu_cell (
            .InA       (InA[i]),
            .InB       (InB[i]),
            .CarryIn   (AllCarries[i]),
            .FloodCarry(FloodCarry),
            .Or        (Or),
            .InvertA   (InvertA),
            .InvertB   (InvertB),
            .CarryOut  (AllCarries[i+1]),
            .OutC      (OutC[i])
        );
    end
endgenerate
endmodule