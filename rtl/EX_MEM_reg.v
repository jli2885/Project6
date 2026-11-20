module EX_MEM_reg(
  input wire i_clk,
  input wire i_rst,

  input wire idex_valid,

  // Input data from EX stage
  input wire [31:0] ex_pc,
  input wire [31:0] ex_pc4,
  input wire [31:0] ex_inst,
  input wire branch_redirect,
  input wire [31:0] target_pc,
  input wire [1:0] ex_jump,
  input wire [31:0] ex_ALU_result,
  input wire [31:0] forward_rs1,
  input wire [31:0] forward_rs2,
  input wire [4:0] ex_rd_waddr,
  input wire [4:0] ex_rs1_raddr,
  input wire [4:0] ex_rs2_raddr,
  input wire [2:0] ex_funct3,

  // Control signal Input
  input wire ex_regwrite,
  input wire ex_memtoreg,
  input wire ex_memread,
  input wire ex_memwrite,
  input wire mem_stall,

  output reg exmem_valid,
  // Output data to MEM stage
  output reg [31:0] mem_pc,
  output reg [31:0] mem_pc4,
  output reg [31:0] mem_inst,
  output reg [31:0] mem_next_pc,
  output reg [31:0] mem_ALU_result,
  output reg [31:0] mem_rs2_rdata,
  output reg [31:0] mem_rs1_rdata,
  output reg [4:0] mem_rd_waddr,
  output reg [4:0] mem_rs1_raddr,
  output reg [4:0] mem_rs2_raddr,
  output reg [2:0] mem_funct3,

  // Control signal Output
  output reg mem_regwrite,
  output reg mem_memtoreg,
  output reg mem_memread,
  output reg mem_memwrite
);

  localparam [31:0] NOP=32'h00000013;

  always @(posedge i_clk) begin
    if(i_rst) begin
      exmem_valid<=0;
      mem_pc <= 0;
      mem_pc4 <= 0;
      mem_inst <= NOP;
      mem_next_pc <= 0;
      mem_ALU_result <= 0;
      mem_rs2_rdata <= 0;
      mem_rs1_rdata <= 0;
      mem_rd_waddr <= 0;
      mem_rs1_raddr <= 0;
      mem_rs2_raddr <= 0;
      mem_funct3 <= 0;
      mem_regwrite <= 0;
      mem_memtoreg <= 0;
      mem_memread <= 0;
      mem_memwrite <= 0;
    end else if(!mem_stall) begin
      exmem_valid <= idex_valid;
      mem_pc <= ex_pc;
      mem_pc4 <= ex_pc4;
      mem_inst <= ex_inst;
      mem_next_pc <= branch_redirect ? target_pc:ex_pc4;
      mem_ALU_result <= (ex_jump!=2'b00) ? ex_pc4:ex_ALU_result;
      mem_rs2_rdata <= forward_rs2;
      mem_rs1_rdata <= forward_rs1;
      mem_rd_waddr <= ex_rd_waddr;
      mem_rs1_raddr <= ex_rs1_raddr;
      mem_rs2_raddr <= ex_rs2_raddr;
      mem_funct3 <= ex_funct3;
      mem_regwrite <= ex_regwrite;
      mem_memtoreg <= ex_memtoreg;
      mem_memread <= ex_memread;
      mem_memwrite <= ex_memwrite;
    end
  end

endmodule
