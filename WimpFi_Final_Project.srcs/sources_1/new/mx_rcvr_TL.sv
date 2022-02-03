`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// Module Name   : mx_rcvr
// Project       : Lab 5 - Manchester Receiver
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : April 2021
//-----------------------------------------------------------------------------
// Description   : Manchester receivers implementation module. Interfaces between 
//				 : the fsm, correlators, reate enables, counters and shift registers. 
//-----------------------------------------------------------------------------

module mx_rcvr_TL #(parameter BIT_RATE = 50000, EOF_BITS = 2)
(
    input logic clk, rst, rxd,
    output logic baud_rate_enb, baud_rate_enb_8x, cardet, valid, error, register_fifo, receiving_data, [2:0] bit_in_byte, [7:0] data
);

        // I/O
        logic cor_rst, baud_rate_enb_16x, baud_st, register_data;
        logic [1:0] bit_counter, data_counter, eof_bit_counter; //{enb, rst}
        logic [3:0] data_sample, eof_bit_count, shreg_ctrl; //{reset, shift_enable, data_bit};
        logic [7:0] data_next;

        //Correlator Signals
        logic pre_enable, sfd_enable, data_enable, eof_enable, preamble_match, sfd_match, eof_match, data_1, data_0, l_out_pre, l_out_sfd, l_out_eof;
        logic [3:0] data_csum, eof_csum;
        logic [6:0] pre_csum, sfd_csum;

        //Baud Rates
        rate_enb #(.RATE_HZ(BIT_RATE))    U_BAUDRATE(.clk, .rst, .clr(baud_st), .enb_out(baud_rate_enb));
        rate_enb #(.RATE_HZ(BIT_RATE*8))  U_BAUDRATE_8X(.clk, .rst, .clr(baud_st), .enb_out(baud_rate_enb_8x));
        rate_enb #(.RATE_HZ(BIT_RATE*16)) U_BAUDRATE_16X(.clk, .rst, .clr(baud_st), .enb_out(baud_rate_enb_16x));

        //Counts which bit that has been received in a single byte transmission
        counter #(.W(3)) U_BIT_COUNT(.clk, .rst(rst || bit_counter[0]), .enb(baud_rate_enb && bit_counter[1]), .q(bit_in_byte));
        counter #(.W(4)) U_COUNT16(.clk, .rst(rst || data_counter[0]), .enb(baud_rate_enb_16x && data_counter[1]), .q(data_sample));
        counter #(.W(4)) U_COUNT16_EOF(.clk, .rst(rst || eof_bit_counter[0]), .enb(baud_rate_enb && eof_bit_counter[1]), .q(eof_bit_count));

        //Correlators
        correlator #(.HTHRESH(50), .LTHRESH(14)) U_COR_PREAMBLE(.clk, .rst(rst || cor_rst), .enb(pre_enable && baud_rate_enb_8x), .d_in(rxd), .csum(pre_csum), .h_out(preamble_match), .l_out(l_out_pre));
        correlator #(.PATTERN(64'h0f_0f_0f_0f_f0_0f_f0_f0), .HTHRESH(50), .LTHRESH(14)) U_COR_SFD(.clk, .rst(rst || cor_rst), .enb(sfd_enable && baud_rate_enb_8x), .d_in(rxd), .csum(sfd_csum), .h_out(sfd_match), .l_out(l_out_sfd));      
        correlator #(.LEN(8), .PATTERN(8'b11110000), .HTHRESH(6), .LTHRESH(2)) U_COR_DATA(.clk, .rst(rst || cor_rst), .enb(data_enable && baud_rate_enb_16x), .d_in(rxd), .csum(data_csum), .h_out(data_1), .l_out(data_0));
        correlator #(.LEN(8), .PATTERN(8'b11111111), .HTHRESH(7), .LTHRESH(1)) U_COR_EOF_TEST(.clk, .rst(rst || cor_rst), .enb(eof_enable && baud_rate_enb_8x), .d_in(rxd), .csum(eof_csum), .h_out(eof_match), .l_out(l_out_eof));

        //FSM
        FSM_MX_RCVR #(.EOF_BITS(EOF_BITS))
        U_RCVR_FSM (.clk, .rst, .rxd, .baud_rate_enb, .baud_rate_enb_8x, .baud_rate_enb_16x, .preamble_match, .sfd_match, .data_1, .data_0, .eof_match,
                    .bit_count_8(bit_in_byte), .bit_count_16(data_sample), .eof_bit_count, .cardet, .valid, .error, .baud_st, .bit_counter, .data_counter, 
                    .eof_bit_counter, .register_fifo, .pre_enable, .sfd_enable, .data_enable, .eof_enable, .cor_rst, .register_data, .shreg_ctrl
                    );

        //Data Shreg
        mx_rcvr_shreg U_DATA_SHREG(.clk, .rst(shreg_ctrl[3] || rst), .shen(shreg_ctrl[1]), .lden(shreg_ctrl[2]), .s_in(shreg_ctrl[0]), .d(8'd0), .q(data_next));

        always_ff @(posedge clk)
        begin
            if(rst) data <= 8'h00;
            else if(register_data) data <= data_next;
            else data <= data;
        end
        
        assign receiving_data = (sfd_match && baud_rate_enb);
endmodule
