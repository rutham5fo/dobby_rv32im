// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   csr_file.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Thu Mar 10 01:15:39 2022 
// Last Change       :   $Date$
// by                :   $Author$                  			
//------------------------------------------------------------
`timescale 1ns/10ps

module csr_file #( parameter W = 32, parameter R = 3, parameter NUM_CSRS = 5 )
			(
				input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input			useCsr,
				input	[R-1:0]	getCsr_addr,
				input	[R-1:0]	putCsr_addr,
				
				output	[W-1:0]	csr,
				output	[W-1:0]	mtvec_val,
				output	[W-1:0]	mcause_val,
				output			mie				// Used to globally enable/disable interrupts. Connected to enable of interrupt tri-state buffers at top_level.
			);
			
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
	
	localparam	MSTATUS_INIT_VAL	= 32'h00001808;
	localparam	MISA_INIT_VAL		= 32'h40000880;
	localparam	MTVEC_INIT_VAL		= 32'h00000001;
	localparam	GEN_INIT_VAL		= 32'h0;
	localparam	INIT_VAL_PARAM		= {GEN_INIT_VAL, GEN_INIT_VAL, MTVEC_INIT_VAL, MISA_INIT_VAL, MSTATUS_INIT_VAL};
	
	integer				i;
	
	reg		[W-1:0]		csrs	[0:NUM_CSRS-1];
	
	assign mie = csrs[0][3];
	assign mtvec_val = csrs[2];
	assign mcause_val = csrs[4];
	
	assign csr = csrs[getCsr_addr];
	
	always @(negedge clk, negedge a_reset_n) begin
		if (!a_reset_n) begin
			for (i = 0; i < NUM_CSRS; i = i+1) csrs[i] <= INIT_VAL_PARAM[i*W +: W];
		end
		else if (useCsr) csrs[putCsr_addr] <= result;
	end
	
endmodule

/*
//------------------ BEGIN >> Latch based -------------------------------
module csr_file #( parameter W = 32, parameter R = 3, parameter NUM_CSRS = 5 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input			useCsr,
				input	[R-1:0]	getCsr_addr,
				input	[R-1:0]	putCsr_addr,
				
				output	[W-1:0]	csr,
				output	[W-1:0]	mtvec_val,
				output	[W-1:0]	mcause_val,
				output			mie				// Used to globally enable/disable interrupts. Connected to enable of interrupt tri-state buffers at top_level.
			);

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
	
	localparam	MSTATUS_INIT_VAL	= 32'h00001808;
	localparam	MISA_INIT_VAL		= 32'h40000880;
	localparam	MTVEC_INIT_VAL		= 32'h00000001;
	localparam	GEN_INIT_VAL		= 32'h0;
	localparam	INIT_VAL_PARAM		= {GEN_INIT_VAL, GEN_INIT_VAL, MTVEC_INIT_VAL, MISA_INIT_VAL, MSTATUS_INIT_VAL};
	
	wire						reset_cond;
	wire						reset_dly;
	wire						mst_gclk;
	wire	[NUM_CSRS-1:0]		slv_clk_en;
	wire	[NUM_CSRS-1:0]		slv_gclk;
	wire	[W-1:0]				mst_out;
	wire	[W-1:0]				slv_out [0:NUM_CSRS-1];
	wire	[W-1:0]				latch_data [0:NUM_CSRS-1];
	
	// --------------- CSR regs -------------------
	// csrs[0] = MSTATUS
	// csrs[1] = MISA
	// csrs[2] = MTVEC
	// csrs[3] = MEPC
	// csrs[4] = MCAUSE
	// --------------- END -------------------
	
	genvar i;
	
	assign mie = slv_out[0][3];
	assign mtvec_val = slv_out[2];
	assign mcause_val = slv_out[4];
	
	// Async reset reaches the latch_in mux, earlier than slv_gclk 1 -> 0.
	// Hence the slave latches are transparent for a brief moment
	// during which the reset val is replaced with data val.
	// To avoid this, delay the a_reset_n signal by combinational circuit.
	assign reset_cond = |slv_gclk & ~useCsr;
	assign reset_dly = (~a_reset_n || reset_cond) ? 1'b0 : 1'b1;
	
	assign mst_gclk = useCsr & ~|slv_gclk;
	assign slv_clk_en = (5'b00001 << putCsr_addr) & { NUM_CSRS{useCsr} };
	assign slv_gclk = (slv_clk_en & { NUM_CSRS{~clk} }) | { NUM_CSRS{~a_reset_n} };
	
	assign csr = slv_out[getCsr_addr];
	
	generate
		for (i = 0; i < NUM_CSRS; i = i+1) begin	: csrfile_slave_latch
		
			assign latch_data[i] = (!reset_dly) ? INIT_VAL_PARAM[i*W +: W] : mst_out;
			
			latch #( .W(W) ) csr_slave_reg_i (
										.en(slv_gclk[i]),
										.data(latch_data[i]),
										
										.Q(slv_out[i])
									);
		end
	endgenerate
	
	latch #( .W(W) ) csr_slave_reg_i (
										.en(mst_gclk),
										.data(result),
										
										.Q(mst_out)
									);
									
endmodule
*/
//------------------ BEGIN >> Latch based + Datapath Gating -------------------------------
/*
module csr_file #( parameter W = 32, parameter R = 3, parameter NUM_CSRS = 5 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input			useCsr,
				//input			readCsr,
				input	[R-1:0]	getCsr_addr,
				input	[R-1:0]	putCsr_addr,
				
				output	[W-1:0]	csr,
				output	[W-1:0]	mtvec_val,
				output	[W-1:0]	mcause_val,
				output			mie				// Used to globally enable/disable interrupts. Connected to enable of interrupt tri-state buffers at top_level.
			);

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
	
	localparam	MSTATUS_INIT_VAL	= 32'h00001808;
	localparam	MISA_INIT_VAL		= 32'h40000880;
	localparam	MTVEC_INIT_VAL		= 32'h00000001;
	localparam	GEN_INIT_VAL		= 32'h0;
	localparam	INIT_VAL_PARAM		= {GEN_INIT_VAL, GEN_INIT_VAL, MTVEC_INIT_VAL, MISA_INIT_VAL, MSTATUS_INIT_VAL};
	
	//reg		[R-1:0]				csr_addr;
	
	wire						reset_cond;
	wire						reset_dly;
	wire						mst_clk_en;
	wire						mst_gclk;
	wire						mst_gen_o;
	wire	[NUM_CSRS-1:0]		slv_clk_en;
	wire	[NUM_CSRS-1:0]		slv_gclk;
	wire	[NUM_CSRS-1:0]		slv_gen_o;
	wire	[W-1:0]				mst_out;
	wire	[W-1:0]				slv_out [0:NUM_CSRS-1];
	//wire	[R-1:0]				csr_gaddr;
	
	// --------------- CSR regs -------------------
	// csrs[0] = MSTATUS
	// csrs[1] = MISA
	// csrs[2] = MTVEC
	// csrs[3] = MEPC
	// csrs[4] = MCAUSE
	// --------------- END -------------------
	
	genvar i;
	
	assign mie = slv_out[0][3];
	assign mtvec_val = slv_out[2];
	assign mcause_val = slv_out[4];
	
	// Async reset reaches the latch_in mux, earlier than slv_gclk 1 -> 0.
	// Hence the slave latches are transparent for a brief moment
	// during which the reset val is replaced with data val.
	// To avoid this, delay the a_reset_n signal by combinational circuit.
	assign reset_cond = |slv_gen_o & ~useCsr;
	assign reset_dly = (~a_reset_n || reset_cond) ? 1'b0 : 1'b1;
	
	assign mst_clk_en = useCsr & ~|slv_gen_o;
	assign mst_gclk = mst_clk_en & clk;
	assign slv_clk_en = (useCsr) ? 5'b00001 << putCsr_addr : 1'b0;
	assign slv_gclk = slv_clk_en & { NUM_CSRS{~clk} };
	
	//assign csr_gaddr = getCsr_addr & { R{readCsr} };
	assign csr = slv_out[getCsr_addr];
	
	generate
		for (i = 0; i < NUM_CSRS; i = i+1) begin	: csrfile_slave_latch
			latch #( .W(W), .V(INIT_VAL_PARAM[i*W +: W]) ) csr_slave_reg_i (
										.en(slv_gclk[i]),
										.a_reset_n(a_reset_n),
										.reset_dly(reset_dly),
										.data(mst_out),
										
										.G_EN(slv_gen_o[i]),
										.Q(slv_out[i])
									);
		end
	endgenerate
	
	latch #( .W(W), .V(0) ) csr_master_reg_i (
		.en(mst_gclk),
		.a_reset_n(a_reset_n),
		.reset_dly(reset_dly),
		.data(result),
		
		.G_EN(mst_gen_o),
		.Q(mst_out)
	);
	
	//always @(clk, getCsr_addr) begin
	//	if (!clk) csr_addr <= getCsr_addr;
	//end
	
endmodule
*/

/*
//------------------ BEGIN >> Slave-Latch base with No Master -------------------------------
module csr_file #( parameter W = 32, parameter R = 3, parameter NUM_CSRS = 5 )
			(	input			clk,
				input			a_reset_n,
				input	[W-1:0]	result,
				input			useCsr,
				input	[R-1:0]	getCsr_addr,
				input	[R-1:0]	putCsr_addr,
				
				output	[W-1:0]	csr,
				output	[W-1:0]	mtvec_val,
				output	[W-1:0]	mcause_val,
				output			mie				// Used to globally enable/disable interrupts. Connected to enable of interrupt tri-state buffers at top_level.
			);

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
	
	localparam	MSTATUS_INIT_VAL	= 32'h00001808;
	localparam	MISA_INIT_VAL		= 32'h40000880;
	localparam	MTVEC_INIT_VAL		= 32'h00000001;
	localparam	GEN_INIT_VAL		= 32'h0;
	localparam	INIT_VAL_PARAM		= {GEN_INIT_VAL, GEN_INIT_VAL, MTVEC_INIT_VAL, MISA_INIT_VAL, MSTATUS_INIT_VAL};
	
	wire						reset_cond;
	wire						reset_dly;
	wire						mst_clk_en;
	wire						mst_gclk;
	wire						mst_gen_o;
	wire	[NUM_CSRS-1:0]		slv_clk_en;
	wire	[NUM_CSRS-1:0]		slv_gclk;
	wire	[NUM_CSRS-1:0]		slv_gen_o;
	wire	[W-1:0]				mst_out;
	wire	[W-1:0]				slv_out [0:NUM_CSRS-1];
	wire	[W-1:0]				latch_data [0:NUM_CSRS-1];
	
	// --------------- CSR regs -------------------
	// csrs[0] = MSTATUS
	// csrs[1] = MISA
	// csrs[2] = MTVEC
	// csrs[3] = MEPC
	// csrs[4] = MCAUSE
	// --------------- END -------------------
	
	genvar i;
	
	assign mie = slv_out[0][3];
	assign mtvec_val = slv_out[2];
	assign mcause_val = slv_out[4];
	
	// Async reset reaches the latch_in mux, earlier than slv_gclk 1 -> 0.
	// Hence the slave latches are transparent for a brief moment
	// during which the reset val is replaced with data val.
	// To avoid this, delay the a_reset_n signal by combinational circuit.
	assign reset_cond = |slv_gclk & ~useCsr;
	assign reset_dly = (~a_reset_n || reset_cond) ? 1'b0 : 1'b1;
	
	assign slv_clk_en = 5'b00001 << putCsr_addr;
	assign slv_gclk = (slv_clk_en & { NUM_CSRS{useCsr} } & { NUM_CSRS{clk} }) | { NUM_CSRS{~a_reset_n} };
	
	assign csr = slv_out[getCsr_addr];
	
	generate
		for (i = 0; i < NUM_CSRS; i = i+1) begin	: csrfile_slave_latch
		
			assign latch_data[i] = (!reset_dly) ? INIT_VAL_PARAM[i*W +: W] : result;
			
			latch #( .W(W) ) csr_slave_reg_i (
										.en(slv_gclk[i]),
										.data(latch_data[i]),
										
										.Q(slv_out[i])
									);
		end
	endgenerate
	
endmodule
*/
