`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : board_interfacing
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : Interfacing occurs between buttons and switches on FPGA board.
//				 : There is a built in fsm that dictates what message is displayed
//				 : on the seven-seg screen when different buttons are pressed.
//-----------------------------------------------------------------------------

module board_interfacing #(parameter BAUD_RATE = 9600)
(
    input logic clk, rst, BTNU, BTND, BTNL, BTNR, [15:0] SW, [7:0] xerrcnt, [7:0] rerrcnt,
    output logic dp_n, [6:0] segs_n, [7:0] an_n, [7:0] mac_addr, [7:0] dest_addr, [7:0] packet_type
);
    
    //Signals
    logic u_pulsed, d_pulsed, l_pulsed, r_pulsed, c_pulsed;
    logic [7:0] toggle_count, display_data;
    
    //Modules
    button_single_pulser U_UP   (.clk, .rst, .din(BTNU), .dout(u_pulsed));
    button_single_pulser U_DOWN (.clk, .rst, .din(BTND), .dout(d_pulsed));
    button_single_pulser U_LEFT (.clk, .rst, .din(BTNL), .dout(l_pulsed));
    button_single_pulser U_RIGHT(.clk, .rst, .din(BTNR), .dout(r_pulsed));
    counter #(.W(8)) U_ADDR_TOGGLE (.clk, .rst, .enb(d_pulsed), .q(toggle_count));
    sevenseg_ctl #(.BAUD_RATE(BAUD_RATE)) U_SEV_SEG_CTL(.clk, .rst, .state, .display_data, .segs_n, .dp_n, .an_n);
    
    typedef enum logic [2:0]
    {
        RESET=3'b000, UP_BUTTON = 3'b001, LEFT_BUTTON = 3'b010, RIGHT_BUTTON = 3'b011, DOWN_BUTTON = 3'b100, DEF = 3'b101
    } states_t;
    states_t state, next;
  
    always_ff @(posedge clk)
    begin
        if(rst) state <= RESET;
        else state <= next;
    end
  
  always_comb
    begin
      //DEFAULT VALUES
      next = RESET;
      mac_addr = 8'h42;
      display_data = 8'h42;

      unique case (state)
        RESET:
        begin
          next = DEF;
        end
        
        DEF:
        begin
            next = DEF;
            
            if(u_pulsed) next = UP_BUTTON;
            else if(d_pulsed) next = DOWN_BUTTON;
            else if(l_pulsed) next = LEFT_BUTTON;
            else if(r_pulsed) next = RIGHT_BUTTON;
        end
        
        UP_BUTTON:
        begin
            next = UP_BUTTON;
            
            if(d_pulsed) next = DOWN_BUTTON;
            else if(l_pulsed) next = LEFT_BUTTON;
            else if(r_pulsed) next = RIGHT_BUTTON;
            
            display_data = SW[15:8];
        end
        
        DOWN_BUTTON://Toggles between programmed mac address and switch mac address
        begin
            next = DOWN_BUTTON;
            
            if(u_pulsed) next = UP_BUTTON;
            else if(l_pulsed) next = LEFT_BUTTON;
            else if(r_pulsed) next = RIGHT_BUTTON;
            
            //MAC ADDRESS
            if(toggle_count % 2 == 0 || SW[7:0] < 8'h20 || SW[7:0] > 8'h7E) mac_addr = 8'h42; //Narrows possible MAC addresses to be whatever is a character
            else mac_addr = SW [7:0];
            
            display_data = mac_addr;
        end
        
        
        RIGHT_BUTTON://Displays Receievd error count
        begin
            next = RIGHT_BUTTON;
            
            if(d_pulsed) next = DOWN_BUTTON;
            else if(u_pulsed) next = UP_BUTTON;
            else if(l_pulsed) next = LEFT_BUTTON;
            
            display_data = rerrcnt;
        end
        
        LEFT_BUTTON:
        begin
            next = LEFT_BUTTON;
            
            if(d_pulsed) next = DOWN_BUTTON;
            else if(u_pulsed) next = UP_BUTTON;
            else if(r_pulsed) next = RIGHT_BUTTON;
            
            display_data = xerrcnt;
        end

      endcase
    end   
    
    assign packet_type = SW[14] ? 8'h31 : 8'h30;
    //assign LED = {1'b0, mac_addr};
    
endmodule
