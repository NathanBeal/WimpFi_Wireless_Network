`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : WimpFi_Transmitter
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : WimpFi_Transmitter module is a conglomorate top level module 
//				 : for nearly all modules used to transmit data to other receivers
//				 : and receive data from the terminal. There are three seperate fsms
//				 : that work in conjuction to achieve this.
//-----------------------------------------------------------------------------

module WimpFi_Transmitter #(parameter BAUD_RATE = 9600, BIT_RATE = 50000)
(
      input logic clk, rst, a_rxd, cardet, [7:0] src_addr, [7:0] packet_type,
      output logic txd, tx_en, [7:0] xerrcnt//, [15:0] LED
);
    //Signals
    logic register_fifo, data_sel, xvalid, xsnd, write_data, read_data, full, empty, error_xmit_adapter, ferr, oerr, txen_safe, txen_fail;
    logic [7:0] uart_rcvr_data, fifo_data, xdata, write_index, read_index, xmit_data, crc, crc_lu, last_crc_next, last_crc;
    logic [2:0] STATE, bit_in_byte, bit_eighths;

    //Receives Data from RealTerm
    uart_rcvr_TL #(.BAUD_RATE(BAUD_RATE)) U_UART_RCVR(.clk, .rst, .rdy(urdy), .rxd(a_rxd), .register_fifo, .valid(uvalid), .ferr, .oerr, .gerr(error_uart_rcvr), .data(uart_rcvr_data));

    //Interacts between MX Xmitter and UART Rcvr
    xmit_adapter U_XMIT_ADAPTER(.clk, .rst, .cardet, .tx_en, .txen_fail, .mx_br_en, .mx_br_en_8x, .bit_in_byte,  .register_fifo, .xrdy, .uvalid, .udata(uart_rcvr_data), .src_addr, .packet_type, .crc,
                                .write_data, .read_data, .urdy, .xvalid, .xsnd, .error(error_xmit_adapter), .write_index, .read_index, .fifo_data, .data_sel, .STATE, .bit_eighths);
    
    //Block Ram -> Stores and retrieves data from an array
    mem2p_sw_sr #(.W(8), .D(255)) U_BRAM(.clk, .we1(write_data), .addr1(write_index), .din1(fifo_data), .addr2(read_index), .dout2(xdata));

    //Transmits Data from Buffer Manchester encoding
    assign xmit_data = data_sel ? crc_lu : xdata;
    mx_xmit_TL #(.BIT_RATE(BIT_RATE)) U_MX_XMIT(.clk, .rst, .packet_type, .read_index, .data(xmit_data), .valid(xvalid || data_sel), .br_en(mx_br_en), .br_en_8x(mx_br_en_8x), .data_transmitting, .rdy(xrdy), .txd, .tx_en, .bit_in_byte);
    
    //CRC
    crc_lookup U_CRC_LU(.clk, .rst(rst || !tx_en), .clr(1'b0), .enb(xrdy && data_transmitting), .data(xmit_data), .crc(crc_lu));

    //Error Counter
    counter #(.W(8)) U_ERROR_COUNT (.clk, .rst, .enb(error_xmit_adapter || error_uart_rcvr), .q(xerrcnt));
    
    //Fail Safe counter
    fsafe U_FSAFE(.clk, .rst, .txen(tx_en), .txen_safe, .txen_fail);
    
    //Status LEDS
    assign LED = {cardet, txen_fail, 1'd0, STATE, 2'd0, last_crc};//transmit, TERA data, uvl, tx_en
    
    //Purely for debugging purposes
    always_ff @(posedge clk)
    begin
      if(rst) last_crc = 8'd0;
      else if(data_sel) last_crc = crc_lu;
      else last_crc_next = last_crc;
  end

endmodule
