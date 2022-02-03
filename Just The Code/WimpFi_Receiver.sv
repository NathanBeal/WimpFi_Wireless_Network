`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : WimpFi_Receiver
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : WimpFi_Receiver module is a conglomorate top level module 
//				 : for nearly all modules used to receive data and send data to
//				 : the terminal. There are three seperate fsms that work in
//				 : conjuction to achieve this.
//-----------------------------------------------------------------------------

module WimpFi_Receiver #(parameter BAUD_RATE = 9600, BIT_RATE = 50000)
(
    input logic  clk, rst, rxd, ignore_broadcast, [7:0] src_addr, 
    output logic cardet, a_txd, [7:0] rerrcnt, [15:0] LED
);

    //Signals
    logic crc_register_fifo, register_fifo, crc_rst, mx_rcvr_valid, error_mx_rcvr, rrdy, rvalid, urdy, uart_xmit_valid, uart_xmit_rdy, full, empty, lockout, receiving_data, wr_en, rd_en;
    logic BAD_CRC, GOOD_CRC;
    logic [2:0] STATE;
    logic [2:0] bit_in_byte;
    logic [7:0] crc_data, fifo_in_data, mx_rcvr_data, uart_xmit_data, crc;
    
    //Recieves data from Antenna
    mx_rcvr_TL #(.BIT_RATE(BIT_RATE)) U_MX_RCVR(.clk, .rst, .rxd, .data(mx_rcvr_data), .baud_rate_enb(mx_br_en), .baud_rate_enb_8x(mx_br_en_8x), .cardet, .valid(mx_rcvr_valid), .error(error_mx_rcvr), .register_fifo, .receiving_data, .bit_in_byte);

    //CRC
    crc U_CHECKSUM(.clk, .rst(rst || !cardet || crc_rst), .enb(crc_enb), .d(rxd), .crc);

    //Interfaces between Receiver and UART Transmitter - Decided ro remove -> doesnt allow data without address to go through
    rcvr_adapter U_RCVR_ADAPTER(.clk, .rst, .ignore_broadcast, .error_mx_rcvr, .mx_br_en, .mx_br_en_8x, .bit_in_byte, .cardet, .uart_br_en, .crc, .uart_xmit_rdy, .register_fifo, .empty, .receiving_data, .mac_addr(src_addr), .mx_rcvr_data, 
                                .wr_en, .rd_en, .uart_valid, .crc_rst, .rst_fifo, .crc_register_fifo, .lockout, .STATE, .crc_data, .crc_enb, .rerrcnt, .GOOD_CRC, .BAD_CRC);//Needs UART Signals
   
    //FIFO
    assign fifo_in_data = crc_register_fifo ? crc_data : mx_rcvr_data;
    fifo_generator_0 U_FIFO (.clk, .srst(rst || rst_fifo), .din(fifo_in_data), .wr_en, .rd_en, .dout(uart_xmit_data), .full, .empty);
    
    //Interfaces between Receiver Adapter and PC Terminal
    uart_xmit_TL #(.BAUD_RATE(BAUD_RATE)) U_UART_XMIT(.clk, .rst, .data(uart_xmit_data), .valid(uart_valid && !empty), .br_en(uart_br_en), .rdy(uart_xmit_rdy), .txd(a_txd));
    
    //Debug LEDS
    assign LED = {cardet, rxd,  3'd0, STATE, mx_rcvr_data};//transmit, TERA data, uvl, tx_en

endmodule
