`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2021 01:30:16 PM
// Design Name: 
// Module Name: MX_RCVR_FSM
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

module FSM_MX_RCVR #(parameter EOF_BITS = 2)(
    input logic clk, rst, rxd, baud_rate_enb, baud_rate_enb_8x, baud_rate_enb_16x,
    input logic preamble_match, sfd_match, data_1, data_0, eof_match,
    input logic [2:0] bit_count_8, [3:0] bit_count_16, [3:0] eof_bit_count,
    output logic cardet, valid, error, baud_st,
    output logic [1:0] bit_counter, [1:0] data_counter,[1:0] eof_bit_counter,
    output logic pre_enable, sfd_enable, data_enable, eof_enable, cor_rst, register_data, register_fifo,
    output logic [3:0] shreg_ctrl
    );

    typedef enum logic [2:0]
    {
      RESET=3'b000, PREAMBLE=3'b001, SFD=3'b010, DATA=3'b011, EOF=3'b111
    } states_t;
    states_t state, next;

    logic [3:0] middle_edge;
    logic cardet_next, valid_next, error_next;
    logic tempval;

    always_ff @(posedge clk)
      begin
        if(rst) state <= RESET;
        else
        begin
          state <= next;
          cardet <= cardet_next;
          valid <= valid_next;
          error <= error_next;
        end
      end

    always_comb
    begin
      //DEFAULT VALUES
      next = RESET;
      baud_st = 1'b0;

      pre_enable = 1'b0;
      sfd_enable = 1'b0;
      data_enable = 1'b0;
      eof_enable = 1'b0;
      eof_bit_counter = {1'b0, 1'b1};
      bit_counter = {1'b0, 1'b1}; //{enb, rst}
      data_counter = {1'b0, 1'b1}; //{enb, rst}
      shreg_ctrl = {1'b0, 1'b0, 1'b0, 1'b0};
      cor_rst = 1'b0;
      register_data = 1'b0;
      middle_edge = 4'b0;
      register_fifo = 1'b0;

      unique case (state)
        RESET:
        begin
          next = PREAMBLE;
          bit_counter = {1'b0, 1'b1};
          data_counter = {1'b0, 1'b1};
          shreg_ctrl = {1'b1, 1'b0, 1'b0, 1'b0};
          valid_next = 1'b0;
          cardet_next = 1'b0;
          error_next = 1'b0;
          baud_st = 1'b1;
          tempval = '0;
        end

        //Sits and has correlator search for preamble, once found,
        //transitions to SFD to look for SFD bits
        PREAMBLE:
        begin
          //Registers
          cardet_next = 1'b0;
          valid_next = 1'b0;
          error_next = 1'b0;

          //If an errors exists keep it
          if(error == 1'b1) error_next = 1'b1;

          baud_st = 1'b0; //Needs to be on to drive other components
          pre_enable = 1'b1;
          if(preamble_match == 1'b1)
          begin
            next = SFD;
            cardet_next = 1'b1;
            baud_st = 1'b1;
          end
          else next = PREAMBLE;
        end

        //Sits and has correlator search for sfd, once found,
        //transitions to DATA to read data sent in byte
        SFD:
        begin
          //Registers
          cardet_next = 1'b1;
          valid_next = 1'b0;
          error_next = 1'b0;


          baud_st = 1'b0;
          sfd_enable = 1'b1;
          bit_counter = {1'b1, 1'b0};
          data_counter = {1'b1, 1'b0};//count how many 16ths are off
          if(sfd_match == 1'b1 && baud_rate_enb)
          begin
            next = DATA;
            bit_counter = {1'b0, 1'b1};//{enb, rst}
            data_counter = {1'b0, 1'b1};//{enb, rst}
          end
          else next = SFD;
        end

        DATA:
        begin
          //Registers
          cardet_next = 1'b1;
          valid_next = 1'b0;
          error_next = 1'b0;
          valid_next = 1'b0;

          //EOF always being sought for in data, we have
          next = DATA;
          eof_enable = 1'b1;
          bit_counter = {1'b1, 1'b0}; //{enb, rst}
          data_counter = {1'b1, 1'b0}; //{enb, rst}

          //Data Sampling Constraints
          if(bit_count_16 >= 4 && bit_count_16 <= 11) data_enable = 1'b1;
          else if(bit_count_16 >= 12) data_enable = 1'b0;
          else data_enable = 1'b0;

          // Bits 0-7
          //if(bit_count_8 <= 7 && baud_rate_enb)
          if(bit_count_8 <= 7 && baud_rate_enb_16x && (bit_count_16 == 12))
          begin
            if(data_0) shreg_ctrl = {1'b0, 1'b0, 1'b1, 1'b0};
            else if(data_1) shreg_ctrl = {1'b0, 1'b0, 1'b1, 1'b1};
            else if(eof_match)// 'Broken Byte' - Not all 8 bits have been transmitted and there is an EOF in byte transmission
            begin
                next = EOF;
                bit_counter = {1'b0, 1'b1};
                error_next = 1'b1;
                cardet_next = 1'b0;
                cor_rst = 1'b1;
            end
            else //Unrealized error abort to preamble
            begin
                next = PREAMBLE;
                bit_counter = {1'b0, 1'b1};
                error_next = 1'b1;
                cardet_next = 1'b0;
                cor_rst = 1'b1;
            end
          end
          
          if(bit_count_8 == 7 && baud_rate_enb)
          begin 
              next = EOF; //above if-else block?
              register_data = 1'b1;
              valid_next = 1'b1;
          end
          if(baud_rate_enb && bit_count_16 >= 0) data_counter = {1'b0, 1'b1};
        end

        EOF:
        begin
          /*three cases
          1. last byte transmitted checking for correct EOF bits
          2. last byte not transmitted push value into shreg, make sure bit counter in next state is 1
          3. last byte trnamistted and no EOF fram -> error
          */
          //Registers
          //Carries over errors/cardet disruption from DATA state
          if(cardet == 1'b0) cardet_next = 1'b0;
          else cardet_next = 1'b1;
          if(error == 1'b1) error_next = 1'b1;
          else error_next = 1'b0;

          valid_next = 1'b0;

          //register_data = 1'b1;
          eof_enable = 1'b1;
          bit_counter = {1'b1, 1'b0}; //{enb, rst}
          data_counter = {1'b1, 1'b0}; //{enb, rst}
          eof_bit_counter = {1'b1, 1'b0};

          //Data Sampling Constraints
          if(bit_count_16 >= 4 && bit_count_16 <= 11) data_enable = 1'b1;
          else if(bit_count_16 >= 12) data_enable = 1'b0;
          else data_enable = 1'b0;

          if(!eof_match && baud_rate_enb && (data_0 || data_1))
          begin
            next = DATA;
            if(data_0) shreg_ctrl = {1'b0, 1'b0, 1'b1, 1'b0};
            else if(data_1) shreg_ctrl = {1'b0, 1'b0, 1'b1, 1'b1};
            
            register_fifo = 1'b1;
          end
          else if (!eof_match && baud_rate_enb && !(data_0 || data_1))//No data nor EOF -> Error
          begin
            next = PREAMBLE;
            bit_counter = {1'b0, 1'b1};
            error_next = 1'b1;
            cor_rst = 1'b1;
            cardet_next = 1'b0;
          end
          else if (eof_match && baud_rate_enb && (eof_bit_count == (EOF_BITS-1))) //works correctly
          begin
            next = PREAMBLE;
            bit_counter = {1'b0, 1'b1};
            error_next = 1'b0;
            cor_rst = 1'b1;
            cardet_next = 1'b0;
            
            register_fifo = 1'b1;
          end
          else next = EOF;

        end
      endcase
    end

endmodule

