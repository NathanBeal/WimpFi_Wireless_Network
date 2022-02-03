`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2021 07:44:48 PM
// Design Name: 
// Module Name: WF_RCVR_SCTB
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


module WF_RCVR_SCTB #(parameter BAUD_RATE=9600, BIT_RATE=50000, MAC_ADDR = 8'h42, BROADCAST_ADDR = 8'h2A, EOF_BITS = 2)
(
    input logic clk, a_txd, cardet, [7:0] rerrcnt,
    output logic rst, rxd
);
    
    parameter CLOCK_PD = 10;

    localparam BITPD_NS_MX = 1_000_000_000 / BIT_RATE;  // bit period in ns
    localparam BITPD_NS_UART = 1_000_000_000 / BAUD_RATE;
    
    int errcount = 0;
    int pream_txd = 0;
    int sfd_txd = 0;
    int eof_txd = 0;
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
    endtask

    
    
    task reset_duv;
        rst = 1;
        @(posedge clk) #1;
        rst = 0;
        rxd = 1;
    endtask: reset_duv
    
    task report_errors;
        if (errcount == 0) $display("Testbench PASSED");
        else $display("Testbench FAILED with %d errors", errcount);
    endtask: report_errors
    
    task generate_preamble_pattern;
        logic [15:0] n = 16'b1010101010101010;
        pream_txd = 1;
        for (int i = 15; i >= 0; i--)
        begin
            if(n[i] == 1)
              begin
                rxd = 1;
                #(BITPD_NS_MX/2);
                rxd = 0;
                #(BITPD_NS_MX/2);
              end
            else
              begin
                rxd = 0;
                #(BITPD_NS_MX/2);
                rxd = 1;
                #(BITPD_NS_MX/2);
              end
        end
        pream_txd = 0;

      endtask: generate_preamble_pattern

      task generate_sfd_pattern;
        logic [7:0] n = 8'b00001011;
        sfd_txd = 1;
        for (int i = 7; i >= 0; i--)
        begin
            if(n[i] == 1)
              begin
                rxd = 1;
                #(BITPD_NS_MX/2);
                rxd = 0;
                #(BITPD_NS_MX/2);
              end
            else
              begin
                rxd = 0;
                #(BITPD_NS_MX/2);
                rxd = 1;
                #(BITPD_NS_MX/2);
              end
        end
        sfd_txd = 0;
      endtask: generate_sfd_pattern
      
    
    task xmit_mx_byte(logic [7:0] n, is_data);
        if(is_data) send_byte(n);
        for (int i = 0; i <= 7; i++)
        begin
            if(n[i] == 1)
              begin
                rxd = 1;
                #(BITPD_NS_MX/2);
                rxd = 0;
                #(BITPD_NS_MX/2);
              end
            else
              begin
                rxd = 0;
                #(BITPD_NS_MX/2);
                rxd = 1;
                #(BITPD_NS_MX/2);
              end
        end
      endtask: xmit_mx_byte
      
      task generate_eof_pattern;
        eof_txd = 1;
        for(int i = 0; i <= EOF_BITS-1; i++)
        begin
            rxd = 1;
            #(BITPD_NS_MX);
        end
        eof_txd = 0;
      endtask: generate_eof_pattern
      
      task send_type_zero([7:0] dest_addr, [7:0] src_addr, frame_length);
        byte random_number = 8'd0;
      
        generate_preamble_pattern;
        generate_sfd_pattern;
        xmit_mx_byte(dest_addr,1);
        xmit_mx_byte(src_addr,1);
        xmit_mx_byte(8'h30,1);        
        for (int i = 0; i < frame_length; i++)
        begin
             random_number = {$random} % 255;
             
             if(random_number < 0) random_number = random_number * -1;
             $display("Rand Num: %d", random_number);
             xmit_mx_byte(random_number,1);
        end
        generate_eof_pattern;
      endtask: send_type_zero
      
      task send_type_one_good_crc([7:0] dest_addr, [7:0] src_addr, frame_length);
        byte random_number = 8'd0;
        $display("TYPE 1: TRANSMITTING, GOOD CRC");
        generate_preamble_pattern;
        generate_sfd_pattern;
        xmit_mx_byte(dest_addr, 1);
        xmit_mx_byte(src_addr, 1);
        xmit_mx_byte(8'h31,1);        
        for (int i = 0; i < frame_length; i++)
        begin
             random_number = {$random} % 255;
             
             if(random_number < 0) random_number = random_number * -1;
             $display("Rand Num: %d", random_number);
             xmit_mx_byte(random_number, 1);
        end
        //xmit_crc_byte;
        xmit_mx_byte(crc_bit, 0);
        generate_eof_pattern;
      endtask: send_type_one_good_crc
      
      task send_type_one_bad_crc([7:0] dest_addr, [7:0] src_addr, frame_length);
        byte random_number = 8'd0;
        $display("TYPE 1: TRANSMITTING, BAD CRC");
        generate_preamble_pattern;
        generate_sfd_pattern;
        xmit_mx_byte(dest_addr, 1);
        xmit_mx_byte(src_addr, 1);
        xmit_mx_byte(8'h31,1);        
        for (int i = 0; i < frame_length; i++)
        begin
             random_number = {$random} % 255;
             
             if(random_number < 0) random_number = random_number * -1;
             $display("Rand Num: %d", random_number);
             xmit_mx_byte(random_number, 1);
        end
        //xmit_crc_byte;
        xmit_mx_byte( (~crc_bit), 0);
        generate_eof_pattern;
      endtask: send_type_one_bad_crc
    
    
    initial begin
        $timeformat(-9, 0, "ns", 6);
        reset_duv;
        
        #(BITPD_NS_UART*5);
        
        /*
        //Generate Transmitted Byte
        send_type_zero(MAC_ADDR, 8'h44, 3);
        #(BITPD_NS_UART*25);
        send_type_zero(MAC_ADDR, 8'h44, 2);
        */
         
        //Multi-overlapping Byte transmission
        //send_type_zero(MAC_ADDR, 8'h44, 3);
        
        #(BITPD_NS_UART*4);
        send_type_one_good_crc(BROADCAST_ADDR, 8'h44, 4);
        
        crc_saved = crc_bit;
        $display("Sending CRC Code: %x", crc_saved);
        send_byte(crc_saved);
        if (crc_bit==0) $display("CRC recevived correctly: %x", crc_saved);
        else $display("CRC recevived incorrectly: %x", crc_saved);
        d = 0;
        
        
        #(BITPD_NS_UART*20);
        send_type_one_bad_crc(BROADCAST_ADDR, 8'h44, 4);
        
        crc_saved = crc_bit;
        $display("Sending CRC Code: %x", crc_saved);
        
        #(BITPD_NS_UART*20);
        send_type_one_good_crc(BROADCAST_ADDR, 8'h44, 4);
        
        crc_saved = crc_bit;
        $display("Sending CRC Code: %x", crc_saved);
        /*
        send_type_zero(MAC_ADDR, 8'h44, 2);
        #(BITPD_NS_UART*1);
        send_type_zero(MAC_ADDR, 8'h44, 6);
        */
        
        /*
        #(BITPD_NS_UART*2);
        //Generate Transmitted Byte
        generate_preamble_pattern;
        generate_sfd_pattern;
        xmit_mx_byte(MAC_ADDR);
        xmit_mx_byte(8'hFE);
        generate_eof_pattern;
        
        /
        #(BITPD_NS_UART*2);
        generate_preamble_pattern;
        generate_sfd_pattern;
        xmit_mx_byte(8'h40);
        xmit_mx_byte(8'h22);
        generate_eof_pattern;
        */
        
        
        
        report_errors;
        $stop;  // suspend simulation (use $finish to exit)
    end
    
endmodule
