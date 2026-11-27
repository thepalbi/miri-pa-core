`timescale 1ns / 1ps

`include "constants.sv"

module hzd_checker(
    input logic [4:0] rf_r_rs1,
    input logic [4:0] rf_r_rs2,

    input logic d_is_load,
    input logic [4:0] d_rf_waddr_d,

    output logic hzd_stall_f,
    output logic hzd_nop_d
    );

    logic hzd_load_use;

    // Hazard load-use (stall fetch and make nop)
    assign hzd_load_use = d_is_load
                         & (d_rf_waddr_d != 0)
                         & (rf_r_rs1 == d_rf_waddr_d | rf_r_rs2 == d_rf_waddr_d);

    assign hzd_stall_f = hzd_load_use;
    assign hzd_nop_d   = hzd_load_use;

endmodule
