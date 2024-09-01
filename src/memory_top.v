// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   memory_top.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Thu Mar  3 22:04:14 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module memory_top #( parameter W = 32, parameter R = 5) (
					input	[W-1:0]	ex_result,
					input	[W-1:0]	ex_data,
					input	[R-1:0]	ex_rd,
					//input			ex_useRd,
					input	[2:0]	ex_funct3,
					input	[1:0]	ex_opcode,
					input	[W-1:0]	data_in,
					input	[W-1:0]	pc_4,
					
					output	[W-1:0]	wb_result,
					output	[W-1:0]	data_addr,
					output	[W-1:0]	data_out,
					output	[2:0]	width,
					output	[1:0]	opType
				);
	

	// MMU opcodes
	localparam	MMU_NONE	= 2'b00;
	localparam	MMU_LOAD	= 2'b10;
	localparam	MMU_STORE	= 2'b01;
	localparam	MMU_FWD_PC4	= 2'b11;
	
	reg	[W-1:0]	wb_result;
	reg	[3:0]	clk_en;
	reg	[1:0]	opType;
	
	assign data_out = ex_data;
	assign data_addr = ex_result;
	assign width = ex_funct3;
	
	// Load store unit
	always @* begin
		case (ex_opcode)
			MMU_STORE	: opType = MMU_STORE;
			MMU_LOAD	: opType = MMU_LOAD;
			default		: opType = MMU_NONE;
		endcase
	end
									
	// Result mux
	always @* begin
		case (ex_opcode)
			MMU_LOAD	: wb_result = data_in;
			MMU_FWD_PC4	: wb_result = pc_4;
			default		: wb_result = ex_result;
		endcase
	end

endmodule
