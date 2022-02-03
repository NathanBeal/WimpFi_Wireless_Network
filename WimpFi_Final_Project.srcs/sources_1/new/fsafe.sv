`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : fsafe
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : fsafe module provided in the exam and implemented into our final 
//               : project.
//////////////////////////////////////////////////////////////////////////////////

module fsafe #(parameter BIT_RATE = 50000, BPLIMIT = 512)
(
    input clk, rst, txen,
    output txen_safe, txen_fail
);

    logic bp_enb;

    rate_enb #(.RATE_HZ(BIT_RATE))   U_FS_RATE_ENB(.clk, .rst, .clr(1'b0), .enb_out(bp_enb));
    fsafe_fsm #(.BPLIMIT(BPLIMIT*8)) U_FLOGIC (.clk, .rst, .txen, .bp_enb, .txen_fail);
    
    assign txen_safe = txen && (!txen_fail);

endmodule: fsafe
