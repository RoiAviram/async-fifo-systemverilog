`timescale 1ns / 1ps

module fifo_mem #(parameter int DATA_WIDTH = 8,parameter int ADDR_WIDTH = 4)(
    // Write clock domain ports
    input  logic                  wr_clk,
    input  logic                  wr_en,
    input  logic                  full,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [DATA_WIDTH-1:0] wr_data,

    // Read clock domain ports
    input  logic [ADDR_WIDTH-1:0] raddr,
    output logic [DATA_WIDTH-1:0] rd_data
);

    localparam int DEPTH = 1 << ADDR_WIDTH;

    // Storage memory array (inferred as Distributed RAM by Vivado)
    logic [DATA_WIDTH-1:0] mem [DEPTH];

    // Synchronous write operation guarded against overflow
    always_ff @(posedge wr_clk) begin
        if (wr_en && !full) begin
            mem[waddr] <= wr_data;
        end
    end

    // Asynchronous combinational read (FWFT: 0-cycle latency)
    assign rd_data = mem[raddr];

endmodule