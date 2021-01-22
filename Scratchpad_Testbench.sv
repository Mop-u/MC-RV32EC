module Scratchpad_Testbench ();

reg rst=0, clk=0;
initial begin
    #10 rst = 1;
    #10 rst = 0;
end
always #100 clk = ~clk;

wire [15:0] C_NOP      = 16'b0000000000000001;                          // c.nop
wire [15:0] C_ADDI     = {3'b000,Imm[5],Rs1,Imm[4:0],2'b01};            // c.addi Rs1, Imm
wire [15:0] C_LI       = {3'b010,Imm[5],Rs1,Imm[4:0],2'b01};            // c.li   Rs1, Imm
wire [15:0] C_LUI      = {3'b011,Imm[17],Rs1,Imm[16:12],2'b01};         // c.lui  Rs1, Imm
wire [15:0] C_SUB      = {6'b100011,Rs1[2:0],2'b00,Rs2[2:0],2'b01};     // c.sub  Rs1, Rs2 # compressed reg address
wire [15:0] C_XOR      = {6'b100011,Rs1[2:0],2'b01,Rs2[2:0],2'b01};     // c.xor  Rs1, Rs2 # compressed reg address
wire [15:0] C_OR       = {6'b100011,Rs1[2:0],2'b10,Rs2[2:0],2'b01};     // c.or   Rs1, Rs2 # compressed reg address
wire [15:0] C_AND      = {6'b100011,Rs1[2:0],2'b11,Rs2[2:0],2'b01};     // c.and  Rs1, Rs2 # compressed reg address
wire [15:0] C_ANDI     = {3'b100,Imm[5],2'b10,Rs1[2:0],Imm[4:0],2'b01}; // c.andi Rs1, Imm # compressed reg address
wire [15:0] C_SRAI     = {3'b100,1'b0,2'b01,Rs1[2:0],Imm[4:0],2'b01};   // c.srai Rs1, Imm # compressed reg address
wire [15:0] C_SRLI     = {3'b100,1'b0,2'b00,Rs1[2:0],Imm[4:0],2'b01};   // c.srli Rs1, Imm # compressed reg address
wire [15:0] C_SLLI     = {3'b000,1'b0,Rs1,Imm[4:0],2'b10};              // c.slli Rs1, Imm
wire [15:0] C_MV       = {4'b1000,Rs1,Rs2,2'b10};                       // c.mv   Rs1, Rs2
wire [15:0] C_JR       = {4'b1000,Rs1,7'b0000010};                      // c.jr   Rs1
wire [15:0] C_ADD      = {4'b1001,Rs1,Rs2,2'b10};                       // c.add  Rs1, Rs2
wire [15:0] C_JALR     = {4'b1001,Rs1,7'b0000010};                      // c.jalr Rs1
wire [15:0] C_EBREAK   = 16'b1001000000000010;                          // c.ebreak
wire [15:0] C_LWSP     = {3'b010,Imm[5],Rs1,Imm[4:2],Imm[7:6],2'b10};   // c.lwsp Rs1, Imm
wire [15:0] C_SWSP     = {3'b110,Imm[5:2],Imm[7:6],Rs2,2'b10};          // c.swsp Rs2, Imm
wire [15:0] C_J        = {3'b101,                                       // c.j    Imm
                            Imm[11],Imm[4],Imm[9:8],Imm[10],
                            Imm[6],Imm[7],Imm[3:1],Imm[5],
                          2'b01};
wire [15:0] C_JAL      = {3'b001,                                       // c.jal  Imm
                            Imm[11],Imm[4],Imm[9:8],Imm[10],
                            Imm[6],Imm[7],Imm[3:1],Imm[5],
                          2'b01};
wire [15:0] C_BEQZ     = {3'b110,                                       // c.beqz Rs1, Imm # compressed reg address
                            Imm[8],Imm[4:3],
                            Rs1[2:0],
                            Imm[7:6],Imm[2:1],Imm[5],
                          2'b01};
wire [15:0] C_BNEZ     = {3'b111,                                       // c.bnez Rs1, Imm # compressed reg address
                            Imm[8],Imm[4:3],
                            Rs1[2:0],
                            Imm[7:6],Imm[2:1],Imm[5],
                          2'b01};
wire [15:0] C_ADDI16SP = {3'b011,                                       // c.addi16sp
                            Imm[9],5'h02,Imm[4],
                            Imm[6],Imm[8:7],Imm[5],
                          2'b01};
wire [15:0] C_ADDI4SPN = {3'b000,                                       // c.addi4spn Rs2 # compressed reg address
                            Imm[5:4],Imm[9:6],Imm[2],Imm[3],
                            Rs2[2:0],
                          2'b00};
wire [15:0] C_LW       = {3'b010,                                       // c.lw Rs2, Imm(Rs1) # compressed reg address
                            Imm[5:3],Rs1[2:0],
                            Imm[2],Imm[6],Rs2[2:0],
                          2'b00};
wire [15:0] C_SW       = {3'b110,                                       // c.sw Rs2, Imm(Rs1) # compressed reg address
                            Imm[5:3],Rs1[2:0],
                            Imm[2],Imm[6],Rs2[2:0],
                          2'b00};

logic [4:0]  Rs1   = 5'h0F;
logic [4:0]  Rs2   = 5'h0E;
logic [31:0] Imm   = '1;
logic [15:0] Inst  = C_NOP;

always_comb case(Cycle)
    0: begin
        Inst = C_NOP;
    end
    1: begin
        Rs1 = 14;
        Imm = 1;
        Inst = C_LI; // Load 1 to x14
    end
    2: begin
        Rs1 = 15;
        Imm = 0;
        Inst = C_LI; // Load 0 to x15
    end
    3: begin
        Rs1 = 15;
        Rs2 = 14;
        Inst = C_ADD; // x15 = x15 + x14
    end
    4: begin
        Rs1 = 14;
        Imm = 1;
        Inst = C_ADDI; // x14 = x14 + 1
    end
    default: begin
        Rs1 = 15;
        Imm = 4;
        Inst = C_SLLI;
    end
endcase

integer Cycle = 0;
integer Stop = 10;
always_ff @(posedge clk, posedge rst) begin
    if     (rst)         Cycle <= 0;
    else if(Cycle>=Stop) $finish();
    else                 Cycle <= Cycle + 1;
end
always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
    end
    else begin

    end
end

`include "CtrlSigEnums.sv"
/*  _______________________________________________________________________________
   |                          2-bit control signal tables                          |
   |-------------------------------------------------------------------------------|
   |    ALUOP    | Bitwise |     Arith &     |  Shift  |   PC Write    |    LSU    |
   |   Category  |  ALUOP  |    Flag ALUOP   |  ALUOP  |     Mode      |   Width   |
   |-------------|---------|-----------------|---------|---------------|-----------|
 00|Bitwise ALUBT|Undefined|Signed Sub AFSUBS|SLL SHSLL|Inc      PCINC |LSU Nop LSN|
 01|Add/Sub ALUAS|XOR BTXOR|       Add AFADD |Undefined|Branch   PCBRCH|Word    LSW|
 10|Shift   ALUSH|OR  BTOR |Unsign Sub AFSUBU|SRL SHSRL|Jump Reg PCJREG|Half    LSH|
 11|Flag    ALUFL|AND BTAND|Equality   AFEQU |SRA SHSRA|Jump Imm PCJIMM|Byte    LSB|
   \------------------------------------------------------------------------------/
*/
wire [4:0]  DecodedRs1;
wire [4:0]  DecodedRs2;
wire [4:0]  DecodedRd;
wire [31:0] DecodedImm;
wire [3:0]  CtrlLSU;
wire        CtrlMultiCycle;
wire        CtrlALUImm;
wire [3:0]  CtrlALUOp;
wire        CtrlFlagInv;
wire        CtrlPCWriteback;
wire [1:0]  CtrlPCMode;
CompressedInstructionDecode #(.embedded(0)) 
decoder (
    .InstructionIn  (Inst),
    .Rs1            (DecodedRs1),
    .Rs2            (DecodedRs2),
    .Rd             (DecodedRd),
    .Immediate      (DecodedImm),
    .CtrlLSU        (CtrlLSU),
    .CtrlMultiCycle (CtrlMultiCycle),
    .CtrlALUImm     (CtrlALUImm),
    .CtrlALUOp      (CtrlALUOp),
    .CtrlFlagInv    (CtrlFlagInv),
    .CtrlPCWriteback(CtrlPCWriteback),
    .CtrlPCMode     (CtrlPCMode)
);
wire [31:0] RdData = (CtrlALUOp[3:2] == ALUSH) ? ShiftUnitRd : IntegerUnitRd;
wire [31:0] Rs1Data;
wire [31:0] Rs2Data;
Regfile #(.embedded(0))
regfile (
    .clk(clk),
    .RdAddr (DecodedRd),
    .Rs1Addr(DecodedRs1),
    .Rs2Addr(DecodedRs2),
    .RdData (RdData),
    .Rs1Data(Rs1Data),
    .Rs2Data(Rs2Data)
);
wire [31:0] Rs2IntMux = CtrlALUImm ? DecodedImm : Rs2Data;
wire [31:0] IntegerUnitRd;
wire        IntegerUnitFlag;
IntegerUnit int_unit (
    .Rs1        (Rs1Data),
    .Rs2        (Rs2IntMux),
    .CtrlALUOp  (CtrlALUOp),
    .CtrlFlagInv(CtrlFlagInv),
    .Rd         (IntegerUnitRd),
    .Flag       (IntegerUnitFlag)
);
wire [31:0] ShiftUnitRd;
ShiftUnit shift_unit (
    .Word      (Rs1Data),
    .Shamt     (Rs2IntMux[4:0]),
    .SignExtend(CtrlALUOp[0]),
    .ShiftRight(CtrlALUOp[1]),
    .Result    (ShiftUnitRd)
);
endmodule