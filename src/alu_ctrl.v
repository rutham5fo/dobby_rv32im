`timescale 1ns/10ps

module alu_ctrl #(  parameter W = 32 )
                (   input   [2:0]   funct3,
                    input   [3:0]   opcode,             // encoded alu opcode
					input	[4:0]	rd,
					input			useRd,
					
					output			inv_rhs,
					output			shft_dir,
					output	[1:0]	alu_rslt_mux_sel,
					output			mul_load,
					output			div_load,
					output			mact,
					output			dact,
					output			mul_res_sel,
					output			div_res_sel,
					output	[1:0]	data_sel,
					output			csr_fwd,
					output	[2:0]	arth_out_sel,
					output	[1:0]	out_opcode,
					output	[4:0]	out_rd,
					output			out_useRd
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
	localparam	ALU_FWDREG	= 4'b1000;
	// Misc
	localparam	OPT_STORE	= 4'b1001;
	localparam	OPT_LOAD	= 4'b1010;
	localparam	OPT_BRANCH	= 4'b1011;
	localparam	OPT_MTVEC	= 4'b1100;
	
	// OP codes
	localparam	ADD_SUB		= 3'b000;              // Add or Sub determined by instruction[30]
	localparam	SLL			= 3'b001;
	localparam	SLT			= 3'b010;
	localparam	SLTU		= 3'b011;
	localparam	XOR			= 3'b100;
	localparam	SRL_SRA		= 3'b101;              // Arithmatic or logical shift is determined by instruction[30]
	localparam	OR			= 3'b110;
	localparam	AND			= 3'b111;
                    
	// M extension      
	localparam	MUL		= 3'b000;
	localparam	MULH	= 3'b001;
	localparam	MULHSU	= 3'b010;
	localparam	MULHU	= 3'b011;
	localparam	DIV		= 3'b100;
	localparam	DIVU	= 3'b101;
	localparam	REM		= 3'b110;
	localparam	REMU	= 3'b111;
	
	// ALU signals and regs
    reg     [1:0]   alu_rslt_mux_sel;
	reg		[1:0]	data_sel;
	reg				csr_fwd;
	reg		[1:0]	out_opcode;
	reg		[4:0]	out_rd;
	reg				out_useRd;
    
    // Shift unit signals
    reg             shft_dir;
    
    // Arth_log_unit signals
    reg             inv_rhs;
	reg		[2:0]	arth_out_sel;
    
    // Multiply unit signals
    reg             mul_load;
	reg				mact;
   
    // Division unit signals
    reg             div_load;
	reg				dact;
	
	//assign out_op_ctrl = in_op_ctrl;
	assign mul_res_sel = (funct3 == MUL) ? 1'b0 : 1'b1;
	assign div_res_sel = (funct3 == DIV || funct3 == DIVU) ? 1'b0 : 1'b1;
	 
    // ALU Control signal generation logic
    always @* begin
	
        inv_rhs = 1'b0;
        shft_dir = 1'b0;
        alu_rslt_mux_sel = 1'b0;
        mul_load = 1'b0;
        div_load = 1'b0;
		mact = 1'b0;
		dact = 1'b0;
		data_sel = 1'b0;
		csr_fwd = 1'b0;
		arth_out_sel = 1'b0;
		out_opcode = 1'b0;
		out_rd = rd;
		out_useRd = useRd;
		
		case (opcode)
			ALU_OP, ALU_OPI	: begin
				case (funct3)
					ADD_SUB    : begin                                     // Perform lhs +/- rhs depending on op_ctrl
						arth_out_sel = 3'b001;
					end
					SLT, SLTU	: begin
						arth_out_sel = (funct3 == SLT) ? 3'b010 : 3'b011;
					end
					SLL        : begin                                     // (logical) lhs << shamt
						alu_rslt_mux_sel = 2'b01;
					end
					XOR        : begin                                     // lhs ^ rhs
						arth_out_sel = 3'b000;
					end
					SRL_SRA    : begin                                     // lhs >> shamt; logical or arithmatic determined by op_ctrl
						shft_dir = 1'b1;
						alu_rslt_mux_sel = 2'b01;
					end
					OR         : begin                                     // (lhs & ~rhs) ^ rhs
						arth_out_sel = 3'b101;
					end
					AND        : begin                                     // lhs & rhs
						arth_out_sel = 3'b100;
					end
				endcase
			end
			ALU_LD		: begin
				case (funct3)
					DIV, DIVU, REM, REMU          : begin
						div_load = 1'b1;
					end
					default	: mul_load = 1'b1;
				endcase
			end
			ALU_ST		: begin
				alu_rslt_mux_sel = (funct3[2]) ? 2'b11 : 2'b10;
			end
			ALU_ACT		: begin
				case (funct3)
					DIV, DIVU, REM, REMU	: dact = 1'b1;
					default					: mact = 1'b1;
				endcase
			end
			ALU_FWDASS	: begin
				csr_fwd = 1'b1;
				data_sel = 2'b10;
			end
			ALU_CSRRC	: begin
				// lhs & !rhs
				inv_rhs = 1'b1;
				arth_out_sel = 3'b100;
				data_sel = 2'b01;
			end
			ALU_CSRRS	: begin
				// lhs | rhs
				arth_out_sel = 3'b101;
				csr_fwd = 1'b1;
				data_sel = 2'b01;
			end
			ALU_FWDREG	: begin
				csr_fwd = 1'b1;
				data_sel = 2'b11;
			end
			OPT_STORE	: begin
				arth_out_sel = 3'b001;
				out_opcode = 2'b01;
			end
			OPT_LOAD	: begin
				arth_out_sel = 3'b001;
				out_opcode = 2'b10;
			end
			OPT_BRANCH	: begin
				arth_out_sel = 3'b001;
				out_opcode = 2'b11;
			end
			default	: begin					// opcode OPT_MTVEC maps here
				arth_out_sel = 3'b001;
			end
        endcase
    end

endmodule
