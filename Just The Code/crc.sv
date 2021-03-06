`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Title         : crc - 8-Bit Dallas/Maxim CRC calculator
// Project       : RTL Hardware Design and Verification using SystemVerilog
//-----------------------------------------------------------------------------
// Author        : John Nestor
// Created       : Mar 2006
// Last modified : April 2021
//-----------------------------------------------------------------------------
// Description : Peforms an 8-bit CRC using the polynomial
//    x^8 + x^5 + x^4 + 1
// Source: Dallas/Maxim 1-Wire bus interface
//-----------------------------------------------------------------------------

module crc(input logic clk, rst, enb, d,
	   output logic [7:0] crc);

   logic x0;

   // note bit order reversed from usual to match polynomial coeffecients
   logic [1:8] qx;

   assign 	x0 = qx[8] ^ d;

   //note reversal of bit order crc is ordered [7:0] as usual
   assign crc = qx;

   always_ff @(posedge clk)
     begin
	if (rst) qx <= 8'd0;
	else if (enb)
          begin
             qx[8] <= qx[7];
             qx[7] <= qx[6];
             qx[6] <= qx[5] ^ x0;
             qx[5] <= qx[4] ^ x0;
             qx[4] <= qx[3];
             qx[3] <= qx[2];
             qx[2] <= qx[1];
             qx[1] <= x0;
          end
     end

endmodule
