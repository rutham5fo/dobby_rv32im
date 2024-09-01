// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   alu_arth_log_unit.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Nov 27 16:14:55 2021 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

/* Arithmatic and Logic unit Top design */
module alu_arth_log_unit    #(  parameter W = 32 )
                            (   input   [W+1:0] in_lhs,
                                input   [W+1:0] in_rhs,
                                input           inv_rhs,
								input			negate,
								input	[2:0]	arth_out_sel,
								
                                output  [W-1:0] arth_log_result,
                                output  [W+1:0] adder_result
                            );
    
    reg	[W-1:0]		arth_log_result;
	reg				slt_out;
	wire			sltu_out;
	wire	[W-1:0]	out_inv_mux;
	wire	[W+1:0]	add_inv_mux;
	wire	[W-1:0]	out_and;
	wire	[W-1:0]	out_xor;
	wire	[W-1:0]	out_or;
    
    wire    [W+1:0] add_rslt;
    
    assign adder_result = add_rslt;
	
	assign add_inv_mux = (negate) ? ~in_rhs : in_rhs;
	assign out_inv_mux = (inv_rhs) ? ~in_rhs[W-1:0] : in_rhs[W-1:0];
	assign out_and = out_inv_mux & in_lhs[W-1:0];
	assign out_xor = in_lhs[W-1:0] ^ in_rhs[W-1:0];
	assign out_or = in_lhs[W-1:0] | in_rhs[W-1:0];
	
	// SLTU logic
	assign sltu_out = add_rslt[W];

    // Instantiate CLA
    carry_lookahead_adder #(.W(W+2)) cla_i   (   .in_a(in_lhs),
                                                 .in_b(add_inv_mux),
                                                 .in_cin(negate),
                                                 .adder_result(add_rslt)
                                            );
											
	
    // SLT logic
	always @* begin
		if (add_rslt[W]) slt_out = (add_rslt[W-1]) ? 1'b0 : 1'b1;
		else slt_out = add_rslt[W-1];
	end
	
	// Output mux
	always @* begin
		case (arth_out_sel)
			3'b001	: arth_log_result = add_rslt[W-1:0];
			3'b010	: arth_log_result = slt_out;
			3'b011	: arth_log_result = sltu_out;
			3'b100	: arth_log_result = out_and;
			3'b101	: arth_log_result = out_or;
			3'b110	: arth_log_result = in_lhs[W-1:0];
			default	: arth_log_result = out_xor;
		endcase
	end

endmodule
