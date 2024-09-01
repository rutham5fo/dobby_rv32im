// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   fe2dec_reg.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Mon Mar  7 14:18:19 2022 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module fe2dec_reg #( parameter W = 32 ) (
						input			clk,
						input			a_reset_n,
						input			clk_en,
						input	[W-1:0]	in_PC,
						input	[W-1:0]	in_nextPC,
						input	[W-1:0]	inst_in,
						
						output	[W-1:0] inst_out,
						output	[W-1:0]	out_PC_fe,
						output	[W-1:0]	out_PC_dec,
						output	[W-1:0]	out_nextPC_fe
					);
					
	localparam	PC_INIT_VAL	= 32'h0008;
	localparam	NOP			= 32'h0013;
	
	reg	[W-1:0]	PC [2:0];
	reg	[W-1:0]	nextPC;
	reg	[W-1:0]	inst_out;
	
	assign out_PC_fe = PC[0];
	assign out_PC_dec = PC[2];
	assign out_nextPC_fe = nextPC;
					
	always @(posedge clk or negedge a_reset_n) begin
		if (!a_reset_n) begin
			PC[0]		<= PC_INIT_VAL;
			PC[1]		<= PC_INIT_VAL;
			PC[2]		<= PC_INIT_VAL;
			nextPC	 	<= PC_INIT_VAL + 4;
			inst_out	<= NOP;
		end
		else if (clk_en) begin
			PC[0] 		<= in_PC;
			PC[1]		<= PC[0];
			PC[2]		<= PC[1];
			nextPC	 	<= in_nextPC;
			inst_out	<= inst_in;
		end
	end
	
endmodule
