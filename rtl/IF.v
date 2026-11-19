
module IF #(
    parameter RESET_ADDR = 32'h00000000
)(
    input i_clk,
    input i_rst,
    input PCsrc,
    input if_stall,
    input i_imem_ready,
    input i_imem_valid,
    input [31:0] i_imem_rdata,
    input [31:0] target_pc,

    output wire [31:0] o_imem_raddr,
    output wire o_imem_ren,
    output wire [31:0] PC_4,
    output reg [31:0] PC,
    output wire [31:0] inst,
    output wire inst_valid
);
    // Instruction Fetch Control
    reg request_pending;
    reg discard_response;

    // Instruction Buffer
    reg [31:0] inst_buffer;
    reg buffer_valid;

    // Internal Control Signals
    wire request_fire;
    wire response_fire;
    wire inst_fire;

    // PC + 4 ADDER
    assign PC_4 = PC + 32'd4;

    // Instruction Memory Address
    assign o_imem_raddr = PC;

    // Instruction Memory Request
    assign request_fire = i_imem_ready && !request_pending && !buffer_valid && !if_stall && !PCsrc;

    assign o_imem_ren = request_fire;

    // Instruction Memory Response
    assign response_fire = request_pending && i_imem_valid;

    // Instruction Output
    assign inst = buffer_valid ? inst_buffer : 32'h00000013;

    assign inst_valid = buffer_valid && !PCsrc;

    // Instruction Accepted by IF/ID
    assign inst_fire = inst_valid && !if_stall;

    // PC Register
    always @(posedge i_clk) begin
        if (i_rst)
            PC <= RESET_ADDR;
        else if (PCsrc)
            PC <= target_pc;
        else if (inst_fire)
            PC <= PC_4;
    end

    // Memory Request Tracking
    always @(posedge i_clk) begin
        if (i_rst) begin
            request_pending <= 1'b0;
            discard_response <= 1'b0;
        end
        else begin
            if (PCsrc) begin
                if (response_fire) begin
                    request_pending <= 1'b0;
                    discard_response <= 1'b0;
                end
                else if (request_pending) begin
                    discard_response <= 1'b1;
                end
            end
            else if (response_fire) begin
                request_pending <= 1'b0;
                discard_response <= 1'b0;
            end
            else if (request_fire) begin
                request_pending <= 1'b1;
            end
        end
    end

    // Instruction Buffer
    always @(posedge i_clk) begin
        if (i_rst) begin
            inst_buffer <= 32'b0;
            buffer_valid <= 1'b0;
        end
        else if (PCsrc) begin
            buffer_valid <= 1'b0;
        end
        else if (response_fire && !discard_response) begin
            inst_buffer <= i_imem_rdata;
            buffer_valid <= 1'b1;
        end
        else if (inst_fire) begin
            buffer_valid <= 1'b0;
        end
    end

endmodule
