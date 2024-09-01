// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   branch_unit.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Mar  5 18:53:56 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module branch_unit #( parameter W = 32 )
			(	input			clk,
				input			a_reset_n,
				input	[1:0]	opcode,
				input			ex_jmp_en,
				input			ex_br_en,
				
				output			pc_sel,
				output			flush
			);
			
	// We need to insert NOPs (done by setting dec_we to 0 through flush),
	// for 2 extra cycles to flush the pre-fetch pipeline in fe2dec_reg.
	
	reg			pc_sel_reg;		// internal register to match pipeline timinig
	wire		pc_ctrl;		// pc control signal
	wire		br_valid;
	
	assign br_valid = (opcode == 2'b11) ? ex_br_en : 1'b0;
	assign flush = (ex_jmp_en || br_valid) ? 1'b1 : 1'b0;
	assign pc_sel = pc_sel_reg;
	assign pc_ctrl = (br_valid || ex_jmp_en) ? 1'b1 : 1'b0;
	
	// register the select signal output to match pipeline timing
	always @ (posedge clk or negedge a_reset_n) begin
		if (!a_reset_n) pc_sel_reg <= 1'b0;
		else pc_sel_reg <= pc_ctrl;
	end
	
endmodule
