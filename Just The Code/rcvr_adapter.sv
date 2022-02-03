`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : rcvr_adapter
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : FSM interface between the UART Transmitter, MX Receiver and the FIFO. 
//               : Controls valid rdy interfae between UART and manchester and loads data
//               : into FIFO.
//////////////////////////////////////////////////////////////////////////////////

module rcvr_adapter #(parameter BROADCAST_ADDR = 8'h2A)
(
    input logic clk, rst, ignore_broadcast, mx_br_en, mx_br_en_8x, error_mx_rcvr, cardet, uart_br_en, uart_xmit_rdy,  register_fifo, empty, receiving_data, [2:0] bit_in_byte, [7:0] mac_addr, [7:0] mx_rcvr_data, [7:0] crc,
    output logic wr_en, rd_en, uart_valid, crc_rst, rst_fifo, lockout, crc_enb, crc_register_fifo, GOOD_CRC, BAD_CRC, [2:0] STATE,
    output logic [7:0] crc_data, [7:0] rerrcnt
);
    //write_index, read_index, uart_valid_next

    //Signals
     logic lockout_next, rst_byte_counter, crc_conf_rst, crc_eighths_rst; //lockout, lockout_next, uart_valid_next;
     logic [7:0] frame_type, frame_type_next, src_addr, src_addr_next;
     
     logic write_counter_rst, read_counter_rst, CRC_ENB;
     logic [7:0] bytes_received, checksum, checksum_next, crc_reg, crc_reg_next;
     
     logic [2:0] bit_eighths, CRC_CNT;
     
     

  typedef enum logic [2:0]
  {
      RESET = 3'b000, IDLE = 3'b001, WRITE_TO_FIFO = 3'b010, CHECK_CRC = 3'b011, READ_FIFO_DATA = 3'b100
  } states_t;
  states_t state, next;
  
  //Counter Modules
  counter #(.W(8)) U_RCVR_BYTES_COUNT (.clk, .rst(rst || rst_byte_counter), .enb(register_fifo), .q(bytes_received));
  counter #(.W(8)) U_ERROR_COUNT      (.clk, .rst, .enb(error_mx_rcvr), .q(rerrcnt));
  counter #(.W(3)) U_BIT_EIGHTHS      (.clk, .rst(rst || crc_eighths_rst), .enb(mx_br_en_8x), .q(bit_eighths));
  counter #(.W(3)) U_CRC_CONF         (.clk, .rst(rst || crc_conf_rst), .enb(CRC_ENB), .q(CRC_CNT));
    
  //
  always_ff @(posedge clk)
  begin
      if(rst)
      begin
        state <= RESET;
        lockout <= 0;
        frame_type <= '0;
        src_addr <= '0;
        //uart_valid <= '0;
        checksum = 8'd0;
        crc_reg = 8'd0;
      end
      else
      begin
        state <= next;
        lockout <= lockout_next;
        frame_type <= frame_type_next;
        src_addr <= src_addr_next;
        checksum <= checksum_next;
        crc_reg <= crc_reg_next;
      end
  end
  
  always_comb
    begin
      //DEFAULT VALUES
      next = RESET;
      lockout_next = lockout;
      frame_type_next = frame_type;
      src_addr_next = src_addr;
      checksum_next = checksum;
      crc_reg_next = crc_reg;
      
      wr_en = 1'b0;
      rd_en = 1'b0;
      rst_fifo = 1'b0;
      rst_byte_counter = 1'b0;
      crc_eighths_rst = 1'b0;
      crc_enb = 1'b0;
      write_counter_rst = 1'b0;
      read_counter_rst = 1'b0;
      CRC_ENB = 1'b0;
      crc_register_fifo = 1'b0;
      crc_data = '0;
      crc_conf_rst= '0;
      crc_rst = '0;
      uart_valid = 1'b0;
      BAD_CRC = '0;
      GOOD_CRC = '0;

      unique case (state)
        RESET:
        begin
          next = IDLE;
          crc_eighths_rst = 1'b1;
          crc_rst = 1'b1;
          rst_fifo = 1'b1;
        end
        
        IDLE:
        begin
            if(lockout && cardet) lockout_next = 1'b1;
            else lockout_next = 1'b0;
        
            //Cardet is high, write stuff to fifo
            if(cardet && receiving_data && !lockout)
            begin
                next = WRITE_TO_FIFO;
                rst_byte_counter = 1'b1;
            end
            else next = IDLE;
            
        end
        
        WRITE_TO_FIFO:
        begin
            next = WRITE_TO_FIFO;
            
            if(mx_br_en_8x && bit_eighths == 3'd1) crc_enb = 1'b1;//register_fifo?
            else crc_enb = 1'b0;
            
            //Checks First byte: If the destination address does not equal our MAC Address
            if(register_fifo && bytes_received == 8'd0)//our MAC and the beacon
            begin
                if(mx_rcvr_data == mac_addr) wr_en = 1'b1;
                else if(mx_rcvr_data == BROADCAST_ADDR && !ignore_broadcast) wr_en = 1'b1;
                else
                begin
                    next = IDLE;
                    rst_fifo = 1'b1;
                    lockout_next = 1'b1;
                end
            end
                
            
            //Source Address
            if(register_fifo && bytes_received == 8'd1)
            begin
                src_addr_next = mx_rcvr_data;
                wr_en = 1'b1;
            end
            
            //FRAME TYPE
            if(register_fifo && bytes_received == 8'd2) 
            begin
                frame_type_next = mx_rcvr_data;
                wr_en = 1'b1;
            end
            
            //Every Other Data Byte
            if(register_fifo && bytes_received > 8'd2)
            begin
                wr_en = 1'b1;//check when ends
                if(frame_type == 8'h31 && register_fifo) checksum_next =  mx_rcvr_data;//Will update to last byte transmitted (CRC)
            end
            
            //CRC HANDLING
            if(bit_in_byte == 3'd7 && mx_br_en && frame_type == 8'h31) crc_reg_next = crc;
            
            //Transmission Over - Leaves EOF on 
            if(!cardet && frame_type == 8'h31 && crc_reg == 8'd0)
            begin     
                next = READ_FIFO_DATA;
                GOOD_CRC = 1'b1;
            end
            else if(!cardet && frame_type == 8'h31 && crc_reg != 8'd0)
            begin
                rst_fifo = 1'b1;
                next = IDLE;
                BAD_CRC = 1'b1;
            end
            else if(!cardet && frame_type == 8'h30) next = READ_FIFO_DATA; 
        end

        READ_FIFO_DATA: //UART side
        begin
            next = READ_FIFO_DATA;
           
            //CRC Stuff
            crc_conf_rst = 1'b1;
            crc_rst = 1'b1;
            
            //UART Transmission
            //Reads data from FIFO and is transmitted
            if(uart_br_en && uart_xmit_rdy) //&& write_index > read_index
            begin
                rd_en = 1'b1;
                uart_valid = 1'b1; 
            end
            
            //Fifo empty, look for more data
            if(empty) next = IDLE;
            
        end
      endcase
    end
    
    assign STATE = state;
endmodule
