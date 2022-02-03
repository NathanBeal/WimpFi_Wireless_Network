`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : mx_xmit_TL
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : FSM interface between the UART receiver, MX Transmitter and the BRAM. 
//               : Controls valid rdy interfae between UART and manchester and loads data
//               : into BRAM.
//////////////////////////////////////////////////////////////////////////////////

module mx_xmit_TL #(parameter IDLE_BITS=2, BIT_RATE=50000)
(
    input logic rst, clk, valid, [7:0] data, [7:0] packet_type, [7:0] read_index,
    output logic br_en, br_en_8x, data_transmitting, rdy, txd, tx_en, [2:0] bit_in_byte
);
    //Signals
    logic br_st;
    logic [1:0] bit_count_ctrl, idle_count_ctrl;
    logic [3:0] idling_bit_counter, shreg_ctrl;
    logic [15:0] register_data, txd_16;

    //Baud Rate Enables
    logic br_en_2x;
    rate_enb #(.RATE_HZ(BIT_RATE))    U_BR (.clk, .rst, .clr(br_st), .enb_out(br_en));
    rate_enb #(.RATE_HZ(BIT_RATE*2))  U_BR_2X(.clk, .rst, .clr(br_st), .enb_out(br_en_2x));
    rate_enb #(.RATE_HZ(BIT_RATE*8))  U_BR_8X(.clk, .rst, .clr(br_st), .enb_out(br_en_8x)); //Used for sampling CRC data bit

    //Constructs 16-bit Manchester transmittable data from 8-bit data
    mx_data_constructor U_DATACONSRUCT(.clk, .data, .register_data);

    //Counter
    counter U_BIT_IN_BYTE_COUNTER(.clk, .rst({rst || bit_count_ctrl[1]}), .enb({br_en && bit_count_ctrl[0]}), .q(bit_in_byte));//bit-in-byte
    counter #(.W(4)) U_IDLE_COUNTER(.clk, .rst({rst || idle_count_ctrl[1]}), .enb({br_en && idle_count_ctrl[0]}), .q(idling_bit_counter));//idling counter

    //Shifts Data Out
    mx_xmit_shreg U_SHIFTREG(.clk, .rst(rst || shreg_ctrl[3]), .shen(shreg_ctrl[0] && br_en_2x), .lden(shreg_ctrl[2]), .s_in(1'b0), .shift_idle(shreg_ctrl[1]), .d(register_data), .q(txd_16));

    //Signals added for TB:
    FSM_MX_XMIT #(.IDLE_BITS(IDLE_BITS)) U_FSM(.clk, .rst, .valid, .br_en, .bit_in_byte, .idling_bit_counter, .shreg_ctrl, .bit_count_ctrl, .idle_count_ctrl, .br_st, .rdy, .tx_en);
    
    //CRC 
    always_comb
    begin
        if((packet_type == 8'h31) && read_index > 2) data_transmitting = 1'b1; //0-Pream, 1-pream, 2-sfd
        else data_transmitting = 1'b0;
    end
    
    assign txd = txd_16[0];

endmodule
