`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : sevenseg_ctl: Seven-segment controller with active low outputs
// Project       : RTL Hardware Design and Verification using SystemVerilog
//-----------------------------------------------------------------------------
// Author             : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Last Updated       : May 3rd, 2021
//-----------------------------------------------------------------------------

module FSM_MX_XMIT #(parameter IDLE_BITS=2)
(
  input logic clk, rst, valid, br_en,
  input logic [2:0] bit_in_byte,
  input logic [3:0] idling_bit_counter,
  output logic [3:0] shreg_ctrl,
  output logic [1:0] bit_count_ctrl, idle_count_ctrl,
  output logic br_st, rdy, tx_en
);

  typedef enum logic [1:0]
  {
    RESET=2'b00, WTVALID=2'b01, TXBIT=2'b10
  } states_t;
  states_t state, next;

  always_ff @(posedge clk)
    begin
      if(rst) state <= RESET;
      else state <= next;
    end

  always_comb
    begin
      //DEFAULT VALS
      next = RESET;
      shreg_ctrl = {1'b0, 1'b0, 1'b0, 1'b0}; //rst, shift_load, shift_idle, shift_enable
      bit_count_ctrl = {1'b0, 1'b0}; //rst, en
      idle_count_ctrl = {1'b0, 1'b0}; //rst, en
      br_st = 1'b0;
      tx_en = 1'b0;

      unique case (state)
        RESET:
        begin
            next = WTVALID;
            rdy = 1'b0;

            //Ctrl Signal Packages
            shreg_ctrl = {1'b1, 1'b0, 1'b0, 1'b0}; //rst, shift_load, shift_idle, shift_enable
            bit_count_ctrl = {1'b1, 1'b0}; //rst, en
            idle_count_ctrl = {1'b1, 1'b0}; //rst, en
        end

        WTVALID:
        begin
            next = WTVALID;
            shreg_ctrl = {1'b0, 1'b0, 1'b1, 1'b0}; //rst, shift_load, shift_idle, shift_enable
            bit_count_ctrl = {1'b1, 1'b0}; //rst, en

            //Sets RDY high if idle_counting is done and pauses the count
            if((IDLE_BITS) <= idling_bit_counter)
            begin
                rdy = 1'b1;
                idle_count_ctrl = {1'b0, 1'b0};//rst, en
            end
            else
            begin
                rdy = 1'b0;
                idle_count_ctrl = {1'b0, 1'b1};//rst, en
            end

            //Minimum of two high idle cycles before transmission
            if((IDLE_BITS == idling_bit_counter) && valid && br_en)
            begin
                next = TXBIT;

                shreg_ctrl = {1'b0, 1'b1, 1'b0, 1'b0}; //Loads Shift reg with txd data**
                bit_count_ctrl = {1'b1, 1'b0}; //rst, en
                idle_count_ctrl = {1'b0, 1'b0};//rst, en
            end
        end

        TXBIT:
        begin
            next = TXBIT;

            //Ctrl Signal Packages
            idle_count_ctrl = {1'b1, 1'b0};//{rst, en} - IDLE bit counter
            bit_count_ctrl = {1'b0, 1'b1}; //{rst, en} - Manchester bit counter

            //Status Signals
            rdy = 1'b0;
            tx_en = 1'b1;

            if(bit_in_byte == 3'd7 && !valid && br_en)
            begin
                rdy = 1'b1;
                shreg_ctrl = {1'b1, 1'b0, 1'b0, 1'b0};
                next = WTVALID;
            end
            else if(bit_in_byte == 3'd7 && valid && br_en)//Transmits another piece of data
            begin
                rdy = 1'b1;
                shreg_ctrl = {1'b0, 1'b1, 1'b0, 1'b0}; //Loads Shift reg with txd data**
            end
            else shreg_ctrl = {1'b0, 1'b0, 1'b0, 1'b1};
        end
      endcase
    end

endmodule
