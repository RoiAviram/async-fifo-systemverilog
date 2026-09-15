`timescale 1ns / 1ps

module async_fifo #(parameter int DATA_WIDTH = 8,parameter int ADDR_WIDTH = 4)(
    // Write clock domain
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    // Read clock domain
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    // Internal interconnect wires
    logic [ADDR_WIDTH-1:0] waddr;
    logic [ADDR_WIDTH-1:0] raddr;
    logic [ADDR_WIDTH:0]   wptr_gray;
    logic [ADDR_WIDTH:0]   rptr_gray;
    logic [ADDR_WIDTH:0]   wptr_gray_sync;
    logic [ADDR_WIDTH:0]   rptr_gray_sync;

    // 1. Dual-port storage memory core
    fifo_mem #( .DATA_WIDTH (DATA_WIDTH),.ADDR_WIDTH (ADDR_WIDTH)) u_fifo_mem (
        .wr_clk  (wr_clk),
        .wr_en   (wr_en),
        .full    (full),
        .waddr   (waddr),
        .wr_data (wr_data),
        .raddr   (raddr),
        .rd_data (rd_data)
    );

    // 2. Write pointer and full flag generator
    wptr_full #( .ADDR_WIDTH (ADDR_WIDTH)) u_wptr_full (
        .wr_clk         (wr_clk),
        .wr_rst_n       (wr_rst_n),
        .wr_en          (wr_en),
        .rptr_gray_sync (rptr_gray_sync),
        .full           (full),
        .waddr          (waddr),
        .wptr_gray      (wptr_gray)
    );

    // 3. Read pointer and empty flag generator
    rptr_empty #( .ADDR_WIDTH (ADDR_WIDTH)) u_rptr_empty (
        .rd_clk         (rd_clk),
        .rd_rst_n       (rd_rst_n),
        .rd_en          (rd_en),
        .wptr_gray_sync (wptr_gray_sync),
        .empty          (empty),
        .raddr          (raddr),
        .rptr_gray      (rptr_gray)
    );

    // 4. Synchronize write pointer into read domain (wr_clk -> rd_clk)
    sync_2ff #( .WIDTH (ADDR_WIDTH + 1)) u_sync_w2r (
        .clk      (rd_clk),
        .rst_n    (rd_rst_n),
        .async_in (wptr_gray),
        .sync_out (wptr_gray_sync)
    );

    // 5. Synchronize read pointer into write domain (rd_clk -> wr_clk)
    sync_2ff #( .WIDTH (ADDR_WIDTH + 1)) u_sync_r2w (
        .clk      (wr_clk),
        .rst_n    (wr_rst_n),
        .async_in (rptr_gray),
        .sync_out (rptr_gray_sync)
    );

endmodule