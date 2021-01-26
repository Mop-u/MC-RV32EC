/*
 * Dual-issue, dual-retire resource tag manager
 */
module ResourceManager #(
    parameter tag_w = 1
) (
    input  clk,
    input  rst,
    input        [1:0]            Issue,
    input        [1:0]            Retire,
    input        [1:0][tag_w-1:0] RetireTag,
    output logic [1:0]            Available,
    output logic [1:0][tag_w-1:0] IssueTag,
    output reg   [depth-1:0]      ResourceStatus // 1 == busy, 0 == idle
);
localparam depth = 2**tag_w;

reg [tag_w-1:0] Queue [0:depth-1];
reg [tag_w-1:0] QueueHead;
reg [tag_w-1:0] QueueTail;
reg [tag_w:0] QueueSize;

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
 * IssueEnable logic
 * Resolves resource contention when only one slot is available, and
 * avoids reading from an empty queue.
 */
wire IssueSpaceFree = |QueueSize[tag_w:1];

wire [1:0] IssueEnable;
assign IssueEnable[0] =
    Issue[0]&(IssueSpaceFree|(QueueSize[0]&(ContentionBit|~Issue[1])));
assign IssueEnable[1] =
    Issue[1]&(IssueSpaceFree|(QueueSize[0]&(~ContentionBit|~Issue[0])));

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
    ResourceStatus[RetireTag[0]];
assign RetireStatus[1] =
    ResourceStatus[RetireTag[1]];

wire [1:0] RetireEnable;
assign RetireEnable[0] =
    Retire[0]&RetireStatus[0]&(~RetireSpaceLow|(SlotRemains&(ContentionBit|~Issue[1]|~RetireStatus[1])));
assign RetireEnable[1] =
    Retire[1]&RetireStatus[1]&(~RetireSpaceLow|(SlotRemains&(~ContentionBit|~Issue[0]|~RetireStatus[0])));

/*
 * Tag forwarding logic.
 * Note that with larger external circuits this is the critical path,
 * so make sure that the tags being retired are buffered nearby.
 * The contention bit is used to prioritize a port when the queue is empty.
 */
logic [1:0] IssuePopEnable;
always_comb begin
    if(RetireEnable[0]&(~IssueEnable[1]|ContentionBit|RetireEnable[1])) begin
        IssueTag[0] = RetireTag[0];
        IssuePopEnable[0] = 1'b0;
    end
    else if(RetireEnable[1]&ContentionBit) begin
        IssueTag[0] = RetireTag[1];
        IssuePopEnable[0] = 1'b0;
    end
    else begin
        IssueTag[0] = Queue[QueueHead-1];
        IssuePopEnable[0] = IssueEnable[0];
    end
end
always_comb begin
    if(RetireEnable[1]&(~IssueEnable[0]|~ContentionBit|RetireEnable[0])) begin
        IssueTag[1] = RetireTag[1];
        IssuePopEnable[1] = 1'b0;
    end
    else if(RetireEnable[0]&~ContentionBit) begin
        IssueTag[1] = RetireTag[0];
        IssuePopEnable[1] = 1'b0;
    end
    else begin
        IssueTag[1] = Queue[QueueTail+1];
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
            Queue[QueueHead] <= RetireTag[0];
            ResourceStatus[RetireTag[0]] <= 1'b0;
        end
        if(RetirePushEnable[1]) begin
            Queue[QueueTail] <= RetireTag[1];
            ResourceStatus[RetireTag[1]] <= 1'b0;
        end
        if(IssuePopEnable[0]) begin
            ResourceStatus[IssueTag[0]] <= 1'b1;
        end
        if(IssuePopEnable[1]) begin
            ResourceStatus[IssueTag[1]] <= 1'b1;
        end
        QueueTail <= QueueTail + TailUpdate;
        QueueHead <= QueueHead + HeadUpdate;
        QueueSize <= QueueSize + SizeUpdate;
    end
end
endmodule