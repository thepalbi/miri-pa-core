`timescale 1ns / 1ps

`include "constants.sv";

module pc(
    input logic clk,
    input logic rst,
    input logic run,
    input logic stall,
    input logic w_en,
    input logic [`DATA_ADDR_SIZE-1:0] addr_in,
    output logic [`DATA_ADDR_SIZE-1:0] out
);
    reg [`DATA_ADDR_SIZE-1:0] pc_val;

    always_ff @ (posedge clk or posedge rst) begin : write_path
        if (rst) begin
            pc_val <= 0;
        end else if (!run | stall) begin
            pc_val <= pc_val;
        end else if (w_en && run) begin
            pc_val <= addr_in;
        end else begin
            pc_val <= pc_val + 1; // TODO: Revisar, deberia ser +4 !
        end
    end

    always_comb out = pc_val;
endmodule
