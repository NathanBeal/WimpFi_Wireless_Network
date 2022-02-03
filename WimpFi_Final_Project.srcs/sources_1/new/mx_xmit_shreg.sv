`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : sh_reg
// Project       : RTL Hardware Design and Verification using SystemVerilog
//-----------------------------------------------------------------------------
// Author        : John Nestor  <nestorj@lafayette.edu>
// Created       : Feb 2020
//-----------------------------------------------------------------------------
// Description   : Shift register with parallel load parameterized by bitwidth
//-----------------------------------------------------------------------------
// Edited by     : Nate Beal  <bealn@lafayette.edu>
// Created       : Apr 2021
//-----------------------------------------------------------------------------
// Description   : Added shift_idle parameter which assigns q an all high value
//                 to be shifted out, also changed init parameter of W=8 to W=16
//-----------------------------------------------------------------------------


module mx_xmit_shreg #(parameter W=16)
                (input logic clk, rst, shen, lden, s_in, shift_idle,
                 input logic [W-1:0]  d,
                 output logic [W-1:0] q);

  always_ff @(posedge clk)
    if (rst) q <= '0;
    else if (lden) q <= d;
    else if (shen) q <= { s_in, q[W-1:1] };
    else if (shift_idle) q <= 16'b1111111111111111;

endmodule: mx_xmit_shreg