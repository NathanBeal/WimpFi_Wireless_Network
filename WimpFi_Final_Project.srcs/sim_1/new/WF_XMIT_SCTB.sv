`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2021 10:34:15 AM
// Design Name: 
// Module Name: WF_XMIT_SCTB
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


module WF_XMIT_SCTB #(parameter BAUD_RATE=9600, MAC_ADDR = 8'h42, BIT_RATE=50000, IDLE_BITS = 2)
(
    input logic clk, txd, tx_en,
    input logic [7:0] xerrcnt,
    output logic rst, a_rxd, cardet, [7:0] packet_type
);
    
    parameter CLOCK_PD = 10;
    localparam BITPD_NS_MX = 1_000_000_000 / BIT_RATE;  // bit period in ns
    localparam BITPD_NS_UART = 1_000_000_000 / BAUD_RATE;
    
    int errcount = 0;
    logic [9:0] expanded_data;
    
    // CRC
    logic clk, rst, enb_bit, d, enb_lookup;
    logic [7:0] crc_bit, crc_saved, data_lookup, crc_lookup; // for saving the value
    crc DUV_BIT (.clk, .rst, .enb(enb_bit), .d(d), .crc(crc_bit));
    crc_lookup DUV_LU (.clk, .rst, .enb(enb_lookup), .data(data_lookup), .crc(crc_lookup));
    // apply data bit di to the CRC input for one clock cycle
    task send_bit(input logic di);
        begin
            enb_bit = 1;
            d = di;
            @(posedge clk) #1;
            enb_bit = 0;
        end
    endtask

    // apply the 8 data bits in bi to the CRC input over eight
    // clock cycles, starting with bi[0]
    task send_byte(input [7:0] bi);
        integer i;
        begin
            data_lookup = bi;
            for (i = 0; i <= 7; i = i+1) begin
                if (i == 0) enb_lookup = 1;
                send_bit(bi[i]);
                enb_lookup = 0;
            end
        end
        $display("CRC on val: h'%h", bi);
    endtask
    
    task reset_duv;
        rst = 1;
        @(posedge clk) #1;
        rst = 0;
        packet_type = 8'h30;
        a_rxd = 1;
    endtask: reset_duv
    
    task report_errors;
        if (errcount == 0) $display("Testbench PASSED");
        else $display("Testbench FAILED with %d errors", errcount);
    endtask: report_errors
    
    //CHECKS
    task check_recieved_data([7:0] data, input_d, ferr, exp_ferr, oerr, exp_oerr, valid, exp_valid);
        if(data == input_d)
        begin
             $display("   - Correct Value Received @t = %t: Expected Data = h'%h, Actual Data = h'%h",
                      $time, data, input_d);
        end
    endtask: check_recieved_data
    
    //Functionality Testing
    task xmit_uart_byte(logic [7:0] input_d, is_data);
      //CRC
      if(is_data) send_byte(input_d);
    
      //Generate data signal and check if output matches expected output
      expanded_data = {1'b1, input_d, 1'b0};
      
      //Generates rxd output signal, starts at 0 is LSB
      for (int i=0; i <= 9; i++)
      begin
        a_rxd = expanded_data[i];
        #(BITPD_NS_UART);
      end
      //check_recieved_data(data, input_d);

    endtask: xmit_uart_byte
    
    task xmit_uart_packet(logic  [7:0] dest, [7:0] src, [7:0] p_type, int frame_length);
        //Generate data signal and check if output matches expected output
        byte random_number = 8'd0;
        packet_type = p_type;
        $display("TYPE *: TRANSMITTING, GOOD CRC");
        xmit_uart_byte(dest, 1);
        xmit_uart_byte(src, 1);
        xmit_uart_byte(p_type, 1);
        
        for (int i = 0; i < frame_length; i++)
        begin
             random_number = {$random} % 255;
             
             if(random_number < 0) random_number = random_number * -1;
             //$display("Rand Num: %d", random_number);
             xmit_uart_byte(random_number, 1);
        end
        xmit_uart_byte(8'h04, 0);
        
    endtask: xmit_uart_packet
    
    initial begin
        $timeformat(-9, 0, "ns", 6);
        reset_duv;
        
        a_rxd = 1;
        #(BITPD_NS_UART*5);
        
        //Generate Realterm Inpuy
        xmit_uart_packet(8'h3F, MAC_ADDR, 8'h31, 4);
        
        crc_saved = crc_bit;
        $display("Sending CRC Code: %x", crc_saved);
        send_byte(crc_saved);
        if (crc_bit==0) $display("CRC recevived correctly: %x", crc_saved);
        else $display("CRC recevived incorrectly: %x", crc_saved);
        d = 0;
        
         #(BITPD_NS_UART*20);
        
        //Generate Realterm Inpuy
        xmit_uart_packet(8'h3F, MAC_ADDR, 8'h31, 7);
        crc_saved = crc_bit;
        $display("Sending CRC Code: %x", crc_saved);
        
        #(BITPD_NS_UART*12);
        //Generate Realterm Inpuy
        xmit_uart_packet(8'h3F, MAC_ADDR, 8'h31, 2);
        crc_saved = crc_bit;
        $display("Sending CRC Code: %x", crc_saved);
        
        
        
        //Generate RealTerm UART Byte
        /*
        
        #(BITPD_NS_UART*2);
        xmit_uart_byte(8'h19);
        cardet = 1'b0;
        xmit_uart_byte(8'he1);
        xmit_uart_byte(8'h2f);
        */
        //xmit_uart_byte(8'h4B);
        //xmit_uart_byte(8'h04);
        /*
        #(BITPD_NS_UART*40);
        cardet = 1'b0;
        //xmit_uart_byte(8'h66);
        */
        report_errors;
        $stop;  // suspend simulation (use $finish to exit)
    end
    
    
    
endmodule
