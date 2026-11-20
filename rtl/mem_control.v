module mem_control (
    input wire i_clk,
    input wire i_rst,

    input wire i_dmem_ready,
    input wire i_dmem_valid,

    input wire mem_read,
    input wire mem_write,
    input wire access_valid,
    input wire misaligned,

    output wire request_read,
    output wire request_write,
    output wire response_fire,
    output wire mem_stall
);

    reg request_pending;

    //wire mem_access;
    wire legal_access;
    wire request_fire;

    //assign mem_access = mem_read || mem_write;

    assign legal_access = (mem_read ^ mem_write) && access_valid && !misaligned;

    // Send a request only once
    assign request_fire = !i_rst && !request_pending && legal_access && i_dmem_ready;

    assign request_read = request_fire && mem_read;
    assign request_write = request_fire && mem_write;

    // Both Load and Store receive a completion response
    assign response_fire = !i_rst && request_pending && i_dmem_valid && mem_read;

    // Release stall in the response cycle
    assign mem_stall = legal_access && ((mem_read && !response_fire) || (mem_write && !request_write));

    always @(posedge i_clk) begin
        if (i_rst) begin
            request_pending <= 1'b0;
        end
        else if (response_fire) begin
            request_pending <= 1'b0;
        end
        else if (request_read) begin
            request_pending <= 1'b1;
        end
    end

endmodule
