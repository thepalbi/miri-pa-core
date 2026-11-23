`timescale 1ns / 1ps

`include "constants.sv"

module fwd_checker(
    input [4:0] rf_r_rs1,
    input [4:0] rf_r_rs2,
    input d_writes_rd,
    input [4:0] d_rf_waddr_d,

    output logic fwd_aluout_rs1,
    output logic fwd_aluout_rs2
);
    assign fwd_aluout_rs1 = d_writes_rd && (rf_r_rs1 == d_rf_waddr_d);
    assign fwd_aluout_rs2 = d_writes_rd && (rf_r_rs2 == d_rf_waddr_d);
endmodule
