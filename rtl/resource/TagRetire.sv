module TagRetire #(
    parameter tag_w = 6,
    parameter embedded = 1
)(
    input clk,
    input rst,
    tag_retire_if      RetireTag,
    handshake_if       RetireHS,
    wr_if.to_mem       RetireCommitWrite,
    input [tag_w-1:0]  RetireCommitRead,
    input              RetireCommitReadValid,
    tag_pool_retire_if PoolRetire
);
parameter addr_w = embedded ? 4 : 5;

wire EnableFullCommit = RetireTag.Enable & ~RetireTag.Discard;
wire EnableDiscard    = RetireTag.Enable & RetireTag.Discard;
wire ValidPoolRetire  = EnableDiscard | (EnableFullCommit & RetireCommitReadValid);

assign PoolRetire.Tag    = RetireTag.Discard ? RetireTag.Tag : RetireCommitRead;
assign PoolRetire.Enable = RetireHS.Trigger & ValidPoolRetire;

assign RetireCommitWrite.Addr   = RetireTag.Addr;
assign RetireCommitWrite.Data   = RetireTag.Tag;
assign RetireCommitWrite.Enable = RetireHS.Trigger & EnableFullCommit;

endmodule