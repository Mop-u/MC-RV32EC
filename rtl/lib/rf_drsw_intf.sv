// dual read, single write regfile interface
interface rf_drsw_intf #(
    parameter addr_w = 5,
    parameter data_w = 32
)();

wire [addr_w-1:0] RdAddr;
wire [addr_w-1:0] Rs1Addr;
wire [addr_w-1:0] Rs2Addr;
wire [data_w-1:0] RdData;
wire [data_w-1:0] Rs1Data;
wire [data_w-1:0] Rs2Data;

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
