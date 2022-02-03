`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/16/2021 11:12:54 AM
// Design Name: 
// Module Name: WF_TL_SCTB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module WF_TL_SCTB #(parameter BAUD_RATE=9600, BIT_RATE=50000, MAC_ADDR = 8'h42)
(
    input logic clk,  a_txd, dp_n, [6:0] segs_n, [7:0] an_n, [15:0] LED, [4:1] TRANSCEIVER,
    output logic rst, BTNU, BTND, BTNR, BTNL, a_rxd, [15:0] SW

);

    localparam CLOCK_PD = 10;
    localparam BITPD_NS_MX = 1_000_000_000 / BIT_RATE;  // bit period in ns
    localparam BITPD_NS_UART = 1_000_000_000 / BAUD_RATE;
    
    int errcount = 0;
    logic [9:0] expanded_data;
    
    task reset_duv;
        rst = 1;
        @(posedge clk) #1;
        rst = 0;
    endtask: reset_duv
    
    task report_errors;
        if (errcount == 0) $display("Testbench PASSED");
        else $display("Testbench FAILED with %d errors", errcount);
    endtask: report_errors
    
    
    initial begin
        $timeformat(-9, 0, "ns", 6);
        reset_duv;
        
        a_rxd = 1;
        #(BITPD_NS_UART*5);
        
        //Generate RealTerm UART Byte
        xmit_uart_byte(8'h44);
        #(BITPD_NS_UART*2);
        xmit_uart_byte(8'h19);
        xmit_uart_byte(8'he1);
        xmit_uart_byte(8'h2f);
        xmit_uart_byte(8'h4B);
        xmit_uart_byte(8'h04);
        
        #(BITPD_NS_UART*5);
        xmit_uart_byte(8'h66);
        
        report_errors;
        $stop;  // suspend simulation (use $finish to exit)
    end
    

    
endmodule
