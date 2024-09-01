// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   soc.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Wed Feb 14 18:46:26 2024 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module reset_synchronizer (
	input		clk,
	input		a_reset_n,
	
	output reg	reset_sync_o
);
	reg rff1;
 	
	always @(posedge clk, negedge a_reset_n) begin
 		if (!a_reset_n) {reset_sync_o, rff1} <= 2'b0;
 		else {reset_sync_o, rff1} <= {rff1, 1'b1};
	end
	
endmodule
