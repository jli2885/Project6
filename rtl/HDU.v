module HDU (
    // Instruction
    input wire [31:0] IF_ID_inst,

    // Validity signals
    input wire IF_ID_valid,
    input wire ID_EX_valid,

    // Memory read signal
    input wire ID_EX_MemRead,

    // Rd will execute in the EX
    input wire [4:0] ID_EX_rd,
    
    // Redirect signal
    input wire redirect_ex,

    // Data Memory Wait
    input wire dmem_wait,

    // HDU signals
    output wire stall_IF,
    output wire stall_IFID,
    output wire stall_IDEX,
    output wire stall_EXMEM,
    output wire flush_IFID,
    output wire flush_IDEX
);
    wire [6:0] opcode;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire uses_rs1;
    wire uses_rs2;
    wire data_hazard;

    assign opcode = IF_ID_inst[6:0];
    assign rs1 = IF_ID_inst[19:15];
    assign rs2 = IF_ID_inst[24:20];

    assign uses_rs1= (opcode==7'b0110011 || opcode==7'b0010011 || opcode==7'b0000011 ||
                      opcode==7'b0100011 || opcode==7'b1100011 || opcode==7'b1100111);
    assign uses_rs2= (opcode==7'b0110011 || opcode==7'b0100011 || opcode==7'b1100011);

    // Load-use Hazard
    assign data_hazard = IF_ID_valid && ID_EX_valid && ID_EX_MemRead && (ID_EX_rd != 5'd0) &&
                         ((uses_rs1 && rs1 == ID_EX_rd) || (uses_rs2 && rs2 == ID_EX_rd));

    // Stall Control
    assign stall_IF = dmem_wait || (data_hazard && !redirect_ex);
    assign stall_IFID = dmem_wait || (data_hazard && !redirect_ex);
    assign stall_IDEX = dmem_wait;
    assign stall_EXMEM = dmem_wait;

    // Flush Control
    assign flush_IFID = redirect_ex && !dmem_wait;
    assign flush_IDEX = !dmem_wait && (redirect_ex || data_hazard);

endmodule
