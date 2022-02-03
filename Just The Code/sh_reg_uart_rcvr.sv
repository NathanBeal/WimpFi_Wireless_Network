`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : sh_reg_uart_rcvr
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : UART rcvr shreg, different width than the provided module
//               : in SV_examples
//////////////////////////////////////////////////////////////////////////////////

module sh_reg_uart_rcvr #(parameter W=8)
                (input logic clk, rst, shen, lden, s_in,
                 input logic [W-1:0]  d,
                 output logic [W-1:0] q);

  always_ff @(posedge clk)
    if (rst) q <= '0;
    else if (lden) q <= d;
    else if (shen) q <= { s_in, q[W-1:1] };

endmodule: sh_reg_uart_rcvr
