interface tag_retire_if #(
    parameter tag_w = 6,
    parameter addr_w = 5
)();
wire [tag_w-1:0]  Tag;
wire [addr_w-1:0] Addr;
wire              Enable;
wire              Discard;
endinterface