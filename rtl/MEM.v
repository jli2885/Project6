module MEM (
    input i_clk,
    input i_rst,

    input wire MemRead,
    input wire MemWrite,
    input wire [31:0] ALU_result,
    input wire [31:0] WriteData,
    input wire [2:0] funct3,

    output wire misaligned,
    output wire [31:0] ReadData,
    output wire mem_stall,

    // Data from/to dmem
    input wire [31:0] i_dmem_rdata,
    input wire        i_dmem_ready,
    input wire        i_dmem_valid,
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_addr,
    output wire [31:0] o_dmem_wdata,
    output wire [3:0] o_dmem_mask
);
    wire reponse;
    wire access_valid;

    mem_control mem_ctrl (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_dmem_ready(i_dmem_ready),
        .i_dmem_valid(i_dmem_valid),
        .exmem_valid(MemRead || MemWrite),
        .mem_read(MemRead),
        .mem_write(MemWrite),
        .access_valid(access_valid),
        .misaligned(misaligned),
        .request_read(o_dmem_ren),
        .request_write(o_dmem_wen),
        .response(response),
        .mem_done(mem_done),
        .mem_stall(mem_stall)
    );

    Data_Memory data_mem (
        .MemRead(MemRead),
        .funct3(funct3),
        .ALU_result(ALU_result),
        .WriteData(WriteData),

        .misaligned(misaligned),
        .access_valid(access_valid),
        .ReadData(ReadData),
        .response(response),

        .i_dmem_addr(i_dmem_addr),
        .i_dmem_wdata(i_dmem_wdata),
        .i_dmem_mask(i_dmem_mask),
        .o_dmem_rdata(o_dmem_rdata)
    );


    
endmodule