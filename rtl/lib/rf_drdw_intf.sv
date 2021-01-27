// dual read, dual write regfile interface
interface rf_drdw_intf #(
    parameter embedded = 1
)();
localparam raddr_w = embedded ? 4 : 5;
wire [raddr_w-1:0] Rd1Addr;
wire [raddr_w-1:0] Rd2Addr;
wire [raddr_w-1:0] Rs1Addr;
wire [raddr_w-1:0] Rs2Addr;
wire [31:0] Rd1Data;
wire [31:0] Rd2Data;
wire [31:0] Rs1Data;
wire [31:0] Rs2Data;
modport to_rf (
    output Rd1Addr,
    output Rd2Addr,
    output Rs1Addr,
    output Rs2Addr,
    output Rd1Data,
    output Rd2Data,
    input  Rs1Data,
    input  Rs2Data
);
modport from_rf (
    input  Rd1Addr,
    input  Rd2Addr,
    input  Rs1Addr,
    input  Rs2Addr,
    input  Rd1Data,
    input  Rd2Data,
    output Rs1Data,
    output Rs2Data
);
endinterface
