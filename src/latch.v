// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   csr_file.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Thu Mar 10 01:15:39 2022 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps
/*
module latch #( parameter W = 32, parameter V = 0 )
			(	input			en,
				input			a_reset_n,
				input			reset_dly,
				input	[W-1:0]	data,
				
				output			G_EN,
				output	[W-1:0]	Q
			);
			
	reg		[W-1:0]		Q;
	
	wire	[W-1:0]		latch_in;
	wire				gate_en;
	
	//assign latch_in = (!a_reset_n) ? V : data;
	assign latch_in = (!reset_dly) ? V : data;
	assign gate_en = en || ~a_reset_n;
	assign G_EN = gate_en;
	
	always @ (gate_en, latch_in) begin
		if (gate_en) Q <= latch_in;
	end

endmodule
*/
module latch #( parameter W = 32 )
			(	input			en,
				input	[W-1:0]	data,
				
				output	[W-1:0]	Q
			);
			
	reg		[W-1:0]		Q;
	
	//wire	[W-1:0]		latch_in;
	//wire				gate_en;
	
	//assign latch_in = (!a_reset_n) ? V : data;
	//assign gate_en = en || ~a_reset_n;
	
	always @ (en, data) begin
		if (en) Q <= data;
	end

endmodule
