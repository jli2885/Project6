module MEM_WB_reg(
  input wire i_clk,
  input wire i_rst,
  input wire exmem_valid,
  input wire [31:0] mem_pc,
  input wire [31:0] mem_next_pc,
  input wire [31:0] mem_inst,
  input wire [31:0] mem_ALU_result,
  input wire [31:0] mem_ReadData,
  input wire [31:0] mem_rs1_rdata,
  input wire [31:0] mem_rs2_rdata,
  input wire [4:0] mem_rd_waddr,
  input wire [4:0] mem_rs1_raddr,
  input wire [4:0] mem_rs2_raddr,
  input wire [31:0] o_dmem_addr,
  input wire [31:0] i_dmem_rdata,
  input wire [31:0] o_dmem_wdata,
  input wire [ 3:0] o_dmem_mask,
  // input wire o_dmem_ren,
  // input wire o_dmem_wen,
  input wire mem_regwrite,
  input wire mem_memtoreg,
  input wire mem_trap,
  input wire mem_stall,
  input wire mem_memread,
  input wire mem_memwrite,
  output reg memwb_valid,
  output reg [31:0] wb_pc,
  output reg [31:0] wb_next_pc,
  output reg [31:0] wb_inst,
  output reg [31:0] wb_ALU_result,
  output reg [31:0] wb_ReadData,
  output reg [31:0] wb_rs1_rdata,
  output reg [31:0] wb_rs2_rdata,
  output reg [4:0] wb_rd_waddr,
  output reg [4:0] wb_rs1_raddr,
  output reg [4:0] wb_rs2_raddr,
  output reg [31:0] wb_dmem_addr,
  output reg [31:0] wb_dmem_rdata,
  output reg [31:0] wb_dmem_wdata,
  output reg [3:0] wb_dmem_mask,
  output reg wb_dmem_ren,
  output reg wb_dmem_wen,
  output reg wb_regwrite,
  output reg wb_memtoreg,
  output reg wb_trap
);

  localparam [31:0] NOP=32'h00000013;

  always @(posedge i_clk) begin
    if(i_rst) begin
      memwb_valid <= 0;
      wb_pc <= 0;
      wb_next_pc <= 0;
      wb_inst <= NOP;
      wb_ALU_result <= 0;
      wb_ReadData <= 0;
      wb_rs1_rdata <= 0;
      wb_rs2_rdata <= 0;
      wb_rd_waddr <= 0;
      wb_rs1_raddr <= 0;
      wb_rs2_raddr <= 0;
      wb_dmem_addr <= 0;
      wb_dmem_rdata <= 0;
      wb_dmem_wdata <= 0;
      wb_dmem_mask <= 0;
      wb_dmem_ren <= 0;
      wb_dmem_wen <= 0;
      wb_regwrite <= 0;
      wb_memtoreg <= 0;
      wb_trap <= 0;
    end else begin
      memwb_valid <= exmem_valid && !mem_stall;;
      wb_pc <= mem_pc;
      wb_next_pc <= mem_next_pc;
      wb_inst <= mem_inst;
      wb_ALU_result <= mem_ALU_result;
      wb_ReadData <= mem_ReadData;
      wb_rs1_rdata <= mem_rs1_rdata;
      wb_rs2_rdata <= mem_rs2_rdata;
      wb_rd_waddr <= mem_rd_waddr;
      wb_rs1_raddr <= mem_rs1_raddr;
      wb_rs2_raddr <= mem_rs2_raddr;
      wb_dmem_addr <= o_dmem_addr;
      wb_dmem_rdata <= (mem_memread && !mem_stall && !mem_trap) ? i_dmem_rdata : 32'b0;
      wb_dmem_wdata <= o_dmem_wdata;
      wb_dmem_mask <= o_dmem_mask;
      wb_dmem_ren <= mem_memread && exmem_valid && !mem_stall && !mem_trap;
      wb_dmem_wen <= mem_memwrite && exmem_valid && !mem_stall && !mem_trap;
      wb_regwrite <= mem_regwrite;
      wb_memtoreg <= mem_memtoreg;
      wb_trap <= exmem_valid && !mem_stall && mem_trap;
    end
  end

endmodule
