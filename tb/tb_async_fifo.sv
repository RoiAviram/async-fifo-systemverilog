`timescale 1ns / 1ps

module tb_async_fifo;

    // Parameters
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 4;
    localparam int DEPTH      = 1 << ADDR_WIDTH;

    // Clock periods: wr_clk = 100MHz (10ns), rd_clk = 40MHz (25ns)
    localparam time WR_CLK_PERIOD = 10ns;
    localparam time RD_CLK_PERIOD = 25ns;

    // DUT Signals
    logic                  wr_clk;
    logic                  wr_rst_n;
    logic                  wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic                  full;

    logic                  rd_clk;
    logic                  rd_rst_n;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  empty;

    // Golden reference queue for data integrity verification
    logic [DATA_WIDTH-1:0] expected_queue[$];
    int error_count = 0;

    // Instantiate Device Under Test (DUT)
    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_rst_n),
        .wr_en    (wr_en),
        .wr_data  (wr_data),
        .full     (full),
        .rd_clk   (rd_clk),
        .rd_rst_n (rd_rst_n),
        .rd_en    (rd_en),
        .rd_data  (rd_data),
        .empty    (empty)
    );

    // 1. Clock Generation
    initial begin
        wr_clk = 1'b0;
        forever #(WR_CLK_PERIOD / 2) wr_clk = ~wr_clk;
    end

    initial begin
        rd_clk = 1'b0;
        forever #(RD_CLK_PERIOD / 2) rd_clk = ~rd_clk;
    end

    // 2. Normal Write Task with Backpressure Flow Control
    task automatic write_data(input logic [DATA_WIDTH-1:0] data);
        @(posedge wr_clk);
        // Wait until FIFO has space available
        while (full) begin
            @(posedge wr_clk);
        end
        wr_en   <= 1'b1;
        wr_data <= data;
        expected_queue.push_back(data);
        @(posedge wr_clk);
        wr_en   <= 1'b0;
    endtask

    // 3. Deliberate Overflow Write Task (Scenario 1 only)
    task automatic test_overflow_write(input logic [DATA_WIDTH-1:0] data);
        @(posedge wr_clk);
        wr_en   <= 1'b1;
        wr_data <= data;
        $display("[OVERFLOW ATTEMPT] Time=%0t | Intentional overflow write: 0x%0h (Full=%0b)", $time, data, full);
        @(posedge wr_clk);
        wr_en   <= 1'b0;
    endtask

    // 4. Read Task
    task automatic read_data();
        logic [DATA_WIDTH-1:0] expected_val;
        @(posedge rd_clk);
        if (!empty) begin
            expected_val = expected_queue.pop_front();
            if (rd_data !== expected_val) begin
                $error("[DATA MISMATCH] Time=%0t | Expected=0x%0h, Got=0x%0h", $time, expected_val, rd_data);
                error_count++;
            end else begin
                $display("[READ MATCH] Time=%0t | Data=0x%0h", $time, rd_data);
            end

            rd_en <= 1'b1;
            @(posedge rd_clk);
            rd_en <= 1'b0;
        end else begin
            rd_en <= 1'b1;
            $display("[UNDERFLOW ATTEMPT] Time=%0t | Attempted read from Empty FIFO", $time);
            @(posedge rd_clk);
            rd_en <= 1'b0;
        end
    endtask

    // 5. Verification Test Execution
    initial begin
        // Signal Initialization
        wr_rst_n = 1'b0;
        rd_rst_n = 1'b0;
        wr_en    = 1'b0;
        rd_en    = 1'b0;
        wr_data  = '0;

        // Apply Reset
        #50ns;
        wr_rst_n = 1'b1;
        rd_rst_n = 1'b1;
        #20ns;

        $display("\n--- SCENARIO 1: Basic Fill to Full & Overflow Test ---");
        for (int i = 0; i < DEPTH; i++) begin
            write_data(8'hA0 + i);
        end

        // Wait for synchronizer settling
        repeat(5) @(posedge wr_clk);

        // Attempt 2 additional writes when FIFO is full
        test_overflow_write(8'hFF);
        test_overflow_write(8'hEE);

        $display("\n--- SCENARIO 2: Read to Empty & Underflow Test ---");
        for (int i = 0; i < DEPTH; i++) begin
            read_data();
        end

        // Wait for empty propagation across CDC
        repeat(5) @(posedge rd_clk);

        // Attempt read on empty
        read_data();

        $display("\n--- SCENARIO 3: Concurrent Asynchronous Write & Read ---");
        fork
            begin : concurrent_write
                for (int i = 0; i < 30; i++) begin
                    write_data(8'h10 + i);
                    #(WR_CLK_PERIOD * 2);
                end
            end
            begin : concurrent_read
                #(RD_CLK_PERIOD * 3); // Initial offset
                for (int j = 0; j < 30; j++) begin
                    read_data();
                    #(RD_CLK_PERIOD);
                end
            end
        join

        // Drain any residual elements
        while (expected_queue.size() > 0) begin
            read_data();
            repeat(2) @(posedge rd_clk);
        end

        // Final Report
        #100ns;
        $display("\n==========================================");
        if (error_count == 0) begin
            $display(">> TEST PASSED: All checks and CDC boundaries verified cleanly! <<");
        end else begin
            $display(">> TEST FAILED: %0d data integrity mismatches detected! <<", error_count);
        end
        $display("==========================================\n");

        $finish;
    end

endmodule