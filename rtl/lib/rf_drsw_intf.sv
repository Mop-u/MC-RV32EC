// dual read, single write regfile interface
interface rf_drsw_intf #(
    parameter embedded = 1
)();
localparam raddr_w = embedded ? 4 : 5;
wire [raddr_w-1:0] RdAddr;
wire [raddr_w-1:0] Rs1Addr;
wire [raddr_w-1:0] Rs2Addr;
wire [31:0] RdData;
wire [31:0] Rs1Data;
wire [31:0] Rs2Data;
modport to_rf (
    output RdAddr,
    output Rs1Addr,
    output Rs2Addr,
    output RdData,
    input  Rs1Data,
    input  Rs2Data
);
modport from_rf (
    input  RdAddr,
    input  Rs1Addr,
    input  Rs2Addr,
    input  RdData,
    output Rs1Data,
    output Rs2Data
);
endinterface
