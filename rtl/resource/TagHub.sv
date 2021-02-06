module TagHub #(
    parameter tag_w = 6,
    parameter embedded = 1
)(
    input clk,
    input rst,
    mem_if        IssueTag0,
    mem_if        IssueTag1,
    handshake_if  IssueInHS0,
    handshake_if  IssueInHS1,
    handshake_if  IssueOutHS0,
    handshake_if  IssueOutHS1,
    tag_retire_if RetireTag0,
    tag_retire_if RetireTag1,
    handshake_if  RetireHS0,
    handshake_if  RetireHS1
);
parameter addr_w = embedded ? 4 : 5;

TagRetire #(.tag_w(tag_w),.embedded(embedded))
tag_retire0 (
    .clk                  (clk),
    .rst                  (rst),
    .RetireTag            (RetireTag0),
    .RetireHS             (RetireHS0),
    .RetireCommitWrite    (RetireCommitIF.Write[0]),
    .RetireCommitRead     (RetireCommitRead[0]),
    .RetireCommitReadValid(RetireCommitReadValid[0]),
    .PoolRetire           (TagPool0.Retire)
);
TagRetire #(.tag_w(tag_w),.embedded(embedded))
tag_retire1 (
    .clk                  (clk),
    .rst                  (rst),
    .RetireTag            (RetireTag1),
    .RetireHS             (RetireHS1),
    .RetireCommitWrite    (RetireCommitIF.Write[1]),
    .RetireCommitRead     (RetireCommitRead[1]),
    .RetireCommitReadValid(RetireCommitReadValid[1]),
    .PoolRetire           (TagPool1.Retire)
);
mem_if #(.read_ports(0),.write_ports(2),.addr_w(addr_w),.data_w(tag_w)) RetireCommitIF();
wire [1:0][tag_w-1:0] RetireCommitRead;
wire [1:0]            RetireCommitReadValid;
TagfileRetireBuffer #(.ports(2),.buf_read(0),.addr_w(addr_w),.data_w(tag_w))
tag_retire_buffer (
    .clk         (clk),
    .rst         (rst),
    .MemIF       (RetireCommitIF),
    .ReadOut     (RetireCommitRead),
    .ReadOutValid(RetireCommitReadValid)
);

TagIssuer #(.tag_w(tag_w),.embedded(embedded))
tag_issuer_0 (
    .clk       (clk),
    .rst       (rst),
    .IssueIF   (IssueIF0),
    .IssueInHS (IssueInHS0), // 3 read, 0 write
    .IssueOutHS(IssueOutHS0),
    .ColdTagIF (ColdTagIF0), // 2 read, 0 write
    .HotTagIF  (HotTagIF0),  // 2 read, 1 write
    .PoolIF    (TagPool0.Issue)
);

TagIssuer #(.tag_w(tag_w),.embedded(embedded))
tag_issuer_1 (
    .clk       (clk),
    .rst       (rst),
    .IssueIF   (IssueIF1),   // 3 read, 0 write
    .IssueInHS (IssueInHS1),
    .IssueOutHS(IssueOutHS1),
    .ColdTagIF (ColdTagIF1), // 2 read, 0 write
    .HotTagIF  (HotTagIF1),  // 2 read, 1 write
    .PoolIF    (TagPool1.Issue)
);

tag_pool_if #(.tag_w(tag_w)) TagPool0();
tag_pool_if #(.tag_w(tag_w)) TagPool1();
TagPool #(.tag_w(tag_w))
tag_pool (
    .clk           (clk),
    .rst           (rst),
    .Intf0         (TagPool0),
    .Intf1         (TagPool1),
    .ResourceStatus(ResourceStatus)
);

endmodule