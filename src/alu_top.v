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
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                              
//------------------------------------------------------------
`timescale 1ns/10ps

/*
 * ------------------
 * This is Version 2
 * ------------------
 */

/* ALU top level module */
module alu_top  #(  parameter W = 32 )
                (   
					input   [W+1:0] in_lhs,
                    input   [W+1:0] in_rhs,				// shamt = rhs[4:0] (I-Imm[4:0]}
                    input           op_ctrl,            // op_ctrl
					
					input			inv_rhs,
					input			shft_dir,
					input	[2:0]	arth_out_sel,
                   
                    output	[W+1:0]	adder_result,
					output  [W-1:0] shft_result,
					output  [W-1:0] arth_log_result
                );

	// Shift unit stage parameter
    localparam S = (W == 32) ? 5 : 6;
              
    // Shift unit signals
	wire	[4:0]	shamt;
    
    // Arth_log_unit signals
    wire    [W+1:0] add_result;

	assign shamt = in_rhs[4:0];
	assign adder_result = add_result;

	// Shift unit instantiation
    alu_shft_unit #( .N(W), .S(S) ) shft_unit_i (   .in_data(in_lhs[W-1:0]),
                                                    .shamt(shamt),
                                                    .shft_dir(shft_dir),
                                                    .shft_result(shft_result),
                                                    .shft_type(op_ctrl)
                                                );
	
    // Arithmatic and logical unit instantiation
    alu_arth_log_unit #( .W(W) ) arth_log_unit_i (  .in_lhs(in_lhs),
                                                    .in_rhs(in_rhs),
                                                    .inv_rhs(inv_rhs),
													.negate(op_ctrl),
													.arth_out_sel(arth_out_sel),
													
                                                    .arth_log_result(arth_log_result),
                                                    .adder_result(add_result)
                                                 );
									   
endmodule
