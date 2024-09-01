// Company           :   tud                      
// Author            :   baam21            
// E-Mail            :   <email>                    
//                    			
// Filename          :   tb_soc_top.v                
// Project Name      :   prz    
// Subproject Name   :   gf28_template    
// Description       :   <short description>            
//
// Create Date       :   Sun Sep  3 17:42:53 2023 
// Last Change       :   $Date: 2023-09-14 02:57:46 +0200 (Thu, 14 Sep 2023) $
// by                :   $Author: baam21 $                  			
//------------------------------------------------------------
`timescale 1ns/10ps
module tb_soc_top;
	parameter CLK_PERIOD        		= 10;
    //parameter MAX_INIT_ADDR     		= 32'd900;
    parameter MAX_INIT_ADDR     		= 32'h3fff;
	parameter MAX_EXT_SRAM_SIZE 		= 4096;
	parameter MAX_EXT_SRAM_SIZE_BYTES	= 32768;
	parameter EXT_DMEM_BEG				= 16384;			// External DMEM is set to 0x00004000
	//parameter EXT_DMEM_BEG				= 0;
	//parameter MAX_EXT_SRAM_SIZE_BYTES	= 200;
    parameter EXT_MEM_FILE      		= "progmem/core.mem";
    //parameter EXT_BASE_ADDR     		= 65536;            // 0x10000 - to force external ram access
    //parameter PRAM_SEL          		= 1;
    //parameter PRAM_OFFSET       		= 4 * (1024 * (PRAM_SEL-1));
    //parameter MAX_CYCLES        		= 3000;               // 0 = run till finish is called
	parameter MAX_CYCLES        		= 0;               // 0 = run till finish is called
    parameter SIGNAL_DLY				= 3;
	//parameter INTR_0_CYCLE				= 1451;				// Interrupt 0 will be asserted in this cycle
	//parameter INTR_1_CYCLE				= 1534;				// Interrupt 1 will be asserted in this cycle
	//parameter INTR_0_CYCLE				= 16451;				// Interrupt 0 will be asserted in this cycle
	//parameter INTR_1_CYCLE				= 16534;				// Interrupt 1 will be asserted in this cycle
	parameter INTR_0_CYCLE				= 12751;				// Interrupt 0 will be asserted in this cycle
	parameter INTR_1_CYCLE				= 13000;				// Interrupt 1 will be asserted in this cycle
	
	parameter SRAM_ADDR_WIDTH 			= 10;
    parameter SRAM_DATA_WIDTH 			= 128;
	
    reg                     clk;
    reg                     reset_n;
    reg                     slv_bus_rdy;
    reg     [1:0]           slv_intr_req_o;
    reg     [31:0]          slv_bus_out;
	
	reg						init_done;
    
    // Memory
    //reg     [31:0]          ext_sram [0:MAX_EXT_SRAM_SIZE-1];
	reg		[7:0]			ext_sram_bytes [0:MAX_EXT_SRAM_SIZE_BYTES-1];
    
	wire					core_sleep;
	wire					bus_rdy;
    wire                    bus_en;
    wire                    bus_we;
    wire    [1:0]           bus_size;
    wire    [1:0]           slv_intr_ack_i;
	wire    [15:0]          bus_addr;
    wire    [31:0]          bus_io;
	wire	[31:0]			slv_bus_in;
	
	wire					dnn_irq_o;
	wire					dnn_bus_rdy;
	wire	[1:0]			core_intr_h;
    
    integer i;
    integer j;
    integer k;
    integer cycles;
    
    assign bus_io = slv_bus_out;
    assign slv_bus_in = bus_io;
    
    assign ext_mem_addr = ((bus_addr & 32'hffff) >> bus_size);
	
	//assign core_intr_h = {slv_intr_req_o[1], dnn_irq_o};
	//assign bus_rdy = slv_bus_rdy | dnn_bus_rdy;
    assign core_intr_h = slv_intr_req_o;
	assign bus_rdy = slv_bus_rdy;
	
    //soc_top #(.MAX_MEM_ADDR(MAX_INIT_ADDR)) soc_top_i (
	soc_top soc_top_i (
		.I_CLK(clk),
		.I_A_RESET_L(reset_n),
		.I_BUS_RDY(bus_rdy),
		.I_INTR_H(core_intr_h),
		
		.B_BUS_DATA(bus_io),
		
		.O_BUS_EN(bus_en),
		.O_BUS_WE(bus_we),
		.O_BUS_SIZE(bus_size),
		.O_INTR_ACK(slv_intr_ack_i),
		.O_BUS_ADDR(bus_addr),
		.O_CORE_SLEEP(core_sleep)
	);
	/*
	dnn_accelerator #(
        .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
        .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH)
    ) i_dnn_accelerator (
        .clk_i(clk),
        .reset_n_i(reset_n),
        .dnn_irq_o(dnn_irq),
        .riscv_en_i(bus_en),
        .riscv_we_i(bus_we),
        .riscv_size_i(bus_size),
        .riscv_addr_i(bus_addr),
        .riscv_data_io(bus_io),
        .riscv_ready_o(dnn_bus_rdy)
    );
	*/
	task reset_core;
		begin
			// Assert and deassert reset to start initialization
			init_done = 1'b0;
			@(negedge clk);
        	reset_n = 1'b0;
			slv_bus_rdy = 1'b0;
        	slv_intr_req_o = 2'b0;
        	slv_bus_out = 32'hzzzzzzzz;
        	#(CLK_PERIOD*3);
        	reset_n = 1'b1;
		end
	endtask
    
    task wait_pedge;
        begin
            @(posedge clk);
            #(SIGNAL_DLY);
        end
    endtask
	
	task mem_rw_byte;
		begin
			case (bus_addr[1:0])
				2'b00: begin
					i = 7;
					j = 0;
				end
				2'b01: begin
					i = 15;
					j = 7;
				end
				2'b10: begin
					i = 23;
					j = 16;
				end
				2'b11: begin
					i = 31;
					j = 24;
				end
			endcase
			if (bus_we) begin
				ext_sram_bytes[bus_addr] = slv_bus_in[j+:8];
				$display("%t: EMUL_BUS | SOC_BUS_WRITE --> ADDR = 0x%h, SIZE = 0x%h, DATA = 0x%h || %d", $time, bus_addr, bus_size, slv_bus_in, slv_bus_in);
			end
			else begin
				slv_bus_out[j+:8] = ext_sram_bytes[bus_addr];
				$display("%t: EMUL_BUS | SOC_BUS_READ --> ADDR = 0x%h, SIZE = 0x%h, DATA = 0x%h || %d", $time, bus_addr, bus_size, slv_bus_out, slv_bus_out);
			end
		end
	endtask
	
	task mem_rw_half;
		begin
			case (bus_addr[1])
				1'b0: begin
					i = 7;
					j = 0;
				end
				1'b1: begin
					i = 23;
					j = 16;
				end
			endcase
			if (bus_we) begin
				for (k = bus_addr; k < (bus_addr+2); k = k+1) begin
					ext_sram_bytes[k] = slv_bus_in[j+:8];
					i = i+8;
					j = j+8;
				end
				$display("%t: EMUL_BUS | SOC_BUS_WRITE --> ADDR = 0x%h, SIZE = 0x%h, DATA = 0x%h || %d", $time, bus_addr, bus_size, slv_bus_in, slv_bus_in);
			end
			else begin
				for (k = bus_addr; k < (bus_addr+2); k = k+1) begin
					slv_bus_out[j+:8] = ext_sram_bytes[k];
					i = i+8;
					j = j+8;
				end
				$display("%t: EMUL_BUS | SOC_BUS_READ --> ADDR = 0x%h, SIZE = 0x%h, DATA = 0x%h || %d", $time, bus_addr, bus_size, slv_bus_out, slv_bus_out);
			end
		end
	endtask
	
	task mem_rw_full;
		begin
			i = 7;
			j = 0;
			if (bus_we) begin
				for (k = bus_addr; k < (bus_addr+4); k = k+1) begin
					ext_sram_bytes[k] = slv_bus_in[j+:8];
					i = i+8;
					j = j+8;
				end
				$display("%t: EMUL_BUS | SOC_BUS_WRITE --> ADDR = 0x%h, SIZE = 0x%h, DATA = 0x%h || %d", $time, bus_addr, bus_size, slv_bus_in, slv_bus_in);
			end
			else begin
				for (k = bus_addr; k < (bus_addr+4); k = k+1) begin
					slv_bus_out[j+:8] = ext_sram_bytes[k];
					i = i+8;
					j = j+8;
				end
				$display("%t: EMUL_BUS | SOC_BUS_READ --> ADDR = 0x%h, SIZE = 0x%h, DATA = 0x%h || %d", $time, bus_addr, bus_size, slv_bus_out, slv_bus_out);
			end
		end
	endtask
	
	task slave_interrupt;
		begin
			// Assert interrupts
			if (cycles == INTR_0_CYCLE || slv_intr_ack_i[0]) begin
				slv_intr_req_o[0] = 1'b0;
				if (cycles == INTR_0_CYCLE) begin
					//#(SIGNAL_DLY);
					$display("%t: SLAVE | Asserting external interrupt_0 | cycle %d", $time, cycles);
					slv_intr_req_o[0] = 1'b1;
				end
				else if (slv_intr_ack_i[0]) begin
					$display("%t: SLAVE | Received ACK for interrupt_0 | cycle %d", $time, cycles);
				end
			end
			else if (cycles == INTR_1_CYCLE || slv_intr_ack_i[1]) begin
				slv_intr_req_o[1] = 1'b0;
				if (cycles == INTR_1_CYCLE) begin
					//#(SIGNAL_DLY);
					$display("%t: SLAVE | Asserting external interrupt_1 | cycle %d", $time, cycles);
					slv_intr_req_o[1] = 1'b1;
				end
				else if (slv_intr_ack_i[1]) begin
					$display("%t: SLAVE | Received ACK for interrupt_1 | cycle %d", $time, cycles);
				end
			end
			else if (core_sleep) begin
				$display("%t: SLAVE | Core Asleep, make woke | cycle %d", $time, cycles);
				slv_intr_req_o[0] = 1'b1;
			end
		end
	endtask
    
    task slave_bus;
        begin
			if (bus_en) begin
                slv_bus_out = 32'hzzzzzzzz;
				//#(SIGNAL_DLY);
                slv_bus_rdy = 1'b1;
                wait_pedge;
                slv_bus_rdy = 1'b0;
                wait_pedge;
				case (bus_size)
					2'b00: mem_rw_byte;
					2'b01: mem_rw_half;
					2'b10: mem_rw_full;
				endcase
                slv_bus_rdy = 1'b1;
				// Cause interrupt if MAX_INIT_ADDR is reached during init_done != 1
				if (bus_addr == MAX_INIT_ADDR && !init_done) begin
					$display("%t: SLAVE | Asserting external interrupt_0 | cycle %d", $time, cycles);
					slv_intr_req_o[0] = 1'b1;
					init_done = 1'b1;
				end
                wait_pedge;
                slv_bus_rdy = 1'b0;
            end
        end
    endtask
    
    // Gen clk
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Setup
    initial begin
		init_done = 1'b0;
        cycles = 0;
        clk = 1'b1;
        reset_n = 1'b1;
        
        $display("%t: << Starting Simulation >>", $time);
        $display("%t: Reading memfile in array", $time);
        $readmemh(EXT_MEM_FILE, ext_sram_bytes);
        
        $display("%t: Initialize Ext_SRAM | ", $time);
		/*
        for (k = 0; k < MAX_EXT_SRAM_SIZE_BYTES; k = k+1) begin
            $display("@%d : %h", k, ext_sram_bytes[k]);
        end
        */
		
        #(CLK_PERIOD*4);
		
        reset_core;
		
    end
    
    // Emulator
    always @(posedge clk) begin
        cycles = cycles + 1;
        if ((ext_sram_bytes[EXT_DMEM_BEG] == 8'h01 && ext_sram_bytes[EXT_DMEM_BEG+1] == 8'h00 && ext_sram_bytes[EXT_DMEM_BEG+2] == 8'h00 && ext_sram_bytes[EXT_DMEM_BEG+3] == 8'h00) || cycles == MAX_CYCLES) begin
			$display("%t: Ending simulation at cycle = %d", $time, cycles);
			$finish;
		end
        //$display("%t: cycle %d | Calling emulators", $time, cycles);
		
		// Delay all I/O task by input_delay value of constraints file
		#(SIGNAL_DLY);
		slave_interrupt;
        slave_bus;
    end
	
endmodule
