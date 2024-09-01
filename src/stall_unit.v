// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   stall_unit.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sun Mar  6 15:51:31 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module stall_unit #( parameter R = 5 )
		(	input			clk,
			input	[R-1:0]	dec_addr1,
			input	[R-1:0]	dec_addr2,
			input	[R-1:0]	ex_rd,
			input			mem_stalled,
			input	[1:0]	ex_optype,
			input			ex_useRd,
			input			int0,
			input			int1,
			input	[2:0]	curr_state,
			input			muldiv_act,
			input			mul_rdy,
			input			div_rdy,
			input	[1:0]	prefetch_cntr,
			
			output			dec_stall,
			output			dependancy,
			output			stall_mmu,
			output			core_sleep,
			output			rs1_fwd_sel,
			output			rs2_fwd_sel,
			output			dec_intr_en
		);
		
	// FSM states
	localparam	INST			= 3'b000;			// Default state
	localparam	MULDIV			= 3'b001;
	localparam	TRAP_MSTATUS	= 3'b010;
	localparam	TRAP_MEPC_SET	= 3'b011;
	localparam	TRAP_MTVEC		= 3'b100;
	localparam	TRAP_MEPC_RET	= 3'b101;
	localparam	TRAP_INT		= 3'b110;
	localparam	SLEEP			= 3'b111;
	
	reg		dec_intr_en;
	
	wire	addr1_eq;
	wire	addr2_eq;
	wire	dec_sleep;
	wire	dec_intr_en_drv;
	wire	mem_dependance;
	
	assign addr1_eq = dec_addr1 == ex_rd;
	assign addr2_eq = dec_addr2 == ex_rd;
	assign dec_sleep = (curr_state == SLEEP || curr_state == MULDIV) && !(int0 || int1);
	assign rs1_fwd_sel = addr1_eq & ex_useRd;
	assign rs2_fwd_sel = addr2_eq & ex_useRd;
	assign mem_dependance = (ex_optype == 2'b10 || ex_optype == 2'b01);
	assign dependancy = (mem_dependance || core_sleep);
	assign stall_mmu = (dependancy || (muldiv_act && !(mul_rdy || div_rdy)));
	
	assign dec_stall = (dependancy || mem_stalled || dec_sleep);
	assign core_sleep = ~(int0 || int1) && (curr_state == SLEEP && prefetch_cntr == 2'b00);
	
	assign dec_intr_en_drv = (curr_state != MULDIV && !dependancy && !mem_stalled && (int0 || int1));
	
	// Sample dec_intr_en on negedge to avoid glitches due to async int0 and int1
	always @(negedge clk) begin
		dec_intr_en <= dec_intr_en_drv;
	end
	
endmodule
