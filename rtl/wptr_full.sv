`timescale 1ns / 1ps

module wptr_full #(parameter int ADDR_WIDTH = 4)(
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH:0]   rptr_gray_sync, // Synchronized read pointer from CDC
    output logic                  full,
    output logic [ADDR_WIDTH-1:0] waddr,          // Memory write address
    output logic [ADDR_WIDTH:0]   wptr_gray       // Gray pointer to read domain
);

    logic [ADDR_WIDTH:0] wbin;
    logic [ADDR_WIDTH:0] wbin_next;
    logic [ADDR_WIDTH:0] wgray_next;
    logic                full_val;

    // 1. Advance binary pointer on valid write requests
    assign wbin_next = wbin + (wr_en & ~full);

    // 2. Binary to Gray conversion: G = B ^ (B >> 1)
    assign wgray_next = wbin_next ^ (wbin_next >> 1);

    // 3. Memory address uses only the lower ADDR_WIDTH bits
    assign waddr = wbin[ADDR_WIDTH-1:0];

    // 4. Full condition: MSB and MSB-1 inverted, remaining LSBs identical
    assign full_val = (wgray_next == {~rptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1], 
                                       rptr_gray_sync[ADDR_WIDTH-2:0]});

    // 5. Register updates on write clock domain
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin      <= '0;
            wptr_gray <= '0;
            full      <= 1'b0; // FIFO starts not full
        end else begin
            wbin      <= wbin_next;
            wptr_gray <= wgray_next;
            full      <= full_val;
        end
    end

endmodule