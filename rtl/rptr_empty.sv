`timescale 1ns / 1ps

module rptr_empty #(parameter int ADDR_WIDTH = 4)(
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    input  logic [ADDR_WIDTH:0]   wptr_gray_sync, // Synchronized write pointer from CDC
    output logic                  empty,
    output logic [ADDR_WIDTH-1:0] raddr,          // Memory read address
    output logic [ADDR_WIDTH:0]   rptr_gray       // Gray pointer to write domain
);

    logic [ADDR_WIDTH:0] rbin;
    logic [ADDR_WIDTH:0] rbin_next;
    logic [ADDR_WIDTH:0] rgray_next;
    logic                empty_val;

    // 1. Advance binary pointer on valid read requests
    assign rbin_next = rbin + (rd_en & ~empty);

    // 2. Binary to Gray conversion: G = B ^ (B >> 1)
    assign rgray_next = rbin_next ^ (rbin_next >> 1);

    // 3. Memory address uses only the lower ADDR_WIDTH bits
    assign raddr = rbin[ADDR_WIDTH-1:0];

    // 4. Empty condition: next read Gray pointer matches synchronized write pointer
    assign empty_val = (rgray_next == wptr_gray_sync);

    // 5. Register updates on read clock domain
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin      <= '0;
            rptr_gray <= '0;
            empty     <= 1'b1; // FIFO starts in empty state
        end else begin
            rbin      <= rbin_next;
            rptr_gray <= rgray_next;
            empty     <= empty_val;
        end
    end

endmodule