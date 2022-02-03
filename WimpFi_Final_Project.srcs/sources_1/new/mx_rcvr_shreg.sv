`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2021 01:31:53 PM
// Design Name: 
// Module Name: mx_rcvr_shreg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mx_rcvr_shreg #(parameter W=8) (
    input logic clk, rst, shen, lden, s_in,
    input logic [W-1:0]  d,
    output logic [W-1:0] q
    );

  always_ff @(posedge clk)
    if (rst) q <= '0;
    else if (lden) q <= d;
    else if (shen) q <= { s_in, q[W-1:1] };

endmodule: mx_rcvr_shreg