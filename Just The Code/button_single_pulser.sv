`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : button_single_pulser
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : FSM used to singularly pulse each time a button is pressed. Once
//				 : a button is pressed it enters a "button pressed" state and only 
//				 : leaves when button is not pushed sending single pulse to change
//				 : what is displayed on seven-seg.
//-----------------------------------------------------------------------------

module button_single_pulser
(
    input logic clk, rst, din,
    output logic dout
);

  typedef enum logic [1:0]
  {
      RESET=2'b00, NOT_PUSHED=2'b01, PUSHED= 2'b10
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
      dout = 1'b0;

      unique case (state)
        RESET:
        begin
          next = NOT_PUSHED;
        end

        NOT_PUSHED: //Sends: Preamble, SFD, Dest Address, Source Address, Type of Byte
        begin
            if(din) next = PUSHED;
            else next = NOT_PUSHED;
        end

        PUSHED: //Read Data from UART
        begin
            if(din) next = PUSHED;
            else
            begin
                next = NOT_PUSHED;
                dout = 1'b1;
            end
        end
      endcase
    end   
endmodule