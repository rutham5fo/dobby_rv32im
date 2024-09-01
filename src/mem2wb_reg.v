// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   mem2wb_reg.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Fri Mar  4 16:00:56 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module mem2wb_reg #( parameter W = 32, parameter R = 5)
				(	input			clk,
					input			a_reset_n,
					input	[W-1:0]	in_result,
					input	[R-1:0]	in_rd,
					input			in_useRd,
					
					output	[W-1:0]	out_result,
					output	[R-1:0]	out_rd,
					output			out_useRd
				);
	
	reg	[W-1:0]	out_result;
	reg	[R-1:0]	out_rd;
	reg			out_useRd;
	
	always @ (posedge clk or negedge a_reset_n) begin
		if (!a_reset_n) begin
			out_result	<= 1'b0;
			out_rd		<= 1'b0;
			out_useRd	<= 1'b0;
		end
		else begin
			out_result		<= in_result;
			out_rd			<= in_rd;
			out_useRd		<= in_useRd;
		end
	end

endmodule
