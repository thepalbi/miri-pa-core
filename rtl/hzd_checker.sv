`timescale 1ns / 1ps

`include "constants.sv"

module hzd_checker(
    input logic [4:0] rf_r_rs1,
    input logic [4:0] rf_r_rs2,

    input logic d_is_load,
    input logic [4:0] d_rf_waddr_d,
    input logic a_btaken,
    input logic a_is_jal,

    output logic hzd_stall_f,
    output logic hzd_nop_d,
    output logic hzd_nop_f,
    output logic hzd_redirect_pc
    );

    logic load_use;
    logic do_jump;

    // Hazard load-use (stall fetch and make nop)
    assign load_use = d_is_load
                         & (d_rf_waddr_d != 0)
                         & (rf_r_rs1 == d_rf_waddr_d | rf_r_rs2 == d_rf_waddr_d);

    assign do_jump = a_btaken | a_is_jal;

    // Output hazard signals
    assign hzd_stall_f     = load_use;
    assign hzd_nop_d       = load_use | do_jump;
    assign hzd_nop_f       = do_jump;
    assign hzd_redirect_pc = do_jump;

endmodule
