`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : uart_rcvr
// Project       : Lab 4 - Asynchronous Serial Receiver
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : March 2021
//-----------------------------------------------------------------------------
// Description   : Receiver drives multiple rate enables. One rate enable is used
//                 to progress the state machine at the paramterized baud rate and
//                 the other is used to sample the signal at 16x speed of the normal
//                 baud rate. Control_fsm handles state transitions and a counter is
//                 employed to indicate when it has counted to 7 (half way through a
//                 bits receiving period.
//-----------------------------------------------------------------------------
//Pulling br_en out

module uart_rcvr_TL #(parameter BAUD_RATE = 9600)
(
     input logic clk, rst, rdy, rxd,
     output logic register_fifo, valid, ferr, oerr, gerr,
     output logic [7:0] data
);

     logic baud_rate_enb, baud_rate_enb_2x, baud_rate_enb_16x, register_data;
     logic [7:0] registered_data;
     
     // BAUD RATE Enables
     rate_enb #(.RATE_HZ(BAUD_RATE))    U_RATEENABLE1 (.clk, .rst, .clr(baud_st), .enb_out(baud_rate_enb));
     rate_enb #(.RATE_HZ(BAUD_RATE*2))  U_RATEENABLE2 (.clk, .rst, .clr(baud_st), .enb_out(baud_rate_enb_2x));
     rate_enb #(.RATE_HZ(BAUD_RATE*16)) U_RATEENABLE3 (.clk, .rst, .clr(baud_st), .enb_out(baud_rate_enb_16x));
     
     //Counters
     logic [1:0] sample_counter_ctrl, counter_ctrl;//{rst, enable}
     logic [3:0] sampling_counter, shreg_ctrl, bit_in_byte;
     counter #(.W(4)) U_BIT_COUNT (.clk, .rst(rst || counter_ctrl[1]), .enb(counter_ctrl[0] && baud_rate_enb), .q(bit_in_byte));
     counter #(.W(4)) U_SAMPLER (.clk, .rst(rst || sample_counter_ctrl[1]), .enb(sample_counter_ctrl[0] && baud_rate_enb_16x), .q(sampling_counter));
     
     //Receiver FSM
     FSM_UART_RCVR U_FSM(.clk, .rst, .rdy, .rxd, .baud_rate_enb, .baud_rate_enb_2x, .baud_rate_enb_16x, .bit_in_byte, .sampling_counter, 
                         .baud_st, .valid, .ferr, .oerr, .gerr, .sample_counter_ctrl, .counter_ctrl, .shreg_ctrl, .register_data, .register_fifo);
    
     //Data Shreg
     sh_reg_uart_rcvr U_DATA_SHREG(.clk, .rst(rst || shreg_ctrl[3]), .shen(shreg_ctrl[2]), .lden(1'b0), .s_in(shreg_ctrl[0]), .d(8'h00), .q(registered_data));
  
     //Registered Data
     always_ff @(posedge clk)
     begin
        if(register_data) data <= registered_data;
     end

endmodule