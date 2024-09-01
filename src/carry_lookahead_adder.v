// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   carry_lookahead_adder.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Fri Dec 03 21:17:21 2021 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

/* Carry Lookahead Adder */
module carry_lookahead_adder    #(  parameter W = 32 )
                                (   input   [W-1:0] in_a,
                                    input   [W-1:0] in_b,
                                    input           in_cin,
                                    
                                    output  [W-1:0] adder_result
                                );
								
	assign adder_result = in_a + in_b + in_cin;
	
endmodule
