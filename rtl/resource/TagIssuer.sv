module TagIssuer #(
    parameter tag_w = 6,
    parameter embedded = 1
)(
    input clk,
    input rst,
    mem_if            IssueIF,    // 3 read, 0 write (rs1,rs2,rd / 0,1,2)
    handshake_if      IssueInHS,
    handshake_if      IssueOutHS,
    mem_if            ColdTagIF,  // 2 read, 0 write
    mem_if            HotTagIF,   // 2 read, 1 write
    tag_pool_issue_if PoolIF
);
parameter addr_w = embedded ? 4 : 5;

// setup handshake for reserving a fresh tag for new issues
handshake_if PoolHS (.clk(clk),.rst(rst));
assign PoolHS.In.Valid = PoolIF.Available;
assign PoolIF.Enable   = PoolHS.In.Ready;
reg [tag_w-1:0] FreshTag;
always_ff @(posedge clk) if(PoolHS.Trigger) FreshTag <= PoolIF.Tag;

// only pop out the fresh tag if it's really being used
wire WriteHotTag = IssueOutHS.In.Ready & PoolHS.Out.Valid & IssueInHS.Out.Valid & IssueIF.Read[2].Enable;
assign PoolHS.Out.Ready = WriteHotTag;

// Register destination hot tag update
assign HotTagIF.Write[0].Addr   = IssueIF.Read[2].Addr;
assign HotTagIF.Write[0].Data   = FreshTag;
assign HotTagIF.Write[0].Enable = WriteHotTag;

// advance pipeline if fresh tag available or fresh tag not needed
assign IssueInHS.Out.Ready = IssueOutHS.In.Ready & (PoolHS.Out.Valid | ~IssueIF.Read[2].Enable);
assign IssueOutHS.In.Valid = IssueInHS.Out.Ready;

// Register destination tag fetch
assign IssueIF.Read[2].Data  = FreshTag;
assign IssueIF.Read[2].Valid = |IssueIF.Read[2].Addr;

// Register source tag reads
assign ColdTagIF.Read[0].Addr   = IssueIF.Read[0].Addr;
assign ColdTagIF.Read[0].Enable = IssueIF.Read[0].Enable;
assign ColdTagIF.Read[1].Addr   = IssueIF.Read[1].Addr;
assign ColdTagIF.Read[1].Enable = IssueIF.Read[1].Enable;

assign HotTagIF.Read[0].Addr    = IssueIF.Read[0].Addr;
assign HotTagIF.Read[0].Enable  = IssueIF.Read[0].Enable;
assign HotTagIF.Read[1].Addr    = IssueIF.Read[1].Addr;
assign HotTagIF.Read[1].Enable  = IssueIF.Read[1].Enable;

genvar i;
generate for(i=0;i<2;i=i+1) begin : gen_read_tag_sel
    assign IssueIF.Read[i].Data  = HotTagIF.Read[i].Valid ? HotTagIF.Read[i].Data : ColdTagIF.Read[i].Data;
    assign IssueIF.Read[i].Valid = IssueIF.Read[i].Enable & (HotTagIF.Read[i].Valid | ColdTagIF.Read[i].Valid);
end endgenerate

endmodule