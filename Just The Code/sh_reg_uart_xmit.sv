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

module sh_reg_uart_xmit #(parameter W=4)
                (input logic clk, rst, shen, lden, s_in, shift_idle,
                 input logic [W-1:0]  d,
                 output logic [W-1:0] q);

  always_ff @(posedge clk)
    if (rst) q <= '0;
    else if (shen) q <= { s_in, q[W-1:1] };
    else if (shift_idle) q <= 10'b1111111111;
    else if (lden) q <= d;

endmodule: sh_reg_uart_xmit