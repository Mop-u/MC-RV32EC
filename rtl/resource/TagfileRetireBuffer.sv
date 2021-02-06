module TagfileRetireBuffer #(
    parameter ports = 2,
    parameter buf_read = 0,
    parameter addr_w = 5,
    parameter data_w = 32
)(
    input clk,
    input rst,
    mem_if MemIF, // Write ports only
    output [ports-1:0][data_w-1:0] ReadOut,
    output [ports-1:0]             ReadOutValid
);

genvar i;
reg [data_w-1:0] Tags [(2**addr_w)-1:1];
reg [(2**addr_w)-1:1] ValidTag;
generate
    for(i=0;i<ports;i=i+1) begin : gen_write
        always_ff @(posedge clk, posedge rst) begin
            if(rst) begin
                ValidTag[i] <= '0;
            end
            else if(MemIF.Write[i].Enable & |MemIF.Write[i].Addr) begin
                Tags    [MemIF.Write[i].Addr] <= MemIF.Write[i].Data;
                ValidTag[MemIF.Write[i].Addr] <= 1'b1;
            end
        end
    end
    if(buf_read) begin
        reg [ports-1:0][data_w-1:0] ReadBufTag;
        reg [ports-1:0]             ReadBufValid;
        for(i=0;i<ports;i=i+1) begin : gen_buffered_read
            always_ff @(posedge clk, posedge rst) begin
                if(rst) begin
                    ReadBufValid[i] <= '0;
                end
                else begin
                    ReadBufTag  [i] <= |MemIF.Write[i].Addr ? Tags    [MemIF.Write[i].Addr] : '0;
                    ReadBufValid[i] <= |MemIF.Write[i].Addr ? ValidTag[MemIF.Write[i].Addr] : 1'b0;
                end
            end
            assign ReadOut     [i] = ReadBufTag  [i];
            assign ReadOutValid[i] = ReadBufValid[i];
        end
    end
    else begin
        for(i=0;i<ports;i=i+1) begin : gen_unbuffered_read
            assign ReadOut[i]      = |MemIF.Write[i].Addr ? Tags    [MemIF.Write[i].Addr] : '0;
            assign ReadOutValid[i] = |MemIF.Write[i].Addr ? ValidTag[MemIF.Write[i].Addr] : 1'b0;
        end
    end
endgenerate
endmodule