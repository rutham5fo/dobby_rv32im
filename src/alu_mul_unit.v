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
// Last Change       :   $Date: 2021-12-07 16:26:11 +0100 (Tue, 07 Dec 2021) $
// by                :   $Author: baam21 $                           
//------------------------------------------------------------
`timescale 1ns/10ps

// Radix 4 Booth's algorithm
module alu_mul_unit #(  parameter W = 34, parameter C = 5 )
                (	input           clk,
                    input           a_rst,
                    input           load,
					input			mul_res_sel,
					input	[2*W:0]	product,
					input			mact,
					input			mul_zero,
					
                    output  [W-3:0] mul_result,
                    output          mul_done
                );
                
    localparam counter_val  = W/2;
	
    wire    [C-1:0] 	count_out;
	wire            	count_en;
	
	assign mul_result = (mul_res_sel) ? product[2*W-4:W-1] : product[W-2:1];
	
	/* Control Signals */
	assign mul_done = ((count_out == 1 || mul_zero) && mact);
	assign count_en = ((count_out || load) && !mul_zero);

    mul_counter #( .W(C), .V(counter_val) ) counter_i ( .clk(clk),
                                                     	.reset(a_rst),
													 	.load(load),
														.en(count_en),
														
                                                     	.count(count_out)
                                         			);
													
endmodule
