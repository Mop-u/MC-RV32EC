module Regfile #(
    parameter addr_w = 5,
    parameter data_w = 32
)(
    input clk,
    mem_if RegIF
);
reg [data_w-1:0] Registers [1:(2**addr_w)-1];
always_ff @(posedge clk) begin
    if(RegIF.Write[0].Enable & |RegIF.Write[0].Addr) begin
        Registers[RegIF.Write[0].Addr] <= RegIF.Write[0].Data;
    end
end
assign RegIF.Read[0].Data = |RegIF.Read[0].Addr ? Registers[RegIF.Read[0].Addr] : 0;//'0;
assign RegIF.Read[1].Data = |RegIF.Read[1].Addr ? Registers[RegIF.Read[1].Addr] : 0;//'0;
endmodule