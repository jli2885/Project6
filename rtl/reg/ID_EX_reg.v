module ID_EX_reg(
  input wire i_clk,
  input wire i_rst,

  // Inputs Data
  input wire ifid_valid,
  input wire [31:0] id_pc,
  input wire [31:0] id_pc4,
  input wire [31:0] id_inst,
  input wire [31:0] id_rs1_rdata,
  input wire [31:0] id_rs2_rdata,
  input wire [31:0] id_imm,
  input wire [4:0] id_rd_waddr,
  input wire [4:0] id_rs1_raddr,
  input wire [4:0] id_rs2_raddr,
  input wire [6:0] id_funct7,
  input wire [2:0] id_funct3,

  // Inputs Control signals
  input wire [1:0] id_ALUop,
  input wire [1:0] id_jump,
  input wire id_ALUsrc,
  input wire id_AUIPC,
  input wire id_regwrite,
  input wire id_memtoreg,
  input wire id_memread,
  input wire id_memwrite,
  input wire id_branch,
  input wire flush_IDEX,
  input wire mem_stall,

  // Outputs Data
  output reg idex_valid,
  output reg [31:0] ex_pc,
  output reg [31:0] ex_pc4,
  output reg [31:0] ex_inst,
  output reg [31:0] ex_rs1_rdata,
  output reg [31:0] ex_rs2_rdata,
  output reg [31:0] ex_imm,
  output reg [4:0] ex_rd_waddr,
  output reg [4:0] ex_rs1_raddr,
  output reg [4:0] ex_rs2_raddr,
  output reg [6:0] ex_funct7,
  output reg [2:0] ex_funct3,

  // Outputs Control signals
  output reg [1:0] ex_ALUop,
  output reg [1:0] ex_jump,
  output reg ex_ALUsrc,
  output reg ex_AUIPC,
  output reg ex_regwrite,
  output reg ex_memtoreg,
  output reg ex_memread,
  output reg ex_memwrite,
  output reg ex_branch
);

  localparam [31:0] NOP=32'h00000013;

  always @(posedge i_clk) begin
    if(i_rst || flush_IDEX) begin
      idex_valid <= 0;
      ex_pc <= 0;
      ex_pc4 <= 0;
      ex_inst <= NOP;
      ex_rs1_rdata <= 0;
      ex_rs2_rdata <= 0;
      ex_imm <= 0;
      ex_rd_waddr <= 0;
      ex_rs1_raddr <= 0;
      ex_rs2_raddr <= 0;
      ex_funct7 <= 0;
      ex_funct3 <= 0;
      ex_ALUop <= 0;
      ex_jump <= 0;
      ex_ALUsrc <= 0;
      ex_AUIPC <= 0;
      ex_regwrite <= 0;
      ex_memtoreg <= 0;
      ex_memread <= 0;
      ex_memwrite <= 0;
      ex_branch <= 0;
    end else if(!mem_stall) begin
      idex_valid <= ifid_valid;
      ex_pc <= id_pc;
      ex_pc4 <= id_pc4;
      ex_inst <= id_inst;
      ex_rs1_rdata <= id_rs1_rdata;
      ex_rs2_rdata <= id_rs2_rdata;
      ex_imm <= id_imm;
      ex_rd_waddr <= id_rd_waddr;
      ex_rs1_raddr <= id_rs1_raddr;
      ex_rs2_raddr <= id_rs2_raddr;
      ex_funct7 <= id_funct7;
      ex_funct3 <= id_funct3;
      ex_ALUop <= id_ALUop;
      ex_jump <= id_jump;
      ex_ALUsrc <= id_ALUsrc;
      ex_AUIPC <= id_AUIPC;
      ex_regwrite <= id_regwrite;
      ex_memtoreg <= id_memtoreg;
      ex_memread <= id_memread;
      ex_memwrite <= id_memwrite;
      ex_branch <= id_branch;
    end
  end

endmodule
