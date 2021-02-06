// simple addr/data read bundle
interface rd_if #(
    parameter addr_w = 5,
    parameter data_w = 32
)();
wire [addr_w-1:0] Addr;
wire [data_w-1:0] Data;
wire              Enable;
wire              Valid;
modport to_mem (
    output Addr,
    input  Data,
    output Enable,
    input  Valid
);
modport from_mem (
    input  Addr,
    output Data,
    input  Enable,
    output Valid
);
endinterface