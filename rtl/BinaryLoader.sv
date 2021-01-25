module BinaryLoader (
    input  [31:0] Address,
    output [31:0] Instruction
);
localparam rom_s = 16'hFFFF;
reg [7:0] Rom [0:rom_s-1];
initial begin
    integer i;
    integer OpenFile;
    OpenFile = $fopen("../rom/rom.bin", "rb");
    if(!OpenFile) begin
        $display("BinaryLoader.sv can't find rom");
        $finish();
    end
    for(i=0;i<rom_s;i=i+1) begin
        if(!$feof(OpenFile)) begin
            Rom[i] = $fgetc(OpenFile);
        end
        else Rom[i] = 8'h00;
    end
        
end
assign Instruction[7:0]   = Rom[Address];
assign Instruction[15:8]  = Rom[Address+1];
assign Instruction[23:16] = Rom[Address+2];
assign Instruction[31:24] = Rom[Address+3];
endmodule