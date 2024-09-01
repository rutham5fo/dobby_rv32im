// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                              
// Filename          :   alu_shft_unit.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Nov 27 13:01:47 2021 
// Last Change       :   $Date$
// by                :   $Author$                           
//------------------------------------------------------------
`timescale 1ns/10ps

module alu_shft_unit    #(  parameter N = 32,
                            parameter S = 5     )
                            
                        (   input   [N-1:0] in_data,        // N bit wide Data to be shifted
                            input   [S-1:0] shamt,          // Shift amount
                            input           shft_dir,       // Select shift direction -> shft_dir = 0; Left Shift , shft_dir = 1; Right Shift
                            input           shft_type,      // Select shift type -> shft_type = 0; Logical Shift, shft_type = 1; Arithmatic Shift
                            
                            output  [N-1:0] shft_result     // Final result shifted by shift amount (shamt)
                        );
                        
	reg	[N-1:0]	shft_result;
	
	always @* begin
		if (shft_dir) shft_result = (shft_type) ? $signed(in_data) >>> shamt : in_data >> shamt;
		else shft_result = in_data << shamt;
	end
    
endmodule
