`timescale 1ns / 1ps

`include "constants.sv"

module fwd_checker(
    input logic [4:0] rf_r_rs1,
    input logic [4:0] rf_r_rs2,
    input logic d_writes_rd,
    input logic [4:0] d_rf_waddr_d,
    input logic a_is_load,
    input logic a_writes_rd,
    input logic [4:0] a_rf_waddr_d,

    output logic fwd_aluout_rs1,
    output logic fwd_aluout_rs2,
    output logic fwd_rfwdata_rs1,
    output logic fwd_rfwdata_rs2
);
    // Distance 1
    assign fwd_aluout_rs1 = d_writes_rd
                            && (d_rf_waddr_d != 0)
                            && (rf_r_rs1 == d_rf_waddr_d);
    assign fwd_aluout_rs2 = d_writes_rd
                            && (d_rf_waddr_d != 0)
                            && (rf_r_rs2 == d_rf_waddr_d);
    // Distance 2
    assign fwd_rfwdata_rs1 = a_writes_rd
                            && (a_rf_waddr_d != 0)
                            && (rf_r_rs1 == a_rf_waddr_d)
                            && !fwd_aluout_rs1;
    assign fwd_rfwdata_rs2 = a_writes_rd
                            && (a_rf_waddr_d != 0)
                            && (rf_r_rs2 == a_rf_waddr_d)
                            && !fwd_aluout_rs2;

endmodule
