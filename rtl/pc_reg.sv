`timescale 1ns / 1ps

`include "constants.sv";

module pc(
    input logic clk,
    input logic w_en,
    input logic [`DATA_ADDR_SIZE-1:0] addr_in,
    output logic [`DATA_ADDR_SIZE-1:0] out
);
    reg [`DATA_ADDR_SIZE-1:0] pc_val;

    always_ff @ (posedge clk) begin : write_path
        if (w_en) begin
            pc_val <= addr_in;
        end else begin
            pc_val <= pc_val + 1;
        end
    end

    always_comb out = pc_val;
endmodule
