`timescale 1ns / 1ps

`include "constants.sv"

module fwd_checker(
    input logic [4:0] rf_r_rs1,
    input logic [4:0] rf_r_rs2,
    input logic d_writes_rd,
    input logic [4:0] d_rf_waddr_d,
    input logic a_is_load,
    input logic [4:0] a_rf_waddr_d,

    output logic fwd_aluout_rs1,
    output logic fwd_aluout_rs2,
    output logic fwd_mdmemrdata_aluin_a,
    output logic fwd_mdmemrdata_aluin_b
);
    assign fwd_aluout_rs1 = d_writes_rd
                            && (d_rf_waddr_d != 0)
                            && (rf_r_rs1 == d_rf_waddr_d);
    assign fwd_aluout_rs2 = d_writes_rd
                            && (d_rf_waddr_d != 0)
                            && (rf_r_rs2 == d_rf_waddr_d);

    assign fwd_mdmemrdata_aluin_a = a_is_load && (rf_r_rs1 == a_rf_waddr_d);
    assign fwd_mdmemrdata_aluin_b = a_is_load && (rf_r_rs2 == a_rf_waddr_d);
endmodule
