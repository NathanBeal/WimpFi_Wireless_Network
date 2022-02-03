`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : FSM_UART_XMIT
// Project       : Lab 2 - UART Transmitter
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : Feb 2021
//-----------------------------------------------------------------------------
// Description   : FSM for UART transmitter. Three states used to transmit data 
//				 : at a specified baud rate.
//-----------------------------------------------------------------------------

module FSM_UART_XMIT
(
    input logic clk, rst, valid, br_en, [4:0] bit_counter,
    output logic [3:0] shreg_ctrl,
    output logic [1:0] count_ctrl,
    output logic br_st, rdy
);

  typedef enum logic [1:0]
  {
    RESET=2'b00, WTVALID=2'b01, TXBIT=2'b10
  } states_t;

  states_t state, next;

  always_ff @(posedge clk)
    if(rst) state <= RESET;
    else state <= next;

  always_comb
    begin
      //DEFAULT VALS
      next = RESET;
      count_ctrl = {1'b0, 1'b0}; //[rst, enable]
      shreg_ctrl = {1'b0, 1'b0, 1'b0, 1'b0}; //{rst, sh_idle, shen, lden}
      br_st = 1'b0;
      rdy = 1'b0;

      unique case (state)
        RESET:
        begin
            next = WTVALID;
            count_ctrl = {1'b1, 1'b0}; //[rst, enable]
        end

        WTVALID:
        begin
            rdy = 1'b1;
            if(valid == 1'b1 && br_en)
            begin
                br_st = 1'b1;
                next = TXBIT;
                shreg_ctrl = {1'b0, 1'b0, 1'b0, 1'b1}; //{rst, sh_idle, shen, lden}
            end
            else
            begin
                br_st = 1'b0;
                shreg_ctrl = {1'b0, 1'b1, 1'b0, 1'b0}; //{rst, sh_idle, shen, lden}
                next = WTVALID;
            end
        end

        TXBIT:
        begin
            rdy = 1'b0;
            next = TXBIT;
            if(br_en)
            begin
                if(bit_counter == 4'd9 && valid)
                begin 
                    rdy = 1'b1;
                    count_ctrl = {1'b1, 1'b0}; //[rst, enable]
                    shreg_ctrl = {1'b0, 1'b0, 1'b0, 1'b1}; //{rst, sh_idle, shen, lden}
                 end
                 else if(bit_counter == 4'd9 && !valid && br_en)
                 begin
                     next = WTVALID;
                     rdy = 1'b1;
                     count_ctrl = {1'b1, 1'b0}; //[rst, enable]
                     shreg_ctrl = {1'b0, 1'b1, 1'b0, 1'b0}; //{rst, sh_idle, shen, lden}
                 end
                 else
                 begin
                    count_ctrl = {1'b0, 1'b1}; //[rst, enable]
                    shreg_ctrl = {1'b0, 1'b0, 1'b1, 1'b0}; //{rst, sh_idle, shen, lden}
                 end
            end
            else next = TXBIT;
        end
      endcase
    end
endmodule
