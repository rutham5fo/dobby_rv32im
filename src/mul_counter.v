// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                              
// Filename          :   alu_mul_unit.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Tue Nov 30 20:46:43 2021 
// Last Change       :   $Date$
// by                :   $Author$                           
//------------------------------------------------------------
`timescale 1ns/10ps

module mul_counter #( parameter W = 5, parameter V = 0 )
			(	input 			en,
				input			load,
				input 			clk,
				input 			reset,
				
				output	[W-1:0]	count
			 );

	reg [W-1:0]	counter;
	
	assign count = counter;
	
	always @ (posedge clk or negedge reset) begin
		if (!reset) counter <= 1'b0;
		else if (en) begin
			if (load) counter <= V;
			else counter <= counter-1;
		end
	end
	
endmodule
