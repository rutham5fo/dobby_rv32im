`timescale 1ns/10ps

module ctrl_unit #( parameter W = 32 )
				(	input			clk,
					input			a_reset_n,
					input	[6:0]	opcode,
					input	[2:0]	funct3,
					input	[11:0]	funct12,
					input	[4:0]	rd,
					input	[4:0]	rs1,
					input			mul_div,	// funct7[0]
					input			in_mul_rdy,
					input			in_div_rdy,
					input			int0,		// Interrupt 0 (higher priority)
					input			int1,		// Interrupt 1
					input			mcause_msb,
					input	[1:0]	mtvec_lsb,
					input			we,
					input	[W-1:0]	pc_4,
					input			intr_en,
					
					output	[2:0]	curr_state,
					output			useRd_out,
					output			useCsr,
					output			idle,
					//output			readCsr,
					output	[1:0]	mux_lhs_sel,
					output	[1:0]	mux_rhs_sel,
					output			jmp_en,
					output			trap,
					output			int0_ack,
					output			int1_ack,
					output	[W-1:0]	csr_data,
					output	[2:0]	csr_addr,
					output	[3:0]	out_opcode,
					output			muldiv_act,
					output			useRs1,
					output			useRs2
					//output			readRs1,
					//output			readRs2
				);
				
	// DEC opcodes
	localparam	LUI			= 7'b0110111;
	localparam	AUIPC		= 7'b0010111;
	localparam	JAL			= 7'b1101111;
	localparam	JALR		= 7'b1100111;
	localparam	BRANCH		= 7'b1100011;
	localparam	MEM_LOAD	= 7'b0000011;
	localparam	MEM_STORE	= 7'b0100011;
	localparam	OP_IMM		= 7'b0010011;
	localparam	OP			= 7'b0110011;
	localparam	SYSTEM		= 7'b1110011;
	
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
	localparam	ALU_FWDREG	= 4'b1000;
	// Misc
	localparam	ALU_ADD		= 4'b1000;
	localparam	OPT_STORE	= 4'b1001;
	localparam	OPT_LOAD	= 4'b1010;
	localparam	OPT_BRANCH	= 4'b1011;
	localparam	OPT_MTVEC	= 4'b1100;
	
	// BRANCH codes
	localparam	BEQ		= 3'b000; 
	localparam	BNE		= 3'b001;
	localparam	BLT		= 3'b100;
	localparam	BGE		= 3'b101;
	localparam	BLTU	= 3'b110;
	localparam	BGEU	= 3'b111;

	// OP codes
	localparam	ADD_SUB		= 3'b000;              // Add or Sub determined by instruction[30]
	localparam	SLL			= 3'b001;
	localparam	SLT			= 3'b010;
	localparam	SLTU		= 3'b011;
	localparam	XOR			= 3'b100;
	localparam	SRL_SRA		= 3'b101;              // Arithmatic or logical shift is determined by instruction[30]
	localparam	OR			= 3'b110;
	localparam	AND			= 3'b111;
	
	//SYSTEM codes
	localparam	CSRRW	= 3'b001;
	localparam	CSRRS	= 3'b010;
	localparam	CSRRC	= 3'b011;
	localparam	CSRRWI	= 3'b101;
	localparam	CSRRSI	= 3'b110;
	localparam	CSRRCI	= 3'b111;
	
	// Priviliged Instruction codes
	localparam	MRET	= 12'h302;
	localparam	WFI		= 12'h105;
	
	// Exception Codes
	localparam	ILLEGAL_INST	= 32'h00000002;
	localparam	EXT_INTERRUPT_0	= 32'h80000000;
	localparam	EXT_INTERRUPT_1	= 32'h80000002;
	localparam	SET_MIE				= 32'h00001808;
	localparam	CLR_MIE				= 32'h00001880;
						
	// M extension      
	localparam	MUL		= 3'b000;
	localparam	MULH	= 3'b001;
	localparam	MULHSU	= 3'b010;
	localparam	MULHU	= 3'b011;
	localparam	DIV		= 3'b100;
	localparam	DIVU	= 3'b101;
	localparam	REM		= 3'b110;
	localparam	REMU	= 3'b111;
	
	// FSM states
	localparam	INST				= 3'b000;			// Default state
	localparam	MULDIV				= 3'b001;
	localparam	TRAP_MSTATUS_CLR	= 3'b010;
	localparam	TRAP_MEPC_SET		= 3'b011;
	localparam	TRAP_MTVEC			= 3'b100;
	localparam	TRAP_MSTATUS_SET	= 3'b101;
	localparam	PRE_SLEEP			= 3'b110;
	localparam	SLEEP				= 3'b111;
	
	// CSR addresses
	localparam	MSTATUS	= 12'h300;
	localparam	MISA	= 12'h301;
	localparam	MTVEC	= 12'h305;
	localparam	MEPC	= 12'h341;
	localparam	MCAUSE	= 12'h342;
	// Mapped CSR addresses
	localparam	MAP_MSTATUS	= 3'd0;
	localparam	MAP_MISA	= 3'd1;
	localparam	MAP_MTVEC	= 3'd2;
	localparam	MAP_MEPC	= 3'd3;
	localparam	MAP_MCAUSE	= 3'd4;

	reg			idle;
	reg			useRd;
	reg			useCsr;
	//reg			readCsr;
	reg	[1:0]	mux_lhs_sel;
	reg	[1:0]	mux_rhs_sel;
	reg			useRs1;
	reg			useRs2;
	//reg			readRs1;
	//reg			readRs2;
	reg			jmp_en;
	reg			int0_ack;
	reg			int1_ack;
	reg			int0_ack_drv;
	reg			int1_ack_drv;
	reg	[W-1:0]	csr_data;
	reg	[2:0]	csr_addr;
	reg	[3:0]	out_opcode;
	reg			muldiv_act;
	reg			trap;
	reg	[2:0]	mapped_csr_addr;
	
	// Regs
	reg	[2:0]	curr_state;
	reg	[2:0]	next_state;
	
	wire		cState_en;
	
	// DONT Raise illegal instruction when rd = 0, since any arithmatic instruction with rd = x0 is considered NOP
	assign useRd_out = (useRd && !rd) ? 1'b0 : useRd;
	
	assign cState_en = (next_state != curr_state);
	
	always @(posedge clk) begin
		int0_ack <= int0_ack_drv;
		int1_ack <= int1_ack_drv;
	end
	
	// FSM
	always @(posedge clk or negedge a_reset_n) begin
		if(!a_reset_n) curr_state <= INST;
		else if (cState_en) curr_state <= next_state;
	end

	always @* begin	: control_block
	
		useRd = 1'b0;
		useCsr = 1'b0;
		//readCsr = 1'b0;
		mux_lhs_sel = 1'b0;
		mux_rhs_sel = 1'b0;
		jmp_en = 1'b0;
		int0_ack_drv = 1'b0;
		int1_ack_drv = 1'b0;
		csr_data = { {27{1'b0}}, rs1 };
		csr_addr = mapped_csr_addr;
		out_opcode = 1'b0;
		muldiv_act = 1'b0;
		useRs1 = 1'b0;
		useRs2 = 1'b0;
		//readRs1 = 1'b0;
		//readRs2 = 1'b0;
		idle = 1'b0;
		trap = 1'b0;
		next_state = curr_state;
		
		case (curr_state)
			INST	: begin
				if (we && !intr_en) begin			// If we is false, instruction is dropped (in the case of stall also drop inst) and no changes are made to default signals. This ensures br_en is at zero
					case (opcode)
						LUI	: begin
							out_opcode = ALU_FWDASS;
							useRd = 1'b1;
							mux_rhs_sel = 2'd0;
						end
						AUIPC	: begin
							out_opcode = ALU_OPI;
							useRd = 1'b1;
							mux_lhs_sel = 2'd0;
							mux_rhs_sel = 2'd0;
						end
						JAL	: begin
							//out_opcode = ALU_ADD;
							out_opcode = OPT_BRANCH;
							useRd = 1'b1;
							mux_lhs_sel = 2'd0;
							mux_rhs_sel = 2'd0;
							jmp_en = 1'b1;
						end
						JALR	: begin
							out_opcode = OPT_BRANCH;
							useRd = 1'b1;
							mux_rhs_sel = 2'd0;
							useRs1 = 1'b1;
							//readRs1 = 1'b1;
							jmp_en = 1'b1;
						end
						BRANCH	: begin
							out_opcode = OPT_BRANCH;
							mux_lhs_sel = 2'd0;
							mux_rhs_sel = 2'd0;
							//readRs1 = 1'b1;
							//readRs2 = 1'b1;
						end
						MEM_LOAD	: begin
							out_opcode = OPT_LOAD;
							useRd = 1'b1;
							mux_rhs_sel = 2'd0;
							useRs1 = 1'b1;
							//readRs1 = 1'b1;
						end
						MEM_STORE	: begin
							out_opcode = OPT_STORE;
							mux_rhs_sel = 2'd0;
							useRs1 = 1'b1;
							//readRs1 = 1'b1;
							//readRs2 = 1'b1;
						end
						OP_IMM		: begin
							out_opcode = ALU_OPI;
							useRd = 1'b1;
							mux_rhs_sel = 2'd0;
							useRs1 = 1'b1;
							//readRs1 = 1'b1;
						end
						OP			: begin
							useRs1 = 1'b1;
							useRs2 = 1'b1;
							//readRs1 = 1'b1;
							//readRs2 = 1'b1;
							if (mul_div) begin
								out_opcode = ALU_LD;
								muldiv_act = 1'b1;
								next_state = MULDIV;
							end
							else begin
								out_opcode = ALU_OP;
								useRd = 1'b1;
							end
						end
						SYSTEM	: begin
							//readCsr = 1'b1;
							mux_rhs_sel = 2'd1;
							case (funct3)
								CSRRW, CSRRWI	: begin
									// res = CSR_reg and CSR_reg = lhs (rs1)
									out_opcode = ALU_FWDREG;
									useRd = (rd) ? 1'b1 : 1'b0;
									useCsr = 1'b1;
									if (funct3 == CSRRWI) begin
										mux_lhs_sel = 2'd1;
									end
									else begin
										useRs1 = 1'b1;
									end
								end
								CSRRC, CSRRCI	: begin									// res = CSR_reg and CSR_reg &= !lhs (rs1)
									// lhs | rhs
									out_opcode = ALU_CSRRC;
									useRd = (rd) ? 1'b1 : 1'b0;
									useCsr = (rs1) ? 1'b1 : 1'b0;
									if (funct3 == CSRRCI) begin
										mux_lhs_sel = 2'd1;
									end
									else begin
										useRs1 = 1'b1;
									end
								end
								CSRRS, CSRRSI	: begin									// res = CSR_reg and CSR_reg |= lhs (rs1)
									// lhs & !rhs
									out_opcode = ALU_CSRRS;
									useRd = (rd) ? 1'b1 : 1'b0;
									useCsr = (rs1) ? 1'b1 : 1'b0;
									if (funct3 == CSRRSI) begin
										mux_lhs_sel = 2'd1;
									end
									else begin
										useRs1 = 1'b1;
									end
								end
								default	: begin
									case (funct12)
										MRET	: begin									// CSR_reg = CSR_reg bit swap and data reg manipulation
											// set nextpc to mepc and bits in mstatus reg
											// Order of operations is important for proper pipeline timing
											out_opcode = ALU_FWDASS;
											jmp_en = 1'b1;
											mux_rhs_sel = 2'd1;
											csr_addr = MAP_MEPC;
											next_state = TRAP_MSTATUS_SET;
										end
										WFI		: begin									// CSR_reg += lhs and data reg manipulation
											// Stall the hart till an interrupt occurs
											out_opcode = ALU_FWDASS;
											useCsr = 1'b1;
											mux_lhs_sel = 2'd1;			// Set MEPC = pc + 4
											trap = 1'b1;
											csr_data = pc_4;
											csr_addr = MAP_MEPC;
											next_state = PRE_SLEEP;
										end
										default	: begin
											out_opcode = ALU_FWDASS;
											useCsr = 1'b1;
											mux_lhs_sel = 2'd1;
											trap = 1'b1;
											csr_data = ILLEGAL_INST;
											csr_addr = MAP_MCAUSE;
											next_state = TRAP_MEPC_SET;
										end
									endcase
								end
							endcase
						end
						default	: begin
							if (a_reset_n) begin
								out_opcode = ALU_FWDASS;
								useCsr = 1'b1;
								mux_lhs_sel = 2'd1;
								mux_rhs_sel = 2'd1;
								trap = 1'b1;
								csr_data = ILLEGAL_INST;
								csr_addr = MAP_MCAUSE;
								next_state = TRAP_MEPC_SET;
							end
						end
					endcase
				end
				else if (intr_en) begin
					out_opcode = ALU_FWDASS;
					useCsr = 1'b1;
					mux_lhs_sel = 2'd1;
					mux_rhs_sel = 2'd1;
					trap = 1'b1;
					csr_addr = MAP_MCAUSE;
					csr_data = (int0) ? EXT_INTERRUPT_0 : EXT_INTERRUPT_1;
					next_state = TRAP_MEPC_SET;
				end
				// DONT Raise illegal instruction when rd = 0, since any arithmatic instruction with rd = x0 is considered NOP
			end
			MULDIV	: begin
				out_opcode = (in_mul_rdy || in_div_rdy) ? ALU_ST : ALU_ACT;
				muldiv_act = 1'b1;
				mux_lhs_sel = 2'd2;
				useRs2 = 1'b1;
				useRd = (in_mul_rdy || in_div_rdy) ? 1'b1 : 1'b0;
				next_state = (in_mul_rdy || in_div_rdy) ? INST : curr_state;
				// Mul Control --> taken care by mul_op_val, mul_shft and mul_nop_val in exec_top
				// Div Control --> taken care by adder_res MSB and div_act in mux_restore_sel
			end
			TRAP_MSTATUS_CLR	: begin							// CSR_reg = CSR_reg bit swap and data reg manipulation
				// Disable MIE and set other relevant bits in mstatus
				out_opcode = ALU_FWDASS;
				useCsr = 1'b1;
				trap = 1'b1;
				mux_lhs_sel = 2'd1;
				mux_rhs_sel = 2'd1;
				csr_data = CLR_MIE;
				csr_addr = MAP_MSTATUS;
				next_state = TRAP_MTVEC;
				// Interrupt 0 has higher priority
				if (int0) int0_ack_drv = 1'b1;
				else if (int1) int1_ack_drv = 1'b1;
			end
			TRAP_MEPC_SET	: begin								// CSR_reg = lhs and data reg manipulation
				// Save current pc to mepc
				out_opcode = ALU_FWDASS;
				useCsr = 1'b1;
				trap = 1'b1;
				mux_lhs_sel = 2'd0;
				mux_rhs_sel = 2'd1;
				csr_addr = MAP_MEPC;
				next_state = TRAP_MSTATUS_CLR;
			end
			TRAP_MTVEC		: begin							// res = CSR_reg
				// Jump to mtvec base or mepc - jump address computed from mtvec in alu						
				jmp_en = 1'b1;
				next_state = INST;
				if (mtvec_lsb == 2'b01 && mcause_msb) begin
					// Async Vector Interrupt mode
					out_opcode = OPT_MTVEC;
					mux_lhs_sel = 2'd3;
					mux_rhs_sel = 2'd2;
				end
				else begin
					// Sync/base mode
					out_opcode = ALU_FWDASS;
					mux_rhs_sel = 2'd2;
				end
			end
			TRAP_MSTATUS_SET	: begin
				out_opcode = ALU_FWDASS;
				useCsr = 1'b1;
				mux_lhs_sel = 2'd1;
				mux_rhs_sel = 2'd1;
				csr_data = SET_MIE;
				csr_addr = MAP_MSTATUS;
				next_state = INST;
			end
			PRE_SLEEP	: begin
				// Assert Idle and go to sleep
				idle = 1'b1;
				next_state = SLEEP;
			end
			SLEEP	: begin
				// Wake on interrupt, start at mepc
				// Interrupt 0 has higher priority
				if (intr_en) begin
					out_opcode = ALU_FWDASS;
					jmp_en = 1'b1;
					mux_rhs_sel = 2'd1;
					csr_addr = MAP_MEPC;
					next_state = INST;
					if (int0) int0_ack_drv = 1'b1;
					else int1_ack_drv = 1'b1;
				end
			end
		endcase
	end
	
	// CSR_ADDR mapper
	always @* begin
		case (funct12)
			MISA		: mapped_csr_addr = MAP_MISA;
			MTVEC		: mapped_csr_addr = MAP_MTVEC;
			MEPC		: mapped_csr_addr = MAP_MEPC;
			MCAUSE		: mapped_csr_addr = MAP_MCAUSE;
			default		: mapped_csr_addr = MAP_MSTATUS;
		endcase
	end

endmodule
