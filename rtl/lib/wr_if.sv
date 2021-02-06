// simple addr/data write bundle
interface wr_if #(
    parameter addr_w = 5,
    parameter data_w = 32
)();
wire [addr_w-1:0] Addr;
wire [data_w-1:0] Data;
wire              Enable;
modport to_mem (
    output Addr,
    output Data,
    output Enable
);
modport from_mem (
    input Addr,
    input Data,
    input Enable
);
endinterface