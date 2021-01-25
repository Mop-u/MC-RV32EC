module MainDecode #(
    parameter embedded = 1
)(
    input  [31:0] InstructionIn,
    output [raddr_w-1:0] Rs1,
    output [raddr_w-1:0] Rs2,
    output [raddr_w-1:0] Rd,
    output [31:0] ImmALU, // goes downstream
    output [31:0] ImmPC,  // critical path!
    output [3:0]  CtrlLSU,
    output        CtrlMultiCycle,
    output        CtrlALUImm,
    output [3:0]  CtrlALUOp,
    output        CtrlFlagInv,
    output        CtrlPCWriteback,
    output [1:0]  CtrlPCMode,
    output        ValidDecode,
    output        CompressedDecode
);
localparam raddr_w = embedded ? 4 : 5;

assign ValidDecode = I_ValidDecode | C_ValidDecode;
assign CompressedDecode = C_ValidDecode;

assign Rs1             = &InstructionIn[1:0] ? I_Rs1             : C_Rs1;
assign Rs2             = &InstructionIn[1:0] ? I_Rs2             : C_Rs2;
assign Rd              = &InstructionIn[1:0] ? I_Rd              : C_Rd;
assign ImmALU          = &InstructionIn[1:0] ? I_ImmALU          : C_ImmALU;
assign ImmPC           = &InstructionIn[1:0] ? I_ImmPC           : C_ImmPC;
assign CtrlLSU         = &InstructionIn[1:0] ? I_CtrlLSU         : C_CtrlLSU;
assign CtrlMultiCycle  = &InstructionIn[1:0] ? I_CtrlMultiCycle  : C_CtrlMultiCycle;
assign CtrlALUImm      = &InstructionIn[1:0] ? I_CtrlALUImm      : C_CtrlALUImm;
assign CtrlALUOp       = &InstructionIn[1:0] ? I_CtrlALUOp       : C_CtrlALUOp;
assign CtrlFlagInv     = &InstructionIn[1:0] ? I_CtrlFlagInv     : C_CtrlFlagInv;
assign CtrlPCWriteback = &InstructionIn[1:0] ? I_CtrlPCWriteback : C_CtrlPCWriteback;
assign CtrlPCMode      = &InstructionIn[1:0] ? I_CtrlPCMode      : C_CtrlPCMode;

wire [raddr_w-1:0] C_Rs1;
wire [raddr_w-1:0] C_Rs2;
wire [raddr_w-1:0] C_Rd;
wire [31:0]        C_ImmALU;
wire [31:0]        C_ImmPC;
wire [3:0]         C_CtrlLSU;
wire               C_CtrlMultiCycle;
wire               C_CtrlALUImm;
wire [3:0]         C_CtrlALUOp;
wire               C_CtrlFlagInv;
wire               C_CtrlPCWriteback;
wire [1:0]         C_CtrlPCMode;
wire               C_ValidDecode;
CompressedInstructionDecode #(.embedded(embedded))
compressed_instruction_decode (
    .InstructionIn  (InstructionIn[15:0]),
    .Rs1            (C_Rs1),
    .Rs2            (C_Rs2),
    .Rd             (C_Rd),
    .ImmALU         (C_ImmALU),
    .ImmPC          (C_ImmPC),
    .CtrlLSU        (C_CtrlLSU),
    .CtrlMultiCycle (C_CtrlMultiCycle),
    .CtrlALUImm     (C_CtrlALUImm),
    .CtrlALUOp      (C_CtrlALUOp),
    .CtrlFlagInv    (C_CtrlFlagInv),
    .CtrlPCWriteback(C_CtrlPCWriteback),
    .CtrlPCMode     (C_CtrlPCMode),
    .ValidDecode    (C_ValidDecode)
);
wire [raddr_w-1:0] I_Rs1;
wire [raddr_w-1:0] I_Rs2;
wire [raddr_w-1:0] I_Rd;
wire [31:0]        I_ImmALU;
wire [31:0]        I_ImmPC;
wire [3:0]         I_CtrlLSU;
wire               I_CtrlMultiCycle;
wire               I_CtrlALUImm;
wire [3:0]         I_CtrlALUOp;
wire               I_CtrlFlagInv;
wire               I_CtrlPCWriteback;
wire [1:0]         I_CtrlPCMode;
wire               I_ValidDecode;
IntegerInstructionDecode #(.embedded(embedded))
integer_instruction_decode (
    .InstructionIn  (InstructionIn),
    .Rs1            (I_Rs1),
    .Rs2            (I_Rs2),
    .Rd             (I_Rd),
    .ImmALU         (I_ImmALU),
    .ImmPC          (I_ImmPC),
    .CtrlLSU        (I_CtrlLSU),
    .CtrlMultiCycle (I_CtrlMultiCycle),
    .CtrlALUImm     (I_CtrlALUImm),
    .CtrlALUOp      (I_CtrlALUOp),
    .CtrlFlagInv    (I_CtrlFlagInv),
    .CtrlPCWriteback(I_CtrlPCWriteback),
    .CtrlPCMode     (I_CtrlPCMode),
    .ValidDecode    (I_ValidDecode)
);

endmodule