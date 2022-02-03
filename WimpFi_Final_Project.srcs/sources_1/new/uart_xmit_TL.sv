`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : uart_xmit
// Project       : Lab 2 - UART Transmitter
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : February 2021
//-----------------------------------------------------------------------------
// Description   : uart_xmit module instation from Lab 2. Interfaces and supports
//				 : communication between the datapath and fsm.  
//-----------------------------------------------------------------------------

module uart_xmit_TL  #(parameter BAUD_RATE = 9600)
(
    input logic clk, rst, valid, 
    input logic [7:0] data,
    output logic br_en, rdy, txd
);
    //Control Signals
    logic [3:0] shreg_ctrl; //{rst, sh_idle, shen, lden}
    logic [1:0] count_ctrl; //[ct_clr, ct_en]
    
    //Signals
    logic br_st;
    logic [9:0] txd_10, register_data;
    logic [4:0] bit_counter;
    
    assign register_data = {1'b1, data[7:0], 1'b0};

    rate_enb #(.RATE_HZ(BAUD_RATE)) U_BAUD_RATE(.clk, .rst, .clr(br_st), .enb_out(br_en));
    counter #(.W(5)) U_COUNT10(.clk, .rst(count_ctrl[1] || rst), .enb(count_ctrl[0] && br_en), .q(bit_counter));
    
    //Data Shreg
    sh_reg_uart_xmit #(.W(10)) U_SHREG(.clk, .rst(shreg_ctrl[3] || rst), .shen(shreg_ctrl[1] && br_en), .lden(shreg_ctrl[0]), .s_in(1'b1), .shift_idle(shreg_ctrl[2]), .d(register_data), .q(txd_10));

    //FSM
    FSM_UART_XMIT U_XMIT_FSM (.clk, .rst, .valid, .br_en, .bit_counter, .shreg_ctrl, .count_ctrl, .br_st, .rdy);

    assign txd = txd_10[0];

endmodule