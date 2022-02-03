`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name   : fsafe_fsm
// Project       : Final Project - WimpFi Project
//-----------------------------------------------------------------------------
// Author        : Andrew Bachman  <bachmana@lafayette.edu> & Nate Beal <bealn@lafayette.edu>
// Created       : May 2021
//-----------------------------------------------------------------------------
// Description   : fsafe_fsm module provided in the exam, edited and implemented into our final 
//               : project.
//////////////////////////////////////////////////////////////////////////////////

module fsafe_fsm  #(parameter BPLIMIT = 512)
(
    input logic clk, rst, txen, bp_enb,
    output logic txen_fail
);
    localparam CW = $clog2(BPLIMIT+1);
    logic [CW-1:0] bpcount, bpcount_next;

    typedef enum logic [1:0] {TX_IDLE, TX_ACTIVE, TX_FAIL} states_t;
    states_t state, next;

    always_ff @(posedge clk) begin
        if (rst) begin
            bpcount <= 0;
            state <= TX_IDLE;
        end
        else begin
            bpcount <= bpcount_next;
            state <= next;
        end
    end

    always_comb 
	begin
		//DEFAULT VALUES
        bpcount_next = bpcount;
        next = state;
		txen_fail = 1'b0;//Added default value for txen_fail to avoid latch inference
		
        case (state)
        
            TX_IDLE: //Waits for TXEN to be high
			begin
                bpcount_next = 0;
                if (txen) next = TX_ACTIVE;
                else next = TX_IDLE;
            end
            
            TX_ACTIVE: //Counts
			begin
                if (bpcount >= BPLIMIT) next = TX_FAIL;
                else if (txen == 0) next = TX_IDLE;
                else if (bp_enb) begin
                    bpcount_next = bpcount + 1;
                    next = TX_ACTIVE;
                end
                else next = TX_ACTIVE;
            end
            
            TX_FAIL: 
			begin
                txen_fail = 1;
                next = TX_FAIL;
            end
        endcase
    end

endmodule: fsafe_fsm

