// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   lhs_shifter.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Wed Mar 23 13:57:46 2022 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module accum_shifter #( parameter W = 32 ) (
					input	[W+2:0]	in_accumL,
					input	[W+1:0]	in_accumH,
					input			shft_inVal,
					input			mul_load,
					input			div_load,
					input	[W+1:0]	mul_load_val,
					input	[W+1:0]	div_load_val,
					input			mact,
					input			dact,
					
					output	[W+2:0]	out_accumL,
					output	[W+1:0]	out_accumH
				);
				
	reg	[W+2:0]		out_accumL;
	reg	[W+1:0]		out_accumH;
	
	wire	[2*(W+2):0]	full_accum;
	wire	[2*(W+2):0]	full_accum_shft_2;
	wire	[2*(W+2):0]	full_accum_shft_1;
	
	assign full_accum = {in_accumH, in_accumL};
	assign full_accum_shft_1 = full_accum << 1;
	assign full_accum_shft_2 = full_accum >>> 2;
	
	always @* begin
		case ({ mact, dact })
			2'b10	: { out_accumH, out_accumL } = full_accum_shft_2;
			2'b01	: { out_accumH, out_accumL } = { full_accum_shft_1[2*(W+2):4], shft_inVal, {3{1'b0}} };
			default	: begin
				if (mul_load) { out_accumH, out_accumL } = { {W+2{1'b0}}, mul_load_val, 1'b0 };
				else if (div_load) { out_accumH, out_accumL } = { {W+1{1'b0}}, div_load_val[W-1:0], {4{1'b0}} };
				else { out_accumH, out_accumL } = full_accum;
			end
		endcase
	end
		
endmodule
