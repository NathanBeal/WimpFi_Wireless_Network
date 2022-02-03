`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2021 02:14:23 PM
// Design Name: 
// Module Name: BH_SCTB
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


module BH_SCTB
(
    input logic clk,
    output logic rst);

     task reset_duv;
        rst = 1;
        @(posedge clk) #1;
        rst = 0;
    endtask: reset_duv
   

initial begin
        $timeformat(-9, 0, "ns", 6);
        reset_duv;

        $stop;  // suspend simulation (use $finish to exit)
    end
endmodule
