`timescale 1ns / 1ps

`include "constants.sv"

module sign_extender #(
    parameter tgt_size,
    parameter src_size
) (
    input logic  [src_size-1:0] src,
    output logic [tgt_size-1:0] tgt
);
    localparam int diff = tgt_size - src_size;
    assign tgt = {{ diff{src[src_size-1]} }, src};
endmodule
