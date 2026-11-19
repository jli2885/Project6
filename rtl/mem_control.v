
module mem_control (
    input wire i_clk,
    input wire i_rst,

    input wire i_dmem_ready,
    input wire i_dmem_valid,

    input wire exmem_valid,
    input wire mem_read,
    input wire mem_write,
    input wire access_valid,
    input wire misaligned,

    output wire request_read,
    output wire request_write,
    output wire response,
    output wire mem_done,
    output wire mem_stall
);

    localparam IDLE = 2'b00;
    localparam WAIT_RESPONSE = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state;

    wire mem_access;
    wire request;

    // Valid memory operation
    assign mem_access = exmem_valid && (mem_read ^ mem_write) && access_valid && !misaligned;

    // Memory Request
    assign request = (state == IDLE) && mem_access && i_dmem_ready && !i_rst;

    assign request_read = request && mem_read;

    assign request_write = request && mem_write;

    // Memory Response
    assign response = (state == WAIT_RESPONSE) && i_dmem_valid;

    // Memory Operation Completed
    assign mem_done = (state == DONE);

    // Stall Pipeline Until Memory Completes
    assign mem_stall = mem_access && (state != DONE);

    // Memory Control FSM
    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (request)
                        state <= WAIT_RESPONSE;
                end

                WAIT_RESPONSE: begin
                    if (i_dmem_valid)
                        state <= DONE;
                end

                DONE: begin
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
