// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   forward_unit.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Mar  5 19:25:11 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module forward_unit #( parameter R = 5 )
			(	input			clk,
				input			a_reset_n,
				input	[R-1:0]	dec_addr1,
				input	[R-1:0]	dec_addr2,
				input	[11:0]	dec_csr_addr,
				input	[R-1:0]	ex_rd,
				input	[11:0]	ex_csr_addr,
				input	[R-1:0]	mem_rd,
				input			useLhs,
				input			useRhs,
				input			useData,
				
				output	[1:0]	rs1_fwd_sel,
				output	[1:0]	rs2_fwd_sel,
				output	[1:0]	data_fwd_sel,
				output	[1:0]	comp_fwd_sel
			);
			
	reg	[1:0]	rs1_sel;
	reg	[1:0]	rs2_sel;
	reg	[1:0]	data_sel;
	reg	[1:0]	comp_sel;
	reg	[1:0]	rs1_sel_reg;
	reg	[1:0]	rs2_sel_reg;
	reg	[1:0]	data_sel_reg;
	reg	[1:0]	comp_sel_reg;
	
	assign rs1_fwd_sel = rs1_sel_reg;
	assign rs2_fwd_sel = rs2_sel_reg;
	assign comp_fwd_sel = comp_sel_reg;
	assign data_fwd_sel = data_sel_reg;
	
	always @ (posedge clk or negedge a_reset_n) begin
		if (!a_reset_n) begin
			rs1_sel_reg <= 1'b0;
			rs2_sel_reg <= 1'b0;
			data_sel_reg <= 1'b0;
			comp_sel_reg <= 1'b0;
		end
		else begin
			rs1_sel_reg <= rs1_sel;
			rs2_sel_reg <= rs2_sel;
			comp_sel_reg <= comp_sel;
			data_sel_reg <= data_sel;
		end
	end
	
	// lhs rs1 fwd ctrl control
	always @* begin
		rs1_sel = 1'b0;
		if (useLhs) begin
			if (dec_addr1 == ex_rd) rs1_sel = 2'b01;
			else if (dec_addr1 == mem_rd) rs1_sel = 2'b10;
		end
	end
	
	// rhs rs2 fwd control
	always @* begin
		rs2_sel = 1'b0;
		if (useRhs) begin
			if (dec_addr2 == ex_rd) rs2_sel = 2'b01;
			else if (dec_addr2 == mem_rd) rs2_sel = 2'b10;
			//else if (dec_csr_addr == ex_csr_addr) rs2_sel = 2'b11;
		end
	end
	
	// Branch/Data rs2 fwd control
	always @* begin
		data_sel = 1'b0;
		if (useData) begin
			if (dec_addr2 == ex_rd) data_sel = 2'b01;
			else if (dec_addr2 == mem_rd) data_sel = 2'b10;
		end
	end
	
	// Comparator rs1 fwd control
	always @* begin
		comp_sel = 1'b0;
		if (useData) begin
			if (dec_addr2 == ex_rd) comp_sel = 2'b01;
			else if (dec_addr2 == mem_rd) comp_sel = 2'b10;
		end
	end
	
endmodule
