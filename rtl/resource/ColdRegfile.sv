module ColdRegfile #(
    parameter embedded = 1,
    parameter wb_depth = 16
)(
    input clk,
    input rst,
    input  [raddr_w-1:0] WbAddr,
    input  [wb_tag_w-1:0] WbTag,
    input  [raddr_w-1:0] RdAddr,
    input  [raddr_w-1:0] Rs1Addr,
    input  [raddr_w-1:0] Rs2Addr,
    input  [31:0] RdData,
    output [31:0] Rs1Data,
    output        Rs1DataHot,
    output [31:0] Rs2Data,
    output        Rs2DataHot
);
localparam raddr_w = embedded ? 4 : 5;
localparam wb_tag_w = wb_depth > 1 ? $clog2(wb_depth) : 1;

// This whole module needs work to properly be using interfaces...

rf_drsw_intf #(.embedded(embedded)) RfIntf();
assign RfIntf.RdAddr = WbAddr;
assign RfIntf.Rs1Addr = Rs1Addr;
assign RfIntf.Rs2Addr = Rs2Addr;
assign RfIntf.RdData = RdData;
wire [raddr_w-1:0] Rs1RegRead = RfIntf.Rs1Data;
wire [raddr_w-1:0] Rs2RegRead = RfIntf.Rs2Data;
Regfile #(.embedded(embedded))
cold_regfile (
    .clk   (clk),
    .RfIntf(RfIntf)
);

reg  [wb_tag_w-1:0] HorizonTag;
reg  [wb_tag_w-1:0] RetiredTag;
wire [wb_tag_w-1:0] NextHorizonTag = HorizonTag+1;

reg [wb_tag_w-1:0] IssuedTagFile [1:(2**raddr_w)-1];
reg [wb_tag_w-1:0] RetireTagFile [1:(2**raddr_w)-1];

assign Rs1DataHot = (Rs1IssuedTag != Rs1RetireTag);
assign Rs2DataHot = (Rs2IssuedTag != Rs2RetireTag);

assign Rs1Data = Rs1DataHot ? {{(32-wb_tag_w){1'b0}},Rs1IssuedTag} : Rs1RegRead;
assign Rs2Data = Rs2DataHot ? {{(32-wb_tag_w){1'b0}},Rs2IssuedTag} : Rs2RegRead;

wire [wb_tag_w-1:0] Rs1IssuedTag = IssuedTagFile[Rs1Addr];
wire [wb_tag_w-1:0] Rs1RetireTag = RetireTagFile[Rs1Addr];

wire [wb_tag_w-1:0] Rs2IssuedTag = IssuedTagFile[Rs2Addr];
wire [wb_tag_w-1:0] Rs2RetireTag = RetireTagFile[Rs2Addr];

integer i;
always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        HorizonTag <= '0;
        for(i=1;i<(raddr_w-1);i=i+1) begin : init_issue_tag_file
            IssuedTagFile[i] <= '0;
        end
    end
    else if(|RdAddr) begin
        IssuedTagFile[RdAddr] <= NextHorizonTag;
        HorizonTag            <= NextHorizonTag;
    end
end
always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        RetiredTag <= '0;
        for(i=1;i<(raddr_w-1);i=i+1) begin : init_retire_tag_file
            RetireTagFile[i] <= '0;
        end
    end
    else if(|WbAddr) begin
        RetireTagFile[WbAddr] <= WbTag;
    end
end
endmodule