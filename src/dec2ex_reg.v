// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   dec2ex_reg.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Thu Mar  3 16:51:27 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module dec2ex_reg #( parameter W = 32, parameter R = 5 )
				(	input			clk1,				// Inactive when dec_stall = 1
					input			clk2,				// Inactive if dec_stall = 1 && muldiv = 0
					input			clk3,				// Inactive if muldiv = 0
					input			clk4,				// Inactive if dec_stall = 1 and trap = 0
					input			clk5,
					input			clk6,				// Inactive if dec_stall = 1 && stall_mmu = 0
					input			a_reset_n,
					input			clk1_en,				// Inactive when dec_stall = 1
					input			clk2_en,				// Inactive if dec_stall = 1 && muldiv = 0
					input			clk3_en,				// Inactive if muldiv = 0
					input			clk4_en,				// Inactive if dec_stall = 1 and trap = 0
					input			clk5_en,
					input			clk6_en,				// Inactive if dec_stall = 1 && stall_mmu = 0
					input	[W+1:0]	in_lhs,
					input	[W+1:0]	in_rhs,
					input	[W+2:0]	in_accumL,
					input	[R-1:0]	in_rd,
					input	[2:0]	in_csr_addr,
					input	[2:0]	in_funct3,
					input	[3:0]	in_opcode,
					input			in_op_ctrl,
					input			in_useRd,
					input			in_useCsr,
					input			in_jmp_en,
					input			in_useRs1,
					input			in_useRs2,
					input	[W-1:0]	in_reg_rs1,
					input	[W-1:0]	in_reg_rs2,
					input			in_fwd_sel1,
					input			in_fwd_sel2,
					
					output	[W+1:0]	out_lhs,
					output	[W+1:0]	out_rhs,
					output	[W+2:0]	out_accumL,
					output	[R-1:0]	out_rd,
					output	[2:0]	out_csr_addr,
					output	[2:0]	out_funct3,
					output	[3:0]	out_opcode,
					output			out_op_ctrl,
					output			out_useRd,
					output			out_useCsr,
					output			out_jmp_en,
					output			out_useRs1,
					output			out_useRs2,
					output	[W-1:0]	out_reg_rs1,
					output	[W-1:0]	out_reg_rs2,
					output			out_fwd_sel1,
					output			out_fwd_sel2
				);
				
	reg	[W+1:0]	out_lhs;
	reg	[W+1:0]	out_rhs;
	reg	[W+2:0]	out_accumL;
	reg	[R-1:0]	out_rd;
	reg	[2:0]	out_csr_addr;
	reg	[2:0]	out_funct3;
	reg	[3:0]	out_opcode;
	reg			out_op_ctrl;
	reg			out_useRd;
	reg			out_useCsr;
	reg			out_br_en;
	reg			out_jmp_en;
	reg			out_useRs1;
	reg			out_useRs2;
	reg	[W-1:0]	out_reg_rs1;
	reg	[W-1:0]	out_reg_rs2;
	reg			out_fwd_sel1;
	reg			out_fwd_sel2;
	
	always @ (posedge clk1 or negedge a_reset_n) begin
		if (!a_reset_n) begin
			out_funct3 <= 1'b0;
			out_reg_rs1 <= 1'b0;
			out_reg_rs2 <= 1'b0;
			out_fwd_sel1 <= 1'b0;
			out_fwd_sel2 <= 1'b0;
		end
		else if (clk1_en) begin
			out_funct3 <= in_funct3;
			out_reg_rs1 <= in_reg_rs1;
			out_reg_rs2 <= in_reg_rs2;
			out_fwd_sel1 <= in_fwd_sel1;
			out_fwd_sel2 <= in_fwd_sel2;
		end
	end
	
	always @ (posedge clk2 or negedge a_reset_n) begin
		if (!a_reset_n) begin
			out_useRs1 <= 1'b0;
			out_useRs2 <= 1'b0;
			out_rhs <= 1'b0;
			out_lhs <= 1'b0;
			out_op_ctrl <= 1'b0;
		end
		else if (clk2_en) begin
			out_useRs1 <= in_useRs1;
			out_useRs2 <= in_useRs2;
			out_rhs <= in_rhs;
			out_lhs <= in_lhs;
			out_op_ctrl <= in_op_ctrl;
		end
	end
	
	always @ (posedge clk3 or negedge a_reset_n) begin
		if (!a_reset_n) begin
			out_accumL <= 1'b0;
		end
		else if (clk3_en) begin
			out_accumL <= in_accumL;
		end
	end
	
	always @ (posedge clk4 or negedge a_reset_n) begin
		if (!a_reset_n) begin
			out_rd <= 1'b0;
			out_csr_addr <= 1'b0;
			//out_useRd <= 1'b0;
			out_useCsr <= 1'b0;
			out_jmp_en <= 1'b0;
		end
		else if (clk4_en) begin
			out_rd <= in_rd;
			out_csr_addr <= in_csr_addr;
			//out_useRd <= in_useRd;
			out_useCsr <= in_useCsr;
			out_jmp_en <= in_jmp_en;
		end
	end
	
	always @ (posedge clk5 or negedge a_reset_n) begin
		if (!a_reset_n) begin
			out_opcode <= 1'b0;
		end
		else if (clk5_en) begin
			out_opcode <= in_opcode;
		end
	end
	
	always @(posedge clk6, negedge a_reset_n) begin
		if (!a_reset_n) out_useRd <= 1'b0;
		else if (clk6_en) out_useRd <= in_useRd;
	end
	
endmodule
