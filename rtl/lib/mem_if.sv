interface mem_if #(
    parameter read_ports = 2,
    parameter write_ports = 1,
    parameter addr_w = 5,
    parameter data_w = 32
)();
//generate
//    if(write_ports) begin
        wr_if #(.addr_w(addr_w),.data_w(data_w)) Write [write_ports] ();
//    end
//    if(read_ports) begin
        rd_if #(.addr_w(addr_w),.data_w(data_w)) Read  [read_ports]  ();
//    end
//endgenerate 

endinterface