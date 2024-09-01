// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   decoder_top.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sat Dec 25 23:24:31 2021 
// Last Change       :   $Date: 2022-03-07 14:59:24 +0100 (Mon, 07 Mar 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module exec_top #( parameter W = 32)(
				input			clk,
				input			a_reset_n,
				input	[W+1:0]	in_lhs,
				input	[W+1:0]	in_rhs,
				input	[W-1:0]	reg_rs1,
				input	[W-1:0]	reg_rs2,
				input	[W+2:0]	accumL,
				input	[3:0]	opcode,
				input			op_ctrl,
				input	[2:0]	funct3,
				input			useRs1,
				input			useRs2,
				input	[4:0]	rd,
				input			useRd,
				
				output			mul_load,
				output			div_load,
				output			mul_act,
				output			div_act,
				output			mul_nop,
				output	[1:0]	alu_rslt_mux_sel,
				output	[1:0]	data_sel,
				output			csr_fwd,
				output	[W+1:0]	div_load_val,
				output	[W+1:0]	mul_load_val,
				output	[W+1:0]	adder_result,
				output	[W-1:0]	shft_result,
				output	[W-1:0]	arth_log_result,
				output	[W-1:0]	mul_result,
				output	[W-1:0]	div_result,
				output			mul_rdy,
				output			div_rdy,
				output	[1:0]	out_opcode,
				output	[4:0]	out_rd,
				output			out_useRd,
				output	[W-1:0]	jmp_pc4
			);

	// ALU opcodes
	localparam	ALU_OPI		= 4'b0000;
	localparam	ALU_ACT		= 4'b0001;			   // BRANCH, SLT, SLTU, SLTI and SLTUI all share the same operation
	localparam	ALU_OP		= 4'b0010;			   // LOAD and STORE --> lhs + rhs ADD, OP_IMM, OP and AUIPC share the operation
	localparam	ALU_LD		= 4'b0011;
	localparam	ALU_ST		= 4'b0100;
	// CSR opcodes
	localparam	ALU_FWDASS	= 4'b0101;
	localparam	ALU_CSRRC	= 4'b0110;
	localparam	ALU_CSRRS	= 4'b0111;
	// Misc
	localparam	ALU_ADD		= 4'b1000;
	localparam	OPT_STORE	= 4'b1001;
	localparam	OPT_LOAD	= 4'b1010;
	localparam	OPT_BRANCH	= 4'b1011;
	
	// M extension      
	localparam	MUL		= 3'b000;
	localparam	MULH	= 3'b001;
	localparam	MULHSU	= 3'b010;
	localparam	MULHU	= 3'b011;
	localparam	DIV		= 3'b100;
	localparam	DIVU	= 3'b101;
	localparam	REM		= 3'b110;
	localparam	REMU	= 3'b111;
	
	// OP codes
	localparam	ADD_SUB		= 3'b000;              // Add or Sub determined by instruction[30]
	localparam	SLL			= 3'b001;
	localparam	SLT			= 3'b010;
	localparam	SLTU		= 3'b011;
	localparam	XOR			= 3'b100;
	localparam	SRL_SRA		= 3'b101;              // Arithmatic or logical shift is determined by instruction[30]
	localparam	OR			= 3'b110;
	localparam	AND			= 3'b111;
	
	// Execute Signals
	wire	[W+1:0]	lhs_out;
	wire	[W+1:0]	rhs_out;
	wire	[W+1:0]	shft_out;
	wire	[W+1:0]	ext_rs1;
	wire	[W+1:0]	ext_rs2;
	wire	[2:0]	arth_out_sel;
	wire			mux_op_ctrl_out;
	wire			mux_shft_out;
	reg				out_op_ctrl;
	
	// ALU control signals
	wire			shft_dir;
	wire			mul_res_sel;
	wire			div_res_sel;
	wire			inv_rhs;

	// Mul_unit signals
	wire	[2:0]	q;
	wire			mul_zero;
	wire			mul_op_val;
	wire			mul_shft;
	wire			mul_nop_val;
	wire			mul_cond1;
	reg		[1:0]	mul_sbit;
	
	// Div_unit signals
	wire			div_overflow;
	wire			div_zero;
	wire			div_unsigned;
	wire	[1:0]	div_sbit;
	
	assign ext_rs1 = (mul_sbit[0]) ? { {2{reg_rs1[W-1]}}, reg_rs1 } : reg_rs1;
	assign ext_rs2 = (mul_sbit[1]) ? { {2{reg_rs2[W-1]}}, reg_rs2 } : reg_rs2;
	assign mux_op_ctrl_out = (mul_cond1) ? mul_op_val : out_op_ctrl;
	assign mux_shft_out = (mul_cond1) ? mul_shft : 1'b0;
	
	//assign q = accumL_q;
	assign q = accumL[2:0];
	assign shft_out = (mux_shft_out) ? ext_rs2 << 1 : ext_rs2;
	assign mul_zero = (!reg_rs1);
	assign mul_cond1 = (opcode == ALU_LD || opcode == ALU_ACT) && (funct3 == MUL || funct3 == MULH || funct3 == MULHU || funct3 == MULHSU);
	
	assign div_unsigned = funct3 == DIVU || funct3 == REMU;
	assign div_overflow = reg_rs2 == 32'hffffffff && reg_rs1 == 32'h80000000 && !div_unsigned;
	assign div_sbit = { reg_rs1[W-1], (reg_rs1[W-1] ^ reg_rs2[W-1]) };	// Holds the sign bits of quotient and reminder --> reg_rs1[W-1] = reminder; (reg_rs1[W-1] ^ reg_rs2[W-1]) = quotient
	assign div_zero = (!reg_rs2);
	
	assign mul_op_val = q == 3'b100 || q == 3'b101 || q == 3'b110;
	assign mul_shft = q == 3'b011 || q == 3'b100;
	assign mul_nop_val = q == 3'b111 || q == 3'b000;
	assign mul_nop = mul_nop_val;
	
	assign lhs_out = (useRs1) ? ext_rs1 : in_lhs;
	assign rhs_out = (useRs2) ? shft_out : in_rhs;
	assign mul_load_val = ext_rs1;
	assign div_load_val = (reg_rs1[W-1]) ? -ext_rs1 : ext_rs1;
	
	assign jmp_pc4 = lhs_out + 4;
	
	alu_ctrl #( .W(W) ) alu_ctrl_i (
				.funct3(funct3),
       	    	.opcode(opcode),
				.rd(rd),
				.useRd(useRd),
			
				.inv_rhs(inv_rhs),
				.shft_dir(shft_dir),
				.alu_rslt_mux_sel(alu_rslt_mux_sel),
				.mul_load(mul_load),
				.div_load(div_load),
				.mact(mul_act),
				.dact(div_act),
				.mul_res_sel(mul_res_sel),
				.div_res_sel(div_res_sel),
				.data_sel(data_sel),
				.csr_fwd(csr_fwd),
				.arth_out_sel(arth_out_sel),
				.out_opcode(out_opcode),
				.out_rd(out_rd),
				.out_useRd(out_useRd)
   		    );
				
	alu_top #( .W(W) ) alu_i (
					.in_lhs(lhs_out),
					.in_rhs(rhs_out),
					.op_ctrl(mux_op_ctrl_out),
					.inv_rhs(inv_rhs),
					.shft_dir(shft_dir),
					.arth_out_sel(arth_out_sel),
					
					.adder_result(adder_result),
					.shft_result(shft_result),
					.arth_log_result(arth_log_result)
				);
				
	// Multiply unit instantiation                                             
    alu_mul_unit #( .W(W+2) ) mul_unit_i (	.clk(clk),
                                            .a_rst(a_reset_n),
                                            .load(mul_load),
											.mul_res_sel(mul_res_sel),
											.product({ in_lhs, accumL }),
											.mact(mul_act),
											.mul_zero(mul_zero),
													
                                            .mul_result(mul_result),
                                            .mul_done(mul_rdy)
                                         );
										 
	// Division unit instantiation
    alu_div_unit #( .W(W) ) div_unit_i (    .clk(clk),
                                            .a_rst(a_reset_n),
                                            .load(div_load),
											.div_res_sel(div_res_sel),
											.div_zero(div_zero),
											.div_overflow(div_overflow),
											.div_sbit(div_sbit),
											.accum({ in_lhs, accumL }),
											.dact(div_act),
											
                                            .div_result(div_result),
                                            .div_done(div_rdy)
                                       );
				
	// out_op_ctrl block
	always @* begin
		out_op_ctrl = 1'b0;
		mul_sbit = 2'b0;
		if (opcode == ALU_LD || opcode == ALU_ACT) begin
			case (funct3)
				MUL, MULH : mul_sbit = 2'b11;
				MULHU  : mul_sbit = 2'b00;
				MULHSU : mul_sbit = 2'b10;
				DIV, REM	: begin
					out_op_ctrl = ~reg_rs2[W-1];
					mul_sbit = 2'b11;
				end
				DIVU, REMU	: begin
					out_op_ctrl = 1'b1;
					mul_sbit = 2'b00;
				end
			endcase
		end
		else if (opcode == ALU_OP) begin
			case (funct3)
				SLT, SLTU	: out_op_ctrl = 1'b1;
				default		: out_op_ctrl = op_ctrl;
			endcase
		end
	end

endmodule
