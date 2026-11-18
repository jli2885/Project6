module IF_ID_reg(
  input wire i_clk,
  input wire i_rst,
  // Input Data from IF stage
  input wire [31:0] if_pc,
  input wire [31:0] if_pc4,
  input wire [31:0] if_inst,

  // Control signals for IF/ID stage
  input wire stall_IFID,
  input wire flush_IFID,

  // Output Data to ID stage
  output reg ifid_valid,
  output reg [31:0] id_pc,
  output reg [31:0] id_pc4,
  output reg [31:0] id_inst
);
  localparam [31:0] NOP=32'h00000013;

  always @(posedge i_clk) begin
    if(i_rst || flush_IFID) begin
      ifid_valid <=1'b0;
      id_pc <= 0;
      id_pc4 <= 0;
      id_inst <= NOP;
    end else if(!stall_IFID) begin
      ifid_valid <= 1'b1;
      id_pc <= if_pc;
      id_pc4 <= if_pc4;
      id_inst <= if_inst;
    end
  end

endmodule
