module Regfile #(
    parameter embedded = 1
)(
    input clk,
    input  [raddr_w-1:0] RdAddr,
    input  [raddr_w-1:0] Rs1Addr,
    input  [raddr_w-1:0] Rs2Addr,
    input  [31:0] RdData,
    output [31:0] Rs1Data,
    output [31:0] Rs2Data
);
localparam raddr_w = embedded ? 4 : 5;
reg [31:0] Registers [1:(2**raddr_w)-1];
always_ff @(posedge clk) begin
    if(|RdAddr) begin
        Registers[RdAddr] <= RdData;
        $display("x%0d <= %h",RdAddr,RdData);
    end
end
assign Rs1Data = |Rs1Addr ? Registers[Rs1Addr] : '0;
assign Rs2Data = |Rs2Addr ? Registers[Rs2Addr] : '0;
endmodule