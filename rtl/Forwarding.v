module Forwarding_Unit(
    input i_clk,
    input i_rst,

    input stall_EX,

    // rs which will be read in the EX stage
    input [4:0] ex_rs1_raddr,
    input [4:0] ex_rs2_raddr,

    // validity signal
    input mem_valid,
    input wb_valid,
    input ex_valid,

    // Control signals
    input mem_regwrite,
    input mem_memread,
    input wb_regwrite,
    
    // load register address
    input [4:0] mem_rd_waddr,
    input [4:0] wb_rd_waddr,
    input [31:0] wb_data,
    
    // Forwarding control signals
    output [1:0] ForwardA,
    output [1:0] ForwardB,

    //saved forward data
    output [31:0] saved_rs1_data,
    output [31:0] saved_rs2_data
);

    wire ex_forward_rs1;
    wire ex_forward_rs2;
    wire mem_forward_rs1;
    wire mem_forward_rs2;
    wire mem_match_rs1;
    wire mem_match_rs2;
    wire wb_match_rs1;
    wire wb_match_rs2;

    reg saved_rs1_valid;
    reg saved_rs2_valid;

    wire saved_forward_rs1;
    wire saved_forward_rs2;

    reg [31:0] saved_rs1_data_reg;
    reg [31:0] saved_rs2_data_reg;

    //register match
    assign mem_match_rs1 = ex_valid && mem_valid && (mem_rd_waddr != 5'b0) && (mem_rd_waddr == ex_rs1_raddr) && mem_regwrite;
    assign mem_match_rs2 = ex_valid && mem_valid && (mem_rd_waddr != 5'b0) && (mem_rd_waddr == ex_rs2_raddr) && mem_regwrite;

    assign wb_match_rs1 = ex_valid && wb_valid && (wb_rd_waddr != 5'b0) && (wb_rd_waddr == ex_rs1_raddr) && wb_regwrite;
    assign wb_match_rs2 = ex_valid && wb_valid && (wb_rd_waddr != 5'b0) && (wb_rd_waddr == ex_rs2_raddr) && wb_regwrite;

    // EX/EX Forwarding
    assign ex_forward_rs1 = mem_match_rs1 && !mem_memread;
    assign ex_forward_rs2 = mem_match_rs2 && !mem_memread;

    // MEM/EX Forwarding
    assign mem_forward_rs1 = wb_match_rs1 && !mem_match_rs1;
    assign mem_forward_rs2 = wb_match_rs2 && !mem_match_rs2;

    //save wb data
    always @(posedge i_clk) begin
        if (i_rst || !ex_valid) begin
            saved_rs1_valid <= 1'b0;
            saved_rs2_valid <= 1'b0;
            saved_rs1_data_reg <= 32'b0;
            saved_rs2_data_reg <= 32'b0;
        end else if (!stall_EX) begin
            saved_rs1_valid <= 1'b0;
            saved_rs2_valid <= 1'b0;
        end else begin
            if(mem_forward_rs1) begin
                saved_rs1_valid <= 1'b1;
                saved_rs1_data_reg <= wb_data;
            end
            if(mem_forward_rs2) begin
                saved_rs2_valid <= 1'b1;
                saved_rs2_data_reg <= wb_data;
            end
        end
    end

    assign saved_rs1_data = saved_rs1_data_reg;
    assign saved_rs2_data = saved_rs2_data_reg;

    //save wb forwarding
    assign saved_forward_rs1 = ex_valid && saved_rs1_valid && !mem_match_rs1;
    assign saved_forward_rs2 = ex_valid && saved_rs2_valid && !mem_match_rs2;

    // Forwarding MUX Control A (for rs1)
    assign ForwardA = ex_forward_rs1 ? 2'b10 : mem_forward_rs1  ? 2'b01 : saved_forward_rs1 ? 2'b11 : 2'b00;
    // Forwarding MUX Control B (for rs2)
    assign ForwardB = ex_forward_rs2 ? 2'b10 : mem_forward_rs2  ? 2'b01 : saved_forward_rs2 ? 2'b11 : 2'b00;

endmodule
