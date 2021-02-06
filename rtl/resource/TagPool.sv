/*
 * Dual-issue, dual-retire resource tag manager
 */
module TagPool #(
    parameter tag_w = 4
) (
    input  clk,
    input  rst,
    tag_pool_if PoolIF0,
    tag_pool_if PoolIF1
);
localparam depth = 2**tag_w;

reg [depth-1:0] ResourceStatus; // 1 == busy, 0 == idle

reg [tag_w-1:0] Queue [0:depth-1];
reg [tag_w-1:0] QueueHead;
reg [tag_w-1:0] QueueTail;
reg [tag_w:0]   QueueSize;

/*
 * ContentionBit logic
 * This bit flips every cycle as a simple way to arbitrate
 * resource access priority between the two ports.
 * In the future this could be changed to flip only when contention
 * occurs, to further smooth out accesses between ports.
 */
reg ContentionBit;
always @(posedge clk, posedge rst) begin
    if(rst) ContentionBit <= 1'b0;
    else ContentionBit <= ~ContentionBit;
end

/*
 * Available logic
 * Let the coressponding interface know if a tag is available,
 * taking into account resource contention when there is only 1 tag
 */

wire IssueSpaceFree = |QueueSize[tag_w:1];
assign PoolIF0.Issue.Available = (IssueSpaceFree|(QueueSize[0]&ContentionBit));
assign PoolIF1.Issue.Available = (IssueSpaceFree|(QueueSize[0]&~ContentionBit));

/*
 * IssueEnable logic
 * Resolves resource contention when only one slot is available, and
 * avoids reading from an empty queue.
 */

wire [1:0] IssueEnable;
assign IssueEnable[0] =
    PoolIF0.Issue.Enable&PoolIF0.Issue.Available;//(IssueSpaceFree|(QueueSize[0]&(ContentionBit|~PoolIF1.Issue)));
assign IssueEnable[1] =
    PoolIF1.Issue.Enable&PoolIF1.Issue.Available;//(IssueSpaceFree|(QueueSize[0]&(~ContentionBit|~PoolIF0.Issue)));

/*
 * RetireEnable logic
 * Resolves resource contention when only one slot is available,
 * avoids writing to the queue when full (tolerant to illegal inputs) and 
 * avoids writing duplicate resource tags to the queue.
 */
wire RetireSpaceLow = QueueSize[tag_w]|&QueueSize[tag_w-1:0];

wire SlotRemains = QueueSize[0];

wire [1:0] RetireStatus;
assign RetireStatus[0] =
    ResourceStatus[PoolIF0.Retire.Tag];
assign RetireStatus[1] =
    ResourceStatus[PoolIF1.Retire.Tag];

wire [1:0] RetireEnable;
assign RetireEnable[0] =
    PoolIF0.Retire&RetireStatus[0]&(~RetireSpaceLow|(SlotRemains&(ContentionBit|~PoolIF1.Issue.Enable|~RetireStatus[1])));
assign RetireEnable[1] =
    PoolIF1.Retire&RetireStatus[1]&(~RetireSpaceLow|(SlotRemains&(~ContentionBit|~PoolIF0.Issue.Enable|~RetireStatus[0])));

/*
 * Tag forwarding logic.
 * Note that with larger external circuits this is the critical path,
 * so make sure that the tags being retired are buffered nearby.
 * The contention bit is used to prioritize a port when the queue is empty.
 */
logic [1:0] IssuePopEnable;
always_comb begin
    if(RetireEnable[0]&(~IssueEnable[1]|ContentionBit|RetireEnable[1])) begin
        PoolIF0.Issue.Tag = PoolIF0.Retire.Tag;
        IssuePopEnable[0] = 1'b0;
    end
    else if(RetireEnable[1]&ContentionBit) begin
        PoolIF0.Issue.Tag = PoolIF1.Retire.Tag;
        IssuePopEnable[0] = 1'b0;
    end
    else begin
        PoolIF0.Issue.Tag = Queue[QueueHead-1];
        IssuePopEnable[0] = IssueEnable[0];
    end
end
always_comb begin
    if(RetireEnable[1]&(~IssueEnable[0]|~ContentionBit|RetireEnable[0])) begin
        PoolIF1.Issue.Tag = PoolIF1.Retire.Tag;
        IssuePopEnable[1] = 1'b0;
    end
    else if(RetireEnable[0]&~ContentionBit) begin
        PoolIF1.Issue.Tag = PoolIF0.Retire.Tag;
        IssuePopEnable[1] = 1'b0;
    end
    else begin
        PoolIF1.Issue.Tag = Queue[QueueTail+1];
        IssuePopEnable[1] = IssueEnable[1];
    end
end

wire [1:0] RetirePushEnable;
assign RetirePushEnable[0] =
    RetireEnable[0]&~(IssueEnable[0]|(IssueEnable[1]&~ContentionBit&~RetireEnable[1]));
assign RetirePushEnable[1] =
    RetireEnable[1]&~(IssueEnable[1]|(IssueEnable[0]&ContentionBit&~RetireEnable[0]));

/*
 * Queue state update logic.
 * 
 * Calculates the required update values, taking into account
 * forwarded tags that don't check in to the queue.
 * 
 * Appropriate flag changes depending on the current queue size
 * are taken into account earlier in the flags IssueEnable & RetireEnable.
 */
wire [tag_w-1:0] TailUpdate = (IssuePopEnable[1] ^ RetirePushEnable[1]) ? 
                                 IssuePopEnable[1] | (-RetirePushEnable[1]) : '0;
wire [tag_w-1:0] HeadUpdate = (IssuePopEnable[0] ^ RetirePushEnable[0]) ? 
                                 (-IssuePopEnable[0]) | RetirePushEnable[0] : '0;
wire [tag_w:0] SizeUpdate = {HeadUpdate[tag_w-1],HeadUpdate} - {TailUpdate[tag_w-1],TailUpdate};

integer i;
always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        ResourceStatus <= '0;
        QueueSize      <= '0;
        QueueHead      <= '0;
        QueueTail      <= '0;
        for(i=0;i<depth;i=i+1) Queue[i] <= i;
    end
    else begin
        if(RetirePushEnable[0]) begin
            Queue[QueueHead] <= PoolIF0.Retire.Tag;
            ResourceStatus[PoolIF0.Retire.Tag] <= 1'b0;
        end
        if(RetirePushEnable[1]) begin
            Queue[QueueTail] <= PoolIF1.Retire.Tag;
            ResourceStatus[PoolIF1.Retire.Tag] <= 1'b0;
        end
        if(IssuePopEnable[0]) begin
            ResourceStatus[PoolIF0.Issue.Tag] <= 1'b1;
        end
        if(IssuePopEnable[1]) begin
            ResourceStatus[PoolIF1.Issue.Tag] <= 1'b1;
        end
        QueueTail <= QueueTail + TailUpdate;
        QueueHead <= QueueHead + HeadUpdate;
        QueueSize <= QueueSize + SizeUpdate;
    end
end
endmodule