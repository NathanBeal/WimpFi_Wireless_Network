`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : sevenseg_ctl: Seven-segment controller with active low outputs
// Project       : RTL Hardware Design and Verification using SystemVerilog
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : Feb 2021
//-----------------------------------------------------------------------------
// Description   : Seven-segment controller with clock enable.
// Segments are ordered as follows: segs_n[6]=g, segs_n[0]=a
//-----------------------------------------------------------------------------

module sevenseg_ctl#(parameter BAUD_RATE = 9600)
(
    input logic clk, rst, [2:0] state, [7:0] display_data,
    output logic dp_n, 
    output logic [6:0] segs_n, 
    output logic [7:0] an_n
);
    
    //Signals
    logic br_en;
    logic [2:0] sel;
    logic [7:0] y, inv, d7, d6, d5, d4;
    
    always_comb
    begin
        //Default
        d7 = {8'b10111111};
        d6 = {8'b10111111};
        d5 = {8'b10111111};
        d4 = {8'b10111111};
        
        
        if(state == 3'b101)//DEFAULT STATE
        begin
            d7 = {3'd0, 5'd10};//A
            d6 = {3'd0, 5'd13};//d
            d5 = {3'd0, 5'd20};//r
            d4 = {3'd0, 5'd20};//r
        end
        else if(state == 3'b100)//DOWN STATE -> Should be alternating between MAC ADDR
        begin
            d7 = {3'd0, 5'd10};//A
            d6 = {3'd0, 5'd13};//d
            d5 = {3'd0, 5'd20};//r
            d4 = {3'd0, 5'd20};//r
        end
        else if(state == 3'b010)//Left = tErr
        begin
            d7 = {3'd0, 5'd19};//t
            d6 = {3'd0, 5'd14};//E
            d5 = {3'd0, 5'd20};//r
            d4 = {3'd0, 5'd20};//r
        end
        else if(state == 3'b011)//Right = rErr
        begin
            d7 = {3'd0, 5'd20};//r
            d6 = {3'd0, 5'd14};//E
            d5 = {3'd0, 5'd20};//r
            d4 = {3'd0, 5'd20};//r
        end
        else if(state == 3'b001)//Top = Toggle
        begin
            d7 = {3'd0, 5'd13};//d
            d6 = {3'd0, 5'd14};//E
            d5 = {3'd0, 5'd21};//S
            d4 = {3'd0, 5'd22};//T
        end
    end
    
    
    rate_enb #(.RATE_HZ(BAUD_RATE)) U_RATE1(.clk, .rst, .clr(1'b0), .enb_out(br_en));
    counter #(.W(3)) U_COUNT1(.clk, .rst, .enb(br_en), .q(sel));
    mux8_seven_Seg U_MUX1(.d7, .d6, .d5, .d4, .d3({3'd0, 5'd16}), .d2({3'd0, 5'd17}), .d1({4'd0, display_data[7:4]}), .d0({4'd0, display_data[3:0]}), .sel, .y);

    dec_3_8 U_DEC1(.a(sel), .y(inv));
    sevenseg_ext U_SEV_SEG_EXT(.d(y), .segs_n, .dp_n);
    assign an_n = ~inv; //Invert the anode seelct signal to provide an active low signal.

endmodule
