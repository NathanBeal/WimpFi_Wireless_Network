`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : rate_enb
// Project       : RTL Hardware Design and Verification using SystemVerilog
//-----------------------------------------------------------------------------
// Author        : John Nestor  <nestorj@lafayette.edu>
// Created       : Jun 2020
//-----------------------------------------------------------------------------
// Description   : Parameterized clock enable generator-
// Description :
// This module generates a enable signal that is asserted for one clock
// cycle at a periodic rate specified by ENB_RATE.  Note that this circuit
// is NOT a clock divider; instead it enables connected logic to perform
// a repeated task at a specified rate while keeping all flip-flops
// connected to a common clock.  The CLKFREQ parameter specifies
// the frequency of the on-board clock; its default corresponds to
// to the on-board clock frequency of a Nexys4 FPGA board (100MHz).
// Note that rst is intended as a master reset signal.
//-----------------------------------------------------------------------------
// Edited By     : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Date Edited   : March 2021
// Edition       : Parameterized RATE_HZ/BAUD_RATE and CLKFREQ.
//-----------------------------------------------------------------------------

module rate_enb #(parameter RATE_HZ=9600, CLKFREQ = 100_000_000) (input logic clk, rst, clr, output logic enb_out);
    localparam DIVAMT = (CLKFREQ / RATE_HZ);
    localparam DIVBITS = $clog2(DIVAMT);   // enough bits to represent DIVAMT

    logic [DIVBITS-1:0] q;

    assign enb_out = (q == DIVAMT-1);

    always_ff @(posedge clk)
        if (rst || clr || enb_out) q <= '0;
        else                       q <= q + 1;

endmodule: rate_enb