module MonkyBrain #(
    parameter embedded = 1
)(
    input  [31:0] Instruction,
    output [31:0] AddressReq,
    output [31:0] AddressTag
);
localparam raddr_w = embedded ? 4 : 5;

endmodule