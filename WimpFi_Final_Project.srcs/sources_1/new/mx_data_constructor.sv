`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2021 10:41:29 AM
// Design Name: 
// Module Name: mx_data_constructor
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

module mx_data_constructor(
  input logic clk,
  input logic [7:0] data,
  output logic [15:0] register_data);

  always_ff @(posedge clk)
    begin
      register_data = 16'b1111111111111111;
      for(int i = 0; i <= 7; i++)
        begin
          if(data[i] == 1'b0)
            begin
              register_data[2*i] = 0;
              register_data[(2*i)+1] = 1;
            end
          if(data[i] == 1'b1)
            begin
              register_data[2*i] = 1;
              register_data[(2*i)+1] = 0;
            end
        end
    end

endmodule
