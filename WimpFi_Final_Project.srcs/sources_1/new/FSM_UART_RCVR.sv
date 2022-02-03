`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : control_fsm
// Project       : Lab 4 - Asynchronous Serial Receiver
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : March 2021
//-----------------------------------------------------------------------------
// Description   : Drives the logic behind the receiving of bytes. Total of nine 
//                 states employed, one fro the transmission of each bit, two start
//                 bit detections states and a stop bit detection state. We use two start 
//                 states two filter out spurious starts.
//-----------------------------------------------------------------------------

module FSM_UART_RCVR
(
    input logic clk, rst, rdy, rxd, 
    input logic baud_rate_enb, baud_rate_enb_2x, baud_rate_enb_16x, 
    input logic [3:0] bit_in_byte, [3:0] sampling_counter, 
    output logic baud_st, oerr, ferr, gerr, valid,
    output logic [1:0] sample_counter_ctrl, [1:0] counter_ctrl, [3:0] shreg_ctrl, 
    output logic register_data, register_fifo
);

    typedef enum logic [2:0]
    {
        RESET=3'b000, IDLE=3'b001, START_BIT=3'b010, 
        DATA=3'b011, STOP=3'b100
    } states_t;
    states_t state, next;
    
    logic rdy_asserted;
    logic valid_next, oerr_next, ferr_next, rdy_asserted_next;
    
    always_ff @(posedge clk)
      begin
        if(rst) state <= RESET;
        else
        begin
            state <= next;
            valid <= valid_next;
            oerr <= oerr_next;
            ferr <= ferr_next;
            rdy_asserted <= rdy_asserted_next;
        end
    end

    always_comb
    begin
      //DEFAULT VALUES
      next = RESET;
      baud_st = 1'b0;
      shreg_ctrl = {1'b0, 1'b0, 1'b0, 1'b0}; //{rst, shen, lden, s_in}
      counter_ctrl = {1'b0, 1'b0}; //{rst, enb}
      sample_counter_ctrl = {1'b0, 1'b0}; //{rst, enb}
      register_data = 1'b0;
      gerr = 1'b0;

      unique case (state)
        RESET:
        begin
          next = IDLE;
          shreg_ctrl = {1'b1, 1'b0, 1'b0, 1'b0};
          counter_ctrl = {1'b1, 1'b0};
          sample_counter_ctrl = {1'b1, 1'b0};
          
          valid_next = 1'b0;
          oerr_next = 1'b0;
          ferr_next = 1'b0;
          rdy_asserted_next = 1'b0;
          register_fifo = 1'b0; //Added for WimpFI
        end

        IDLE:
        begin
            next = IDLE;
            valid_next = 1'b1;
            oerr_next = 1'b0;
            ferr_next = ferr;
            rdy_asserted_next = rdy_asserted;
            register_fifo = 1'b0; //Added for WimpFI
            
            //Registers if rdy has been asserted in the idle state
            if(rdy) rdy_asserted_next = 1'b1;
            
            if(rxd == 0)
            begin
                next = START_BIT;
                valid_next = 1'b0;
                ferr_next = 1'b0;
                baud_st = 1'b1;
                
                if(!rdy_asserted)
                begin 
                    oerr_next = 1'b1;
                    gerr = 1'b1;
                end
                else oerr_next = 1'b0;
            end
            else oerr_next = oerr;
        end

        START_BIT: //Checks for start/spurious start
        begin
          valid_next = 1'b0;
          ferr_next = ferr;
          oerr_next = oerr;
          rdy_asserted_next = 1'b0;
          baud_st = 1'b0;
          register_fifo = 1'b0; //Added for WimpFI
          counter_ctrl = {1'b0, 1'b1};
          sample_counter_ctrl = {1'b0, 1'b1};
          next = START_BIT;
          
          //Sample Halfway Through Bit, if high, back to IDLE
          if(sampling_counter == 4'd7 && rxd)
          begin 
            sample_counter_ctrl = {1'b1, 1'b0};
            next = IDLE;
          end
     
          //Transition to DATA Receival State
          if(baud_rate_enb)
          begin
            next = DATA; //tertiary spurious start check
            ferr_next = 1'b0;
            counter_ctrl = {1'b1, 1'b0};
          end
          
          //Last Failsafe against spurious starts
          if(baud_rate_enb && bit_in_byte >= 3'd3)
          begin
            next = IDLE;
            counter_ctrl = {1'b1, 1'b0};
            sample_counter_ctrl = {1'b1, 1'b0};
          end
        end

        DATA:
        begin
            valid_next = 1'b0;
            ferr_next = 1'b0;
            oerr_next = oerr;
            rdy_asserted_next = 1'b0;
            register_fifo = 1'b0; //Added for WimpFI
            
            next = DATA;
            register_data = 1'b0;
            sample_counter_ctrl = {1'b0, 1'b1};
            counter_ctrl = {1'b0, 1'b1};
            
            if(baud_rate_enb && bit_in_byte == 4'd7)
            begin
                next = STOP;
                register_data = 1'b1;
            end
            
            //Halfway through the bit
            if(sampling_counter == 4'd7 && baud_rate_enb_16x) shreg_ctrl = {1'b0, 1'b1, 1'b0, rxd}; //{rst, shen, lden, s_in}
        end

        STOP:
        begin
        valid_next = 1'b0;
        ferr_next = ferr;
        oerr_next = oerr;
        rdy_asserted_next = 1'b0;
        sample_counter_ctrl = {1'b0, 1'b1};
        register_fifo = 1'b0; //Added for WimpFI
        
        if(sampling_counter == 4'd7 && !rxd)
        begin
            ferr_next = 1'b1;
            gerr = 1'b1;
        end
        
        if(baud_rate_enb)
        begin
            next = IDLE;
            sample_counter_ctrl = {1'b1, 1'b0};
            shreg_ctrl = {1'b1, 1'b0, 1'b0, 1'b0}; //{rst, shen, lden, s_in}
            counter_ctrl = {1'b1, 1'b0};
            
            if(!ferr)
            begin 
                valid_next = 1'b1;
                register_fifo = 1'b1; //Added for WimpFI
            end
        end
        else next = STOP;//Cycles back to stop
        end
      endcase
    end
endmodule
