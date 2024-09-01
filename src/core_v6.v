// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   core_v6.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Wed Mar 23 13:57:46 2022 
// Last Change       :   $Date: 2022-04-01 00:51:52 +0200 (Fri, 01 Apr 2022) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module core_v6 #( parameter W = 32 ) (
			input			clk,
			input			a_reset_n,
			input			int0_ext,
			input			int1_ext,
			input			mem_stall,
			input	[W-1:0]	inst_in,
			input	[W-1:0]	data_in,
			
			output	[W-1:0]	inst_addr,
			output	[W-1:0]	data_out,
			output	[W-1:0]	data_addr,
			output	[1:0]	opType,
			output	[2:0]	width,
			output			int0_ack,
			output			int1_ack,
			output			stall_mmu,
			output			sleep
		);
	
	localparam PREFETCH_CNT_STALL	= 1;
	localparam PREFETCH_CNT_INIT	= 2;
	localparam PREFETCH_CNT_BRNCH	= 3;
	
	// Fetch stage signals
	wire	[W-1:0]	fe_PC;
	wire	[W-1:0]	fe_PC_o;
	wire	[W-1:0]	fe_PC_fe;
	wire	[W-1:0]	fe_nextPC;
	wire	[W-1:0]	fe_nextPC_fe;
	wire	[W-1:0]	fe_nextPC_o;
	wire	[W-1:0]	instruction;
	
	// Decode stage signals
	wire	[W+1:0]	dec_lhs;
	wire	[W+1:0]	dec_lhs_o;
	wire	[W+1:0]	dec_rhs;
	wire	[W+1:0]	dec_rhs_o;
	wire	[4:0]	dec_rd;
	wire	[4:0]	dec_rd_o;
	wire	[2:0]	dec_funct3;
	wire	[2:0]	dec_funct3_o;
	wire	[3:0]	dec_opcode;
	wire	[3:0]	dec_opcode_o;
	wire			dec_op_ctrl;
	wire			dec_op_ctrl_o;
	wire			dec_idle;
	wire			dec_useRd;
	wire			dec_useRd_o;
	wire			dec_useCsr;
	//wire			dec_readCsr;
	wire			dec_useCsr_o;
	wire	[2:0]	dec_csr_addr;
	wire	[2:0]	dec_csr_addr_o;
	wire			dec_jmp_en;
	wire			dec_jmp_en_o;
	wire			dec_sleep;
	wire			dec_int0_ack;
	wire			dec_int1_ack;
	wire			dec_we;
	wire			dec_we_o;
	wire	[W+2:0]	dec_accumL;
	wire	[W+2:0]	dec_accumL_o;
	wire	[W+1:0]	dec_accumH;
	wire			dec_useRs1;
	wire			dec_useRs1_o;
	wire			dec_useRs2;
	wire			dec_useRs2_o;
	//wire			dec_readRs1;
	//wire			dec_readRs2;
	wire			dec_fwd_sel1;
	wire			dec_fwd_sel2;
	wire			dec_fwd_sel1_o;
	wire			dec_fwd_sel2_o;
	wire	[W-1:0]	dec_rs1_o;
	wire	[W-1:0]	dec_rs2_o;
	wire			dec_muldiv_act;
	wire			dec_trap;
	wire	[2:0]	dec_curr_state;
	wire			dec_intr_en;
	
	// Execute stage signals
	reg		[W-1:0]	ex_result_inter;
	reg		[W-1:0]	ex_data;
	wire	[W-1:0]	ex_data_o;
	wire	[W-1:0]	ex_result;
	wire	[W-1:0]	ex_result_o;
	wire			ex_mul_rdy;
	wire			ex_div_rdy;
	wire	[4:0]	ex_rd_o;
	wire	[2:0]	ex_csr_addr_o;
	wire	[2:0]	ex_funct3_o;
	wire	[1:0]	ex_opcode;
	wire	[1:0]	ex_opcode_o;
	//wire			ex_useRd_o;
	//wire			ex_useRd_mst_o;
	wire			ex_useRd_slv_o;
	wire			ex_useCsr_o;
	wire			ex_we_o;
	wire	[W-1:0]	ex_shft_result;
	wire	[W-1:0]	ex_arth_log_result;
	wire	[W-1:0]	ex_mul_result;
	wire	[W-1:0]	ex_div_result;
	wire			ex_br_en;
	
	wire			ex_inv_rhs;
	wire			ex_cin;
	wire			ex_shft_dir;
	wire	[1:0]	ex_alu_rslt_mux_sel;
	wire			ex_div_unsigned;
	wire	[1:0]	ex_mul_sbit;
	wire	[1:0]	ex_adder_sel;
	wire			ex_mact;
	wire			ex_dact;
	wire			ex_mul_res_sel;
	wire			ex_div_res_sel;
	wire	[1:0]	ex_data_sel;
	wire			ex_csr_fwd;
	wire	[2:0]	ex_arth_out_sel;
	wire			ex_op_ctrl;
	wire	[W+1:0]	ex_adder_result;
	wire	[W+2:0]	ex_accumL;
	wire	[W+1:0]	ex_accumH;
	wire			ex_mul_nop;
	wire	[W+1:0]	ex_mul_load_val;
	wire	[W+1:0]	ex_div_load_val;
	wire			ex_mLoad;
	wire			ex_dLoad;
	wire	[W-1:0]	ex_rs1;
	wire	[W-1:0]	ex_rs2;
	wire	[4:0]	ex_rd;
	wire			ex_useRd;
	wire	[7:0]	ex_bank_sel_o;
	wire	[W-1:0]	ex_jmp_pc4;
	wire	[W-1:0]	ex_jmp_pc4_o;
	
	
	// Memory stage signals
	wire	[W-1:0]	mem_data_addr;
	wire	[W-1:0]	mem_data_out;
	wire	[W-1:0]	mem_result;
	wire	[2:0]	mem_width;
	wire	[1:0]	mem_opType;
	
	// Reg file
	wire	[W-1:0]	rs1_out;
	wire	[W-1:0]	rs2_out;
	
	// CSR file
	wire	[W-1:0]	csr_out;
	wire	[W-1:0]	mtvec_val;
	wire	[W-1:0]	mcause_val;
	wire			global_ie;
	
	// Forward Unit signal (Part of stall_unit)
	
	// Branch unit signals
	wire			pc_sel;
	wire			set_fe_we;
	wire			flush_pipe;
	
	// Stall unit signals
	wire			stall_dec;
	
	// Core signals
	reg				mem_depend_reg;
	reg				init_done;
	reg				mem_depend_inv;
	reg		[1:0]	prefetch_cntr;
	//reg		[W+1:0]	pipe_addres;
	wire			fe_clk1;
	wire			dec_clk1;
	wire			dec_clk2;
	wire			dec_clk3;
	wire			dec_clk4;
	wire			dec_clk5;
	wire			dec_clk6;
	wire			ex_clk1;
	wire			int0;
	wire			int1;
	wire	[W-1:0]	reg_result;
	wire			core_sleep;
	wire			mem_depend;
	wire			core_stall;
	
	assign data_out = mem_data_out;
	assign data_addr = mem_data_addr;
	assign opType = mem_opType;
	assign width = mem_width;
	assign inst_addr = fe_PC_fe;
	assign int0_ack = dec_int0_ack;
	assign int1_ack = dec_int1_ack;
	
	// Clock gating
	assign dec_clk1 = ~stall_dec;
	assign dec_clk2 = ~(stall_dec && !dec_muldiv_act);
	assign dec_clk3 = (instruction[6:0] == 7'b0110011 && instruction[25] == 1);
	assign dec_clk4 = ~stall_dec;
	assign dec_clk5 = (dec_opcode ^ dec_opcode_o) && ~core_sleep;
	assign dec_clk6 = ~(stall_dec && !(ex_mul_rdy || ex_div_rdy)) || stall_mmu;
	assign ex_clk1 = ~(core_sleep || core_stall);
	assign fe_clk1 = (!(stall_dec || dec_muldiv_act) || ex_mul_rdy || ex_div_rdy) && !dec_trap;
	
	// Interrupts
	// mie bit enables of disables global interrupts
	assign int0 = int0_ext && global_ie && prefetch_cntr == 2'b00 && ~flush_pipe && ~dec_idle;
	assign int1 = int1_ext && global_ie && prefetch_cntr == 2'b00 && ~flush_pipe && ~dec_idle;
	
	assign sleep = core_sleep;
	assign dec_we = (!flush_pipe && !stall_dec && prefetch_cntr == 2'b00) ? 1'b1 : 1'b0;
	assign core_stall = (mem_stall || mem_depend_reg);
	
	//Muxes
	assign ex_result = (ex_csr_fwd) ? dec_rhs_o : ex_result_inter;		// CSR Forward mux
	assign ex_rs1 = (dec_fwd_sel1_o) ? ex_result_o : dec_rs1_o;		// Forwarding mux
	assign ex_rs2 = (dec_fwd_sel2_o) ? ex_result_o : dec_rs2_o;		// Forwarding mux
		
	fetch_top #( .W(W) ) fetch_stage_i (
					.nextPC_fe(fe_nextPC_fe),
					.nextPC_ex(ex_result_o),
					.pc_sel(pc_sel),
					
					.nextPC(fe_nextPC),
					.PC(fe_PC)
				);
	
	fe2dec_reg #( .W(W) ) fe2dec_reg_i (
					.clk(clk),
					.a_reset_n(a_reset_n),
					.clk_en(fe_clk1),
					.in_PC(fe_PC),
					.in_nextPC(fe_nextPC),
					.inst_in(inst_in),
					
					.inst_out(instruction),
					.out_PC_fe(fe_PC_fe),
					.out_PC_dec(fe_PC_o),
					.out_nextPC_fe(fe_nextPC_fe)
				);
						
	decoder_top #( .W(W) ) decode_stage_i (
					.clk(clk),
					.a_reset_n(a_reset_n),
					.fe_funct7(instruction[31:25]),
					.fe_rs1(instruction[19:15]),
					.fe_rs2(instruction[24:20]),
					.fe_funct3(instruction[14:12]),
					.fe_rd(instruction[11:7]),
					.fe_opcode(instruction[6:0]),
					.in_mul_rdy(ex_mul_rdy),
					.in_div_rdy(ex_div_rdy),
					.reg_csr(csr_out),
					.mtvec_val(mtvec_val),
					.mcause_val(mcause_val),
					.int0(int0),
					.int1(int1),
					.PC(fe_PC_o),
					.accumH(dec_lhs_o),
					//.adder_res(pipe_addres),
					.adder_res(ex_adder_result),
					.mul_nop(ex_mul_nop),
					.mul_act(ex_mact),
					.div_act(ex_dact),
					.in_ex_rd(ex_rd),
					.we(dec_we),
					.dec_intr_en(dec_intr_en),
					
					.curr_state(dec_curr_state),
					.useRs1(dec_useRs1),
					.useRs2(dec_useRs2),
					//.readRs1(dec_readRs1),
					//.readRs2(dec_readRs2),
					//.readCsr(dec_readCsr),
					.ex_lhs(dec_lhs),
					.ex_rhs(dec_rhs),
					.ex_rd(dec_rd),
					.ex_funct3(dec_funct3),
					.ex_opcode(dec_opcode),
					.ex_op_ctrl(dec_op_ctrl),
					.ex_useRd(dec_useRd),
					.ex_useCsr(dec_useCsr),
					.ex_jmp_en(dec_jmp_en),
					.idle(dec_idle),
					.trap(dec_trap),
					.int0_ack(dec_int0_ack),
					.int1_ack(dec_int1_ack),
					.muldiv_act(dec_muldiv_act),
					.csr_addr(dec_csr_addr)
				);
								
	// LHS Shifter
	accum_shifter #( .W(W) ) accum_shft_i (
					.in_accumL(dec_accumL_o),
					.in_accumH(dec_lhs),
					.shft_inVal(~ex_adder_result[W]),
					.mul_load(ex_mLoad),
					.div_load(ex_dLoad),
					.mul_load_val(ex_mul_load_val),
					.div_load_val(ex_div_load_val),
					.mact(ex_mact),
					.dact(ex_dact),
					
					.out_accumL(dec_accumL),
					.out_accumH(dec_accumH)
				);
				
	dec2ex_reg #( .W(W) ) dec2ex_reg_i (					
					.clk1(clk),				// Inactive when dec_stall = 1
					.clk2(clk),				// Inactive if dec_stall = 1 && muldiv = 0
					.clk3(clk),				// Inactive if muldiv = 0
					.clk4(clk),				// Inactive if dec_stall = 1 && trap = 0
					.clk5(clk),
					.clk6(clk),				// Inactive if dec_stall = 1 && stall_mmu = 0
					.a_reset_n(a_reset_n),
					.clk1_en(dec_clk1),
					.clk2_en(dec_clk2),
					.clk3_en(dec_clk3),
					.clk4_en(dec_clk4),
					.clk5_en(dec_clk5),
					.clk6_en(dec_clk6),
					.in_lhs(dec_accumH),
					.in_rhs(dec_rhs),
					.in_accumL(dec_accumL),
					.in_rd(dec_rd),
					.in_csr_addr(dec_csr_addr),
					.in_funct3(dec_funct3),
					.in_opcode(dec_opcode),
					.in_op_ctrl(dec_op_ctrl),
					.in_useRd(dec_useRd),
					.in_useCsr(dec_useCsr),
					.in_jmp_en(dec_jmp_en),
					.in_useRs1(dec_useRs1),
					.in_useRs2(dec_useRs2),
					.in_reg_rs1(rs1_out),
					.in_reg_rs2(rs2_out),
					.in_fwd_sel1(dec_fwd_sel1),
					.in_fwd_sel2(dec_fwd_sel2),
					
					.out_lhs(dec_lhs_o),
					.out_rhs(dec_rhs_o),
					.out_accumL(dec_accumL_o),
					.out_rd(dec_rd_o),
					.out_csr_addr(dec_csr_addr_o),
					.out_funct3(dec_funct3_o),
					.out_opcode(dec_opcode_o),
					.out_op_ctrl(dec_op_ctrl_o),
					.out_useRd(dec_useRd_o),
					.out_useCsr(dec_useCsr_o),
					.out_jmp_en(dec_jmp_en_o),
					.out_useRs1(dec_useRs1_o),
					.out_useRs2(dec_useRs2_o),
					.out_reg_rs1(dec_rs1_o),
					.out_reg_rs2(dec_rs2_o),
					.out_fwd_sel1(dec_fwd_sel1_o),
					.out_fwd_sel2(dec_fwd_sel2_o)
				);
	
	exec_top #( .W(W) ) execute_stage_i (
					.clk(clk),
					.a_reset_n(a_reset_n),
					.in_lhs(dec_lhs_o),
					.in_rhs(dec_rhs_o),
					.reg_rs1(ex_rs1),
					.reg_rs2(ex_rs2),
					.accumL(dec_accumL_o),
					.opcode(dec_opcode_o),
					.op_ctrl(dec_op_ctrl_o),
					.funct3(dec_funct3_o),
					.useRs1(dec_useRs1_o),
					.useRs2(dec_useRs2_o),
					.rd(dec_rd_o),
					.useRd(dec_useRd_o),
					
					.mul_load(ex_mLoad),
					.div_load(ex_dLoad),
					.mul_act(ex_mact),
					.div_act(ex_dact),
					.mul_nop(ex_mul_nop),
					.alu_rslt_mux_sel(ex_alu_rslt_mux_sel),
					.data_sel(ex_data_sel),
					.csr_fwd(ex_csr_fwd),
					.div_load_val(ex_div_load_val),
					.mul_load_val(ex_mul_load_val),
					.adder_result(ex_adder_result),
					.shft_result(ex_shft_result),
					.arth_log_result(ex_arth_log_result),
					.mul_result(ex_mul_result),
					.div_result(ex_div_result),
					.mul_rdy(ex_mul_rdy),
					.div_rdy(ex_div_rdy),
					.out_opcode(ex_opcode),
					.out_rd(ex_rd),
					.out_useRd(ex_useRd),
					.jmp_pc4(ex_jmp_pc4)
	);
	
	// Branch comparator
	comparator #( .W(W) ) br_comp_i	(	.lhs(ex_rs1),
										.rhs(ex_rs2),
										.funct3(dec_funct3_o),
										.br_en(ex_br_en)
									);
									
	ex2mem_reg #( .W(W) ) ex2mem_reg_i (
					.clk1(clk),
					//.clk2(clk),
					.a_reset_n(a_reset_n),
					.clk1_en(ex_clk1),
					.in_result(ex_result),
					.in_data(ex_data),
					.in_rd(ex_rd),
					.in_csr_addr(dec_csr_addr_o),
					.in_funct3(dec_funct3_o),
					.in_opcode(ex_opcode),
					.in_useRd(ex_useRd),
					.in_useCsr(dec_useCsr_o),
					.in_jmp_pc4(ex_jmp_pc4),
					
					.out_result(ex_result_o),
					.out_data(ex_data_o),
					.out_rd(ex_rd_o),
					.out_csr_addr(ex_csr_addr_o),
					.out_funct3(ex_funct3_o),
					.out_opcode(ex_opcode_o),
					//.out_useRd_mst(ex_useRd_mst_o),
					.out_useRd_slv(ex_useRd_slv_o),
					.out_useCsr(ex_useCsr_o),
					.out_jmp_pc4(ex_jmp_pc4_o)
				);
	
	memory_top #( .W(W) ) memory_stage_i (
					.ex_result(ex_result_o),
					.ex_data(ex_data_o),
					.ex_rd(ex_rd_o),
					//.ex_useRd(ex_useRd_slv_o),
					.ex_funct3(ex_funct3_o),
					.ex_opcode(ex_opcode_o),
					.data_in(data_in),
					.pc_4(ex_jmp_pc4_o),
					
					.wb_result(mem_result),
					.data_addr(mem_data_addr),
					.data_out(mem_data_out),
					.width(mem_width),
					.opType(mem_opType)
				);
					
	branch_unit branch_unit_i (
					.clk(clk),
					.a_reset_n(a_reset_n),
					.opcode(ex_opcode),
					.ex_jmp_en(dec_jmp_en_o),
					.ex_br_en(ex_br_en),
					
					.pc_sel(pc_sel),
					.flush(flush_pipe)
				);
				
	stall_unit stall_unit_i (
					.clk(clk),
					.dec_addr1(instruction[19:15]),
					.dec_addr2(instruction[24:20]),
					.ex_rd(dec_rd_o),
					.mem_stalled(core_stall),
					.ex_optype(ex_opcode),
					.ex_useRd(ex_useRd),
					.int0(int0),
					.int1(int1),
					.curr_state(dec_curr_state),
					.muldiv_act(dec_muldiv_act),
					.mul_rdy(ex_mul_rdy),
					.div_rdy(ex_div_rdy),
					.prefetch_cntr(prefetch_cntr),
					
					.dec_stall(stall_dec),
					.dependancy(mem_depend),
					.stall_mmu(stall_mmu),
					.core_sleep(core_sleep),
					.rs1_fwd_sel(dec_fwd_sel1),
					.rs2_fwd_sel(dec_fwd_sel2),
					.dec_intr_en(dec_intr_en)
				);
	
	regfile #( .W(W) ) regfile_i (
					.clk(clk),
					.a_reset_n(a_reset_n),
					.result(mem_result),
					.rd(ex_rd_o),
					//.useRd_mst(ex_useRd_mst_o),
					.useRd_slv(ex_useRd_slv_o),
					.addr1(instruction[19:15]),
					.addr2(instruction[24:20]),
					//.readRs1(dec_readRs1),
					//.readRs2(dec_readRs2),
					
					.rs1(rs1_out),
					.rs2(rs2_out)				
				);
				
	csr_file #( .W(W) ) csr_file_i (
					.clk(clk),
					.a_reset_n(a_reset_n),
					.result(ex_data_o),
					.useCsr(ex_useCsr_o),
					//.readCsr(dec_readCsr),
					.getCsr_addr(dec_csr_addr),
					.putCsr_addr(ex_csr_addr_o),
					
					.csr(csr_out),
					.mtvec_val(mtvec_val),
					.mcause_val(mcause_val),
					.mie(global_ie)
				);
	
	// Prefetch counter and init phase
	always @(posedge clk, negedge a_reset_n) begin
		if (!a_reset_n) init_done <= 0;
		else if (!init_done && prefetch_cntr == 2'b00) init_done <= 1'b1;
	end
	
	always @(posedge clk) begin
		if (!a_reset_n) prefetch_cntr <= PREFETCH_CNT_INIT;
		else if (flush_pipe || dec_idle) prefetch_cntr <= PREFETCH_CNT_BRNCH;
		else if (prefetch_cntr != 2'b00 && !core_stall) prefetch_cntr <= prefetch_cntr - 1;
	end
	
	always @(posedge clk) begin
		mem_depend_reg <= mem_depend;
	end
	
	// pipe_addres reg
	/*
	always @ (clk or ex_adder_result) begin
		if (!clk) begin
			pipe_addres <= ex_adder_result;
		end
	end
	*/
	// --- Execute stage ---
	// Data mux
	always @* begin
		case (ex_data_sel)
			2'b01	: ex_data = ex_result;
			2'b10	: ex_data = dec_lhs_o;
			2'b11	: ex_data = ex_rs1;
			default	: ex_data = ex_rs2;
		endcase
	end
	// ALU result mux
	always @* begin
        case (ex_alu_rslt_mux_sel)
            2'b01  	:   ex_result_inter = ex_shft_result;
            2'b10  	:   ex_result_inter = ex_mul_result;
            2'b11  	:   ex_result_inter = ex_div_result;
            default :   ex_result_inter = ex_arth_log_result;
        endcase
    end
	
endmodule
