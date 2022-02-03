`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : sevenseg_ext: Seven-segment decoder with active low outputs
// Project       : RTL Hardware Design and Verification using SystemVerilog
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : Feb 2021
//-----------------------------------------------------------------------------
// Description   : Seven-segment decoder extended.
// Segments are ordered as follows: segs_n[6]=g, segs_n[0]=a
//-----------------------------------------------------------------------------
// Edited By     : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Date Edited   : March 2021
// Edition       : Increased bitwidth of d to 8 bits. This increased the decoding to five bits 
//                 and allowed us to add two additional characters, "h" and " ' ". Also forced
//                 sp_n value high such that it never comes on (not necessary for the lab). 
//-----------------------------------------------------------------------------
// Edited By     : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Date Edited   : May 2021
// Edition       : Added more characters to be displayed on the seven seg. Chars include
//               : "t", "r", "e"
//-----------------------------------------------------------------------------

module sevenseg_ext(
    input logic [7:0] d,
    output logic [6:0] segs_n,
    output logic dp_n
    );

    // c - 4'd0: segs_n = 7'b0111001;
    // 7 bit input: d[6] = blank, d[5] = decimal point, d[4] = dash, d[3:0] is 0-F
    always_comb
      if (d[7] == 1'b1) // Checking for the blank bit
        begin
          segs_n = 7'b1111111;
          dp_n = 1'b1;
        end


      else
        begin
        if(d[6] == 1'b1) // Checking for the decimal point bit
          begin
            dp_n = 1'b1;
          end
        if(d[5] == 1'b1) // Checking for the dash
          begin
            segs_n = 7'b0111111; //Inverse of the 0 segements
            dp_n = 1'b1;
          end
        else
          begin
            dp_n = 1'b1;
            case (d[4:0])     //  gfedcba
              5'd0: segs_n = 7'b1000000;
              5'd1: segs_n = 7'b1111001;
              5'd2: segs_n = 7'b0100100;
              5'd3: segs_n = 7'b0110000;
              5'd4: segs_n = 7'b0011001;
              5'd5: segs_n = 7'b0010010;
              5'd6: segs_n = 7'b0000010;
              5'd7: segs_n = 7'b1111000;
              5'd8: segs_n = 7'b0000000;
              5'd9: segs_n = 7'b0010000;
              5'd10: segs_n = 7'b0001000; // Letter A
              5'd11: segs_n = 7'b0000011; // Letter b
              5'd12: segs_n = 7'b1000110; // Letter C
              5'd13: segs_n = 7'b0100001; // Letter d
              5'd14: segs_n = 7'b0000110; // Letter E
              5'd15: segs_n = 7'b0001110; // Letter F
              5'd16: segs_n = 7'b0001011; // Letter H
              5'd17: segs_n = 7'b1111101; // Char '
              5'd18: segs_n = 7'b0001000; // Letter R
              5'd19: segs_n = 7'b0000111; // Letter t
              5'd20: segs_n = 7'b0101111; // Letter r
              5'd21: segs_n = 7'b0010010; // Letter S
              5'd22: segs_n = 7'b1111000; // Letter T
              default: segs_n = 7'b1111111;
            endcase
          end
        end

endmodule
