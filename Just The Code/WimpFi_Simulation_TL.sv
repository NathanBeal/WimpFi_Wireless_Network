`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : WimpFi_Simulation_TL
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : Top level sim for WimpFi device
//-----------------------------------------------------------------------------

module WimpFi_Simulation_TL();
  
  //Inits
  timeunit 1ns/100ps;
  parameter CLKPD = 10;
  parameter BIT_RATE = 50000;
  parameter BAUD_RATE = 9600;
  parameter IDLE_BITS = 2;
  parameter EOF_BITS = 2;
  parameter MAC_ADDR = 8'h42;
  
  //Signals
  logic clk, rst;
  
  clk_gen #(.CLKPD(CLKPD)) CG (.clk);
  
  //WimpFi Transmitter SCTB
  logic a_rxd, cardet, txd, tx_en; 
  logic [7:0] packet_type, xerrcnt;
  WimpFi_Transmitter #(.BAUD_RATE(BAUD_RATE), .BIT_RATE(BIT_RATE)) WF_XMIT(.clk, .rst, .src_addr(8'h42), .packet_type, .a_rxd, .cardet, .txd, .tx_en, .xerrcnt);
  WF_XMIT_SCTB  #(.BAUD_RATE(BAUD_RATE), .BIT_RATE(BIT_RATE)) U_SCTB (.clk, .rst, .cardet, .txd, .tx_en, .xerrcnt, .packet_type, .a_rxd);
  
  /*
  //WimpFi Receiver SCTB
  logic rxd, cardet, a_txd;
  logic [7:0] rerrcnt;
  WimpFi_Receiver #(.BAUD_RATE(BAUD_RATE), .BIT_RATE(BIT_RATE)) WF_RCVR(.clk, .rst, .rxd, .src_addr(MAC_ADDR), .cardet, .a_txd, .rerrcnt);
  WF_RCVR_SCTB #(.BAUD_RATE(BAUD_RATE), .BIT_RATE(BIT_RATE)) U_SCTB_2(.clk, .rst, .rxd, .cardet, .a_txd, .rerrcnt);
  */
  
  //Hardware TB
  /*
  logic BTNU, BTND, BTNC, BTNL, BTNR, dp_n;
  logic [6:0] segs_n;
  logic [7:0] xerrcnt, rerrcnt, mac_addr, packet_type, an_n;
  logic [15:0] SW, LED;
  assign BTNU = 1'b0; 
  assign BTND = 1'b0;
  assign BTNC = 1'b0;
  assign BTNL = 1'b0;
  assign BTNR = 1'b0;
  assign SW = 16'h44;
  BH_SCTB U_SCTB(.clk, .rst);
  board_interfacing #(.BAUD_RATE(BAUD_RATE)) U_BOARD(.clk, .rst, .BTNU, .BTND, .BTNC, .BTNL, .BTNR, .SW, .xerrcnt, .rerrcnt, .dp_n, 
                                                     .segs_n, .an_n, .mac_addr, .packet_type, .LED);*/
                                                     
   /*                                                 
  //Complete Design Test Bench
  logic BTNU, BTND, BTNC, BTNL, BTNR, dp_n, a_rxd, a_txd;
  logic [6:0] segs_n;
  logic [7:0] an_n; 
  logic [4:1] TRANSCEIVER; 
  logic [15:0] LED, SW;
  WimpFi_Hardware_TL U_DUV (.clk, .rst, .BTNU, .BTND, .BTNR, .BTNL, .a_rxd, .SW, .a_txd, .dp_n, .segs_n, .an_n, .LED, .TRANSCEIVER);
  WF_TL_SCTB U_TB (.clk, .a_txd, .dp_n, .segs_n, .an_n, .LED, .TRANSCEIVER, .rst, .BTNU, .BTND, .BTNR, .BTNL, .a_rxd, .SW);
  */
  
  //crc_bench U_CRC(.clk, .rst(1'b0));
endmodule
