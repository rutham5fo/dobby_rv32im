// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   alu_top.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Fri Dec  3 01:25:57 2021 
// Last Change       :   $Date: 2021-12-07 20:45:14 +0100 (Tue, 07 Dec 2021) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

// Restoring division algorithm
module alu_div_unit #(  parameter W = 32, C = 6 )
                (	input           	load,
                    input     	     	clk,
                    input      	   		a_rst,
					input				div_res_sel,
					input	[1:0]		div_sbit,
					input	[2*(W+2):0]	accum,
					input				div_zero,
					input				div_overflow,
					input				dact,
					
                    output  [W-1:0] 	div_result,
                    output         		div_done
                );
               
    localparam counter_val = W;
	
	wire	        count_en;
    wire    [C-1:0] count_out;
	
	// Output/result reg
	reg	[W-1:0]	div_result;
	
	wire	[W-1:0]	quo;
	wire	[W-1:0]	rem;
	
	assign rem = accum[2*(W+2):W+3] >> 1;
	assign quo = accum[W+2:3];
	
	/* Control Signals */
	assign count_en = ((count_out || load) && !div_zero && !div_overflow);
	assign div_done = ((count_out == 1 || div_zero || div_overflow) && dact);
    
    div_counter #( .W(C), .V(counter_val) ) counter_i ( .clk(clk),
                                    					.reset(a_rst),
													 	.load(load),
														.en(count_en),
														
                                    				 	.count(count_out)
                                  				  	 );
	
	// result_sel control
	always @* begin
		if (div_zero) div_result = (div_res_sel) ? accum[W+5:W+4] : 32'hffffffff;
		else if (div_overflow) div_result = (div_res_sel) ? 1'b0 : accum[W+5:W+4];
		else begin
			if (div_res_sel) div_result = (div_sbit[1]) ? -rem : rem;
			else div_result = (div_sbit[0]) ? -quo : quo;
		end
	end
	
endmodule
