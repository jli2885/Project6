module Forwarding_Unit(
    // rs which will be read in the EX stage
    input [4:0] ex_rs1_raddr,
    input [4:0] ex_rs2_raddr,

    // validity signal
    input mem_valid,
    input wb_valid,

    // Control signals
    input mem_regwrite,
    input mem_memread,
    input wb_regwrite,
    
    // load register address
    input [4:0] mem_rd_waddr,
    input [4:0] wb_rd_waddr,
    
    // Forwarding control signals
    output [1:0] ForwardA,
    output [1:0] ForwardB
);

    wire ex_forward_rs1;
    wire ex_forward_rs2;
    wire mem_forward_rs1;
    wire mem_forward_rs2;

    // EX/EX Forwarding
    assign ex_forward_rs1 = mem_valid && mem_regwrite && !mem_memread && (mem_rd_waddr != 5'b0) && (mem_rd_waddr == ex_rs1_raddr);

    assign ex_forward_rs2 = mem_valid && mem_regwrite && !mem_memread && (mem_rd_waddr != 5'b0) && (mem_rd_waddr == ex_rs2_raddr);

    // MEM/EX Forwarding
    assign mem_forward_rs1 = wb_valid && wb_regwrite && (wb_rd_waddr != 5'b0) && (wb_rd_waddr == ex_rs1_raddr);

    assign mem_forward_rs2 = wb_valid && wb_regwrite && (wb_rd_waddr != 5'b0) && (wb_rd_waddr == ex_rs2_raddr);

    // Forwarding MUX Control A (for rs1)
    assign ForwardA = ex_forward_rs1 ? 2'b10 : mem_forward_rs1  ? 2'b01 : 2'b00;
    // Forwarding MUX Control B (for rs2)
    assign ForwardB = ex_forward_rs2 ? 2'b10 : mem_forward_rs2  ? 2'b01 : 2'b00;

endmodule
