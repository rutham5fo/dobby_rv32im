// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   ex2mem_reg.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Thu Mar  3 17:03:05 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module ex2mem_reg #( parameter W = 32, parameter R = 5 )
				(	input			clk1,
					//input			clk2,
					input			a_reset_n,
					input			clk1_en,
					input	[W-1:0]	in_result,
					input	[W-1:0]	in_data,
					input	[R-1:0]	in_rd,
					input	[2:0]	in_csr_addr,
					input	[2:0]	in_funct3,
					input	[1:0]	in_opcode,
					input			in_useRd,
					input			in_useCsr,
					input	[W-1:0]	in_jmp_pc4,
					
					output	[W-1:0]	out_result,
					output	[W-1:0]	out_data,
					output	[R-1:0]	out_rd,
					output	[2:0]	out_csr_addr,
					output	[2:0]	out_funct3,
					output	[1:0]	out_opcode,
					//output			out_useRd,
					//output			out_useRd_mst,
					output			out_useRd_slv,
					output			out_useCsr,
					output	[W-1:0]	out_jmp_pc4
				);
				
	reg	[W-1:0]	out_result;
	reg	[W-1:0]	out_data;
	reg	[R-1:0]	out_rd;
	reg	[2:0]	out_csr_addr;
	reg	[2:0]	out_funct3;
	reg	[1:0]	out_opcode;
	//reg			out_useRd;
	reg			out_useCsr;
	reg	[W-1:0]	out_jmp_pc4;
	
	//reg			inter_useRd_mst;
	reg			inter_useRd_slv;
	
	//wire		inter_useRd_mst;
	//wire		inter_useRd_slv;
	
	//assign out_useRd_mst = inter_useRd_mst;
	assign out_useRd_slv = inter_useRd_slv;
	
	always @ (posedge clk1 or negedge a_reset_n) begin
		if (!a_reset_n) begin
			out_result		<= 1'b0;
			out_data		<= 1'b0;
			out_csr_addr	<= 1'b0;
			out_funct3		<= 1'b0;
			out_opcode		<= 1'b0;
			//out_useRd		<= 1'b0;
			inter_useRd_slv <= 1'b0;
			out_rd			<= 1'b0;
			out_useCsr		<= 1'b0;
			out_jmp_pc4		<= 1'b0;
		end
		else if (clk1_en) begin
			out_result		<= in_result;
			out_data		<= in_data;
			out_csr_addr	<= in_csr_addr;
			out_funct3		<= in_funct3;
			out_opcode		<= in_opcode;
			//out_useRd		<= in_useRd;
			inter_useRd_slv <= in_useRd;
			out_rd			<= in_rd;
			out_useCsr		<= in_useCsr;
			out_jmp_pc4		<= in_jmp_pc4;
		end
	end
	/*
	always @ (negedge clk1, negedge a_reset_n) begin
		if (!a_reset_n) inter_useRd_mst <= 1'b0;
		else if (clk1_en) inter_useRd_mst <= in_useRd;
	end
	*/
	/*
	always @ (clk2, a_reset_n, in_useRd) begin
		if (!a_reset_n) inter_useRd_mst <= 1'b0;
		else if (clk2) inter_useRd_mst <= in_useRd;
	end
	
	always @ (clk1, a_reset_n, inter_useRd_mst) begin
		if (!a_reset_n) inter_useRd_slv <= 1'b0;
		else if (clk1) inter_useRd_slv <= inter_useRd_mst;
	end
	*/
endmodule
