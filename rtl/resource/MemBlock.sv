module MemBlock #(
    parameter read_ports = 2,
    parameter write_ports = 1,
    parameter buf_read = 0,
    parameter addr_w = 5,
    parameter data_w = 32
)(
    input clk,
    mem_if MemIF
);

genvar i;
reg [data_w-1:0] Memory [0:(2**addr_w)-1];
generate
    for(i=0;i<write_ports;i=i+1) begin : gen_writes
        always_ff @(posedge clk) begin
            if(MemIF.Write[i].Enable) begin
                Memory[MemIF.Write[i].Addr] <= MemIF.Write[i].Data;
            end
        end
    end
    if(buf_read) begin
        reg [read_ports-1:0][data_w-1:0] BufRead;
        for(i=0;i<read_ports;i=i+1) begin : gen_reads
            always_ff @(posedge clk) begin
                if(MemIF.Read[i].Enable) begin
                    BufRead[i] <= Memory[MemIF.Read[i].Addr];
                end
            end
            assign MemIF.Read[i].Data = BufRead[i];
        end
    end
    else begin
        for(i=0;i<read_ports;i=i+1) begin : gen_reads
            assign MemIF.Read[i].Data = Memory[MemIF.Read[i].Addr];
        end
    end
endgenerate
endmodule