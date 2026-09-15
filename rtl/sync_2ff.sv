`timescale 1ns / 1ps

module sync_2ff #( parameter int WIDTH = 5)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] async_in,
    output logic [WIDTH-1:0] sync_out
);

    // אילוץ ייעודי ל-Vivado לקירוב פיזי של הדרגות ומניעת מטא-סטביליות
    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] sync_stage1;
    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] sync_stage2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= '0;
            sync_stage2 <= '0;
        end else begin
            sync_stage1 <= async_in;
            sync_stage2 <= sync_stage1;
        end
    end

    assign sync_out = sync_stage2;

endmodule