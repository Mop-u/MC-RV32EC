module QuadReadRegfile #(
    parameter addr_w = 5,
    parameter data_w = 32
)(
    input clk,
    rf_drsw_intf.from_rf RfSwIntf0,
    rf_drsw_intf.from_rf RfSwIntf1
);

rf_drdw_intf #(.addr_w(addr_w),.data_w(data_w)) RfDwIntf0();
// share the write addresses
assign RfDwIntf0.Rd1Addr = RfSwIntf0.RdAddr;  // input
assign RfDwIntf0.Rd2Addr = RfSwIntf1.RdAddr;  // input
// share the write data
assign RfDwIntf0.Rd1Data = RfSwIntf0.RdData;  // input
assign RfDwIntf0.Rd2Data = RfSwIntf1.RdData;  // input
// pass through the dual read
assign RfDwIntf0.Rs1Addr = RfSwIntf0.Rs1Addr; // input
assign RfDwIntf0.Rs2Addr = RfSwIntf0.Rs2Addr; // input
assign RfSwIntf0.Rs1Data = RfDwIntf0.Rs1Data; // output
assign RfSwIntf0.Rs2Data = RfDwIntf0.Rs2Data; // output
rf_drdw_intf #(.addr_w(addr_w),.data_w(data_w)) RfDwIntf1();
// share the write addresses
assign RfDwIntf1.Rd1Addr = RfSwIntf1.RdAddr;  // input
assign RfDwIntf1.Rd2Addr = RfSwIntf0.RdAddr;  // input
// share the write data
assign RfDwIntf1.Rd1Data = RfSwIntf1.RdData;  // input
assign RfDwIntf1.Rd2Data = RfSwIntf0.RdData;  // input
// pass through the dual read
assign RfDwIntf1.Rs1Addr = RfSwIntf1.Rs1Addr; // input
assign RfDwIntf1.Rs2Addr = RfSwIntf1.Rs2Addr; // input
assign RfSwIntf1.Rs1Data = RfDwIntf1.Rs1Data; // output
assign RfSwIntf1.Rs2Data = RfDwIntf1.Rs2Data; // output

DualWriteRegfile #(.addr_w(addr_w),.data_w(data_w))
dual_write_rf_0 (
    .clk   (clk),
    .RfIntf(RfDwIntf0)
);
DualWriteRegfile #(.addr_w(addr_w),.data_w(data_w))
dual_write_rf_1 (
    .clk   (clk),
    .RfIntf(RfDwIntf1)
);
endmodule