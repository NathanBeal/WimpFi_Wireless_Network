`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : WimpFi_Network_Interface
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : The module is a direct interface between the WimpFi transmitter half
//               : and the WimpFi receiver half. Cardet is or'd so it canbe asserted high
//               : to test backoff
//////////////////////////////////////////////////////////////////////////////////


module WimpFi_Network_Interface #(parameter BAUD_RATE = 9600, BIT_RATE = 50000)
(
    input logic clk, rst, forced_cardet, a_rxd, rxd, ignore_broadcast, [7:0] src_addr, [7:0] packet_type,
    output logic txd, tx_en, a_txd, [7:0] xerrcnt, [7:0] rerrcnt, [15:0] LED
);
    //Signals
    logic rcvr_cardet;
    
    //Transmitter & Receiver
    WimpFi_Transmitter #(.BAUD_RATE(BAUD_RATE), .BIT_RATE(BIT_RATE)) WF_XMIT(.clk, .rst, .src_addr, .packet_type, .a_rxd, .cardet(rcvr_cardet || forced_cardet), .txd, .tx_en, .xerrcnt);//, .LED);
    WimpFi_Receiver    #(.BAUD_RATE(BAUD_RATE), .BIT_RATE(BIT_RATE)) WF_RCVR(.clk, .rst, .src_addr, .rxd, .cardet(rcvr_cardet), .ignore_broadcast, .a_txd, .rerrcnt, .LED);
    
endmodule
