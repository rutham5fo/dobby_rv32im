// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   regfile.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Mar  5 18:08:53 2022 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module clk_ctrl #( parameter NUM_REGS = 32 )
		(
				input	[NUM_REGS-1:0]	in_gclk,
				
				output					out_clk_ctrl
		);
		
	assign out_clk_ctrl = ~|in_gclk;
	
endmodule
