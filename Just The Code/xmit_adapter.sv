`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : xmit_adapter
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : FSM interface between the UART receiver, MX Transmitter and the FIFO. 
//               : Controls valid rdy interfae between UART and manchester and loads data
//               : into FIFO.
//////////////////////////////////////////////////////////////////////////////////

module xmit_adapter
(
    input logic clk, rst, cardet, tx_en, txen_fail, mx_br_en, mx_br_en_8x, register_fifo, xrdy, uvalid,
    input logic [2:0] bit_in_byte, [7:0] udata, [7:0] src_addr, [7:0] packet_type, [7:0] crc,
    output logic write_data, read_data, urdy, xvalid, xsnd, error, data_sel, [2:0] bit_eighths, [2:0] STATE,
    output logic [7:0] write_index, [7:0] read_index, [7:0] fifo_data
);

  //Parameters
  localparam preamble_byte = 8'b01010101;
  localparam sfd_byte = 8'b11010000;
  localparam DIFS_BP = 40;
  localparam SLOT_TIME_BP = 8;

  logic urdy_next, uvalid_next, xsnd_next, crc_fourths_rst; 
  logic [5:0] SLOT_TIME, SLOT_TIME_NEXT;
  logic [1:0] write_counter_ctrl, read_counter_ctrl, wait_counter_ctrl; //{rst, enb}
  logic [7:0] fifo_data_next, rand_num, RAND_NUM;
  logic [9:0] bit_period_count, RAND_NUM_2;


  typedef enum logic [2:0]
  {
      RESET=3'b000, LOAD_PACKET_INFO= 3'b001, WRITE_TO_FIFO = 3'b010, WAIT_FOR_DIFS = 3'b011, WAIT_SLOT_TIME = 3'b100,
      READ_FIFO_DATA = 3'b101, CRC = 3'b110, TX_FAIL = 3'b111
  } states_t;
  states_t state, next;

  //Write 
  counter #(.W(8)) U_READ_BYTES_COUNT   (.clk, .rst(rst || read_counter_ctrl[1]), .enb(read_counter_ctrl[0]), .q(read_index));
  counter #(.W(8)) U_WRITE_BYTES_COUNT  (.clk, .rst(rst || write_counter_ctrl[1]), .enb(write_data), .q(write_index));
  
  //Timing and re-transmission
  counter #(.W(10)) U_BIT_PERIOD_COUNTER (.clk, .rst(rst || wait_counter_ctrl[1]), .enb(mx_br_en && wait_counter_ctrl[0]), .q(bit_period_count));
  counter #(.W(3))  U_BIT_EIGHTHS        (.clk, .rst(rst || crc_fourths_rst), .enb(mx_br_en_8x), .q(bit_eighths));
  //counter_random_num #(.W(8), .DIV(3)) U_RAND_NUM_GEN   (.clk, .rst, .enb(clk), .q(RAND_NUM));//Pseudo rand number
  
  //
  always_ff @(posedge clk)
  begin
      if(rst)
      begin
          state <= RESET;
          urdy <= 0;
          xsnd <= 0;
          SLOT_TIME <= '0;
      end
      else
      begin
          state <= next;
          urdy <= urdy_next;
          xsnd <= xsnd_next;
          SLOT_TIME <= SLOT_TIME_NEXT;
      end
  end

  always_comb
    begin
      //DEFAULT VALUES
      next = RESET;
      error = 1'b0;
      urdy_next = urdy;
      xsnd_next = xsnd;
      SLOT_TIME_NEXT = SLOT_TIME;
      
      fifo_data = 8'h00;
      read_data = 1'b0;
      write_data = 1'b0;
      xvalid = 1'b0;
      data_sel = 1'b0;
      RAND_NUM = '0;

      //Counter Controls
      write_counter_ctrl = {1'b0, 1'b0};  //{rst, enb}
      read_counter_ctrl = {1'b0, 1'b0};   //{rst, enb}
      wait_counter_ctrl = {1'b0, 1'b0};   //{rst, enb}

      unique case (state)
        RESET:
        begin
          next = LOAD_PACKET_INFO;
          urdy_next = 0;
          uvalid_next = 0;
          xsnd_next = 0;
          SLOT_TIME_NEXT = '0;
          fifo_data_next = 8'b00000000;

          write_counter_ctrl = {1'b1, 1'b0}; //{rst, enb}
          read_counter_ctrl = {1'b1, 1'b0}; //{rst, enb}
          wait_counter_ctrl = {1'b1, 1'b0};   //{rst, enb}
        end

        LOAD_PACKET_INFO: //Sends: Preamble, SFD, Dest Address, Source Address, Type of Byte
        begin
          next = LOAD_PACKET_INFO;
          write_data = 1'b1;
          write_counter_ctrl = {1'b0, 1'b1}; //{rst, enb}
    
          if(packet_type == 8'h30 || packet_type == 8'h31)// Type 0, Type 1 - ASCII 8'h30
          begin
              if(write_index == 8'd0 || write_index == 8'd1) fifo_data = preamble_byte;// Pream 1
              else if(write_index == 8'd2) //SFD
              begin
                 fifo_data = sfd_byte;
                 next = WRITE_TO_FIFO;
              end
              else next = WRITE_TO_FIFO;
          end
          else //Error in wrong packet_type
          begin
            error = 1'b1;
            next = RESET;
          end
          
          //Too Long of Transmission Fail Safe Timer Trips
          if(txen_fail)
          begin
              error = 1'b1;
              next = TX_FAIL;
          end
        end

        WRITE_TO_FIFO: //Read Data from UART
        begin
          next = WRITE_TO_FIFO;

          if(register_fifo && udata == 8'd4 && write_index > 3'd5)//Transition to sending manchester transmitter data
          begin
            xsnd_next = 1'b1;
            urdy_next = 1'b1;
            if(cardet)
            begin
                next = WAIT_FOR_DIFS; //If the network is being read as busy
                SLOT_TIME_NEXT = '0;
            end
            else next = READ_FIFO_DATA;//Data from FIFO read from transmitter
          end
          else if(register_fifo && udata != 8'd4) //IN HERE
          begin
            //Defaults
            write_data = 1'b1;
            xsnd_next = 1'b0;
            urdy_next = 1'b1;
            write_counter_ctrl = {1'b0, 1'b1}; //{rst, enb}
            
            // Statements forcefully overwrite Input data if they dont align with info
            if(write_index == 3'd4 && udata != src_addr) fifo_data = src_addr;
            else if(write_index == 3'd5 && udata != packet_type) fifo_data = packet_type;
            else fifo_data = udata;
            
          end
          else //Keep Collecting Data
          begin
            xsnd_next = 1'b0;
            urdy_next = 1'b1;
          end
          
          //Too Long of Transmission Fail Safe Timer Trips
            if(txen_fail)
            begin
                error = 1'b1;
                next = TX_FAIL;
            end
        end
        
        WAIT_FOR_DIFS: //If 
        begin
            next = WAIT_FOR_DIFS;
            wait_counter_ctrl = {1'b0, 1'b1};
            
            if(bit_period_count >= DIFS_BP)
            begin
                if(cardet)//Car detect is high, wait for a random amount of slot time
                begin
                    wait_counter_ctrl = {1'b1, 1'b0};//reset wait counter 
                    next = WAIT_SLOT_TIME;
                    RAND_NUM = read_index ^ write_index ^ bit_period_count ^ bit_eighths;
                    SLOT_TIME_NEXT = (RAND_NUM%63) + 1;//GENERATE PSUEDO RANDOM NUMBER
                end
                else next = READ_FIFO_DATA; //Carrier detect is not high, send immediately
            end
            
            //Too Long of Transmission Fail Safe Timer Trips
            if(txen_fail)
            begin
                error = 1'b1;
                next = TX_FAIL;
            end
        end
        
        WAIT_SLOT_TIME:
        begin
            next = WAIT_SLOT_TIME;
            wait_counter_ctrl = {1'b0, 1'b1};
            
            if(bit_period_count >= (SLOT_TIME*SLOT_TIME_BP))
            begin
                if(cardet)
                begin
                    next = WAIT_FOR_DIFS;
                    wait_counter_ctrl = {1'b1, 1'b0};
                    SLOT_TIME_NEXT = '0;
                end
                else
                begin
                    next = READ_FIFO_DATA; //Carrier detect is not high, send immediately
                    SLOT_TIME_NEXT = '0;
                end
            end
            
            //Too Long of Transmission Fail Safe Timer Trips
            if(txen_fail)
            begin
                error = 1'b1;
                next = TX_FAIL;
            end
        end

        //Sends Data to the Manchester Transmitter
        READ_FIFO_DATA:
        begin
          next = READ_FIFO_DATA;
          read_data = 1'b0;
          wait_counter_ctrl = {1'b1, 1'b0};

          if(mx_br_en && xrdy && read_index < (write_index))
          begin
            read_counter_ctrl = {1'b0, 1'b1}; //{rst, enb}
            read_data = 1'b1;
            xvalid = 1'b1;
          end
          else if(mx_br_en && xrdy && read_index >= (write_index))
          begin
            if(packet_type == 8'h30 || packet_type == 8'h31) read_counter_ctrl = {1'b1, 1'b0}; //{rst, enb}
            else error = 1'b1;
            
            write_counter_ctrl = {1'b1, 1'b0}; //{rst, enb}
            read_counter_ctrl = {1'b1, 1'b0};
            next = LOAD_PACKET_INFO;
            
            //Appends CRC to back of Transmitted Data
            if(packet_type == 8'h31)
            begin
                next = CRC;
                data_sel = 1'b1;
            end
          end
          
          //CRC Loading - NEW LINE
          if(read_index == write_index && packet_type == 8'h31) data_sel = 1'b1;
          
          //Too Long of Transmission Fail Safe Timer Trips
            if(txen_fail)
            begin
                error = 1'b1;
                next = TX_FAIL;
            end
        end
        
        CRC:
        begin
            next = CRC;
            if(mx_br_en && bit_in_byte == 3'd7) next = LOAD_PACKET_INFO;
            
            //Too Long of Transmission Fail Safe Timer Trips
            if(txen_fail)
            begin
                error = 1'b1;
                next = TX_FAIL;
            end
        end
        
        TX_FAIL:
        begin
            next = TX_FAIL;
            read_counter_ctrl = {1'b1, 1'b0};
            write_counter_ctrl = {1'b1, 1'b0};
        end

      endcase
    end
    
    assign STATE = state;

endmodule