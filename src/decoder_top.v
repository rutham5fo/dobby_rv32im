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

/* Notes:
		
		*	rhs mux --> Imm, reg_csr, mtvec_base
		*	lhs mux --> pc, csr_data, accumH/adder_res, mcause_val[W-2:0] << 2		[order - 0, 1, 2, 3... from left to right]
			
		*	Comparator synthesizes into a smaller unit compared to when using the alu adder to perform comparision.
			In addition if the alu is used to compare, address gen requires an additional adder, which takes up more space.
		  
		* Branch/Jump Unit handles branching depending on signals ex_br_en and ex_jmp_en recieved from decoder through execute
		
		* Mux after execution stage (before pipeline) hadles nextpc and alu_result reg entry selection based on br and jmp signals from decoder
		
		* we is controled by a gate outside decoder stage that compares both signals from we_set (dec_br_en, ex_br_en) from branch unit 
		  and dec_stall from stall unit to generate fe_we. That is: fe_we = (set_we && !dec_stall) ? 1'b1 : 1'b0;
		
		* Stall signal acts as enable for PC_reg. If stalled PC_reg remains same maintining all signals down the line.
		
*/

module decoder_top #( parameter W = 32, parameter R = 5)(	input			clk,
															input			a_reset_n,
															input	[6:0]	fe_funct7,
															input	[4:0]	fe_rs1,
															input	[4:0]	fe_rs2,
															input	[2:0]	fe_funct3,
															input	[4:0]	fe_rd,
															input	[6:0]	fe_opcode,
															input			in_mul_rdy,
															input			in_div_rdy,
															input	[W-1:0]	reg_csr,		// csr reg input
															input	[W-1:0]	mtvec_val,
															input	[W-1:0]	mcause_val,
															input			int0,
															input			int1,
															input	[W-1:0]	PC,
															input	[W+1:0]	accumH,
															input	[W+1:0]	adder_res,
															input			mul_nop,
															input			div_act,
															input			mul_act,
															input	[R-1:0]	in_ex_rd,
															input			we,
															input			dec_intr_en,
															
															output	[2:0]	curr_state,
															output			useRs1,
															output			useRs2,
															//output			readCsr,
															//output			readRs1,
															//output			readRs2,
															output			idle,
															output	[W+1:0]	ex_lhs,
															output	[W+1:0]	ex_rhs,
															output	[R-1:0]	ex_rd,
															output	[2:0]	ex_funct3,
															output	[3:0]	ex_opcode,
															output			ex_op_ctrl,
															output			ex_useRd,
															output			ex_useCsr,
															output			ex_jmp_en,			// final signal tied to branch unit and ex stage reg
															output			trap,
															output			int0_ack,
															output			int1_ack,
															output			muldiv_act,
															output	[2:0]	csr_addr
														);
	
	// Decoder signals
	wire	[6:0]	opcode;
	wire	[R-1:0]	rs1;
	wire 	[R-1:0]	rs2;
	wire 	[R-1:0]	rd;
	wire 	[2:0]	funct3;
	wire 	[6:0]	funct7;
	wire	[11:0]	funct12;	// used for csrs
	wire 	[W-1:0]	imm;
	wire	[W-1:0]	csr_data;
	wire	[W-1:0]	pc_4;
	
	// Mux signals
	reg		[W+1:0]	mux_lhs_out;
	reg		[W+1:0]	mux_rhs_out;
	wire	[W+1:0]	mux_restore_out;
	wire	[1:0]	mux_lhs_sel;
	wire	[1:0]	mux_rhs_sel;
	wire			mux_restore_sel;
	
	assign opcode = fe_opcode;
	assign rd = fe_rd;
	assign funct3 = fe_funct3;
	assign rs1 = fe_rs1;
	assign rs2 = fe_rs2;
	assign funct7 = fe_funct7;
	assign funct12 = {fe_funct7, fe_rs2};
	assign pc_4 = PC + 4;
	
	assign ex_lhs = mux_lhs_out;
	assign ex_rhs = mux_rhs_out;
	assign ex_rd = rd;
	assign ex_funct3 = funct3;
	assign ex_op_ctrl = funct7[5];
	
	assign mux_restore_sel = ((adder_res[W] & div_act) || (mul_nop & mul_act));
	
	// Muxes
	assign mux_restore_out = (mux_restore_sel) ? accumH : adder_res;
							
	imm_gen #( .W(W) ) imm_gen_i	(	.inst({funct7, rs2, rs1, funct3, rd}),
										.opcode(opcode),
										.imm_out(imm)
									);
								
	ctrl_unit #( .W(W) ) ctrl_unit_i	(	.clk(clk),
											.a_reset_n(a_reset_n),
											.opcode(opcode),
											.funct3(funct3),
											.funct12(funct12),
											.rd(rd),
											.rs1(rs1),
											.mul_div(funct7[0]),
											.in_mul_rdy(in_mul_rdy),
											.in_div_rdy(in_div_rdy),
											.int0(int0),
											.int1(int1),
											.mcause_msb(mcause_val[W-1]),
											.mtvec_lsb(mtvec_val[1:0]),
											.we(we),
											.pc_4(pc_4),
											.intr_en(dec_intr_en),
											
											.curr_state(curr_state),
											.useRd_out(ex_useRd),
											.useCsr(ex_useCsr),
											//.readCsr(readCsr),
											.idle(idle),
											.mux_lhs_sel(mux_lhs_sel),
											.mux_rhs_sel(mux_rhs_sel),
											.jmp_en(ex_jmp_en),
											.trap(trap),
											.int0_ack(int0_ack),
											.int1_ack(int1_ack),
											.csr_data(csr_data),
											.csr_addr(csr_addr),
											.out_opcode(ex_opcode),
											.muldiv_act(muldiv_act),
											.useRs1(useRs1),
											.useRs2(useRs2)
											//.readRs1(readRs1),
											//.readRs2(readRs2)
										);
	
	// LHS mux
	always @* begin
		case (mux_lhs_sel)
			2'd1	: mux_lhs_out = csr_data;
			2'd2	: mux_lhs_out = mux_restore_out;
			2'd3	: mux_lhs_out = mcause_val[W-1:0] << 1;
			default	: mux_lhs_out = PC;
		endcase
	end
	
	// RHS Mux
	always @* begin
		case (mux_rhs_sel)
			2'd1	: mux_rhs_out = reg_csr;
			2'd2	: mux_rhs_out = { mtvec_val[W-1:2], {2{1'b0}} };
			default	: mux_rhs_out = imm;
		endcase
	end
	
endmodule
