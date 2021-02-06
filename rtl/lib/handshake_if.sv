interface handshake_if (input clk, input rst);
struct {
    logic Ready;
    logic Valid;
} In;
logic Trigger;
struct {
    logic Ready;
    logic Valid;
} Out;

assign In.Ready = Out.Ready | ~Out.Valid; // Out.Ready is crit path h/s forwarding
assign Trigger = In.Ready & In.Valid;
always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        Out.Valid <= 0;
    end
    else begin
        Out.Valid <= (In.Ready & In.Valid) | (Out.Valid & ~Out.Ready);
    end
end
endinterface