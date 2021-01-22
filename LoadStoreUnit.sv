module LoadStoreUnit #(
    parameter tag_w = 4
)(
    input clk,
    input rst,
    input  [31:0]      DataIn,
    input  [31:0]      AddressIn,
    input  [tag_w-1:0] TagIn,
    input  [3:0]       CtrlLSU,
    output [31:0]      DataOut,
    output [tag_w-1:0] TagOut,
    output             Full,
    output             Valid
);
endmodule