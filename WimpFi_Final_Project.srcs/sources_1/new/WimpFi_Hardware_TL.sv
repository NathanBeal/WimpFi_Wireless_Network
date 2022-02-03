`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : WimpFi_Hardware_TL
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : Total overarching top level module for WimpFi hardware. Top 
//				 : level interface between the constraints, the physical elements
//				 : on the FPGA board and the tranmission and reception of both
//				 : UART and manchester data.
//-----------------------------------------------------------------------------

module WimpFi_Hardware_TL #(parameter BAUD_RATE = 9600, BIT_RATE = 50000)
(
    input logic clk, rst, BTNU, BTND, BTNR, BTNL, rxd, a_rxd, [15:0] SW,
    output logic txd, cfgclk, cfgdat, a_txd, dp_n, [6:0] segs_n, [7:0] an_n, [15:0] LED
);

    //Signals
    logic [7:0] mac_addr, dest_addr, packet_type, xerrcnt, rerrcnt;
    logic tx_en;

    //Hardwarwe Interfacing
    board_interfacing U_BH (.clk, .rst, .xerrcnt, .rerrcnt, .SW, .BTNU, .BTND, .BTNR, .BTNL, .dp_n, .segs_n, .an_n, .mac_addr, .dest_addr, .packet_type);
    
    //Manchester Receiver & Transmitter
    WimpFi_Network_Interface U_WF_Interface(.clk, .rst, .forced_cardet(SW[15]), .ignore_broadcast(SW[13]), .src_addr(mac_addr), .packet_type, .a_rxd, .rxd, .txd, .tx_en, .a_txd, .xerrcnt, .rerrcnt, .LED);
    
    //Other Transceiver Signals
    assign cfgclk = ~tx_en;
    assign cfgdat = 1'b1;
    
endmodule
