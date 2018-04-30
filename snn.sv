module snn(clk, sys_rst_n, led, uart_tx, uart_rx,tx_rdy);
		
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	output reg [7:0] led;	// Drives LEDs of DE0 nano board
	input uart_rx;
	output uart_tx, tx_rdy;
	logic rst_n;				 	// Synchronized active low reset
	logic uart_rx_ff, uart_rx_synch;

	/******************************************************
	Reset synchronizer
	******************************************************/
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
	/******************************************************
	UART Instantiation and logic
	******************************************************/
	
	// Declare wires below
	wire rx_rdy;
	reg [7:0] rx_data, uart_data;
	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
		uart_rx_ff <= 1'b1;
		uart_rx_synch <= 1'b1;
	end else begin
	  uart_rx_ff <= uart_rx;
	  uart_rx_synch <= uart_rx_ff;
	end
	
	
	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".
	
	uart_rx rx(clk,rst_n,uart_rx_synch,rx_rdy,rx_data);
	uart_tx tx(clk, rst_n, uart_tx, rx_rdy, uart_data,tx_rdy);
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			uart_data <= 8'hFF;
		else
			uart_data <= rx_data;

	end
	/******************************************************
	Ram Input Unit Instantiation and logic
	******************************************************/
	reg [783:0] SNN_INPUT;
	reg [9:0] RAM_ADDR;
	logic we_R; 
	reg [9:0] RAM_PROG;
	ram_input_unit ram_input_unit(SNN_INPUT[RAM_PROG], RAM_ADDR, we_R, clk, q);
	/******************************************************
	SNN_Core logic
	******************************************************/
	wire [9:0] addr_input_unit;    // address of each q_input being sent to snn_core
	logic start;                   // asserted when finished writing SNN_INPUT to RAM
	snn_core snn_core(clk, rst_n, start, q, addr_input_unit, digit, done);
	
	
	reg [6:0] LOAD_PROG;
	wire LOAD_DONE;
	logic INC_LOAD,INC_RAM,StateT,StateRW;
	
		
	assign LOAD_DONE = (LOAD_PROG == 7'h62) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			LOAD_PROG <= 7'h0;
		else
			if (INC_LOAD)
				LOAD_PROG <= LOAD_PROG + 1;
			else
				LOAD_PROG <= LOAD_PROG;
	end
	
	
	assign RAM_WRITE_DONE = (RAM_PROG == 10'h310) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			RAM_PROG <= 10'h0;
		else
			if (INC_RAM)
				RAM_PROG <= RAM_PROG + 1;
			else
				RAM_PROG <= RAM_PROG;
	end
	//Chooses the correct address for RAM depending on the state 
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			RAM_ADDR <= 10'h0;
		end
		else if(StateRW) begin
			RAM_ADDR <= RAM_PROG;
		end
		else begin
			RAM_ADDR <= addr_input_unit;
		end
	end
	//Continuously concatenate until the entire input has been taken in
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			SNN_INPUT <= 10'h0;
		end
		else if (rx_rdy) begin
			SNN_INPUT <= {rx_data,SNN_INPUT};
		end
		else begin
			SNN_INPUT <= SNN_INPUT;
		end
	end
	/******************************************************
	* State Machine Transition/Combinational Logic for the snn design
	******************************************************/
	typedef enum {LOAD,RAM_WRITE,CALCULATE,TRANSMIT} State;
	State state,nxt_state;
	
	always_comb begin
		INC_LOAD = 0;
		INC_RAM = 0;
		we_R = 0;
		StateT = 0;
		StateRW = 0;
		nxt_state = LOAD;
		start = 0;
		case (state)
			//In this stage until all 98 bytes are loaded into SNN_INPUT
			LOAD : begin
				if (LOAD_DONE) begin
					nxt_state = RAM_WRITE;
				end
				else if(rx_rdy) begin
					INC_LOAD = 1;				
				end
			end
			//In this stage until all of RAM_WRITE has been updated to match SNN_INPUT
			RAM_WRITE : begin
				StateRW = 1;
				if(RAM_WRITE_DONE) begin
					nxt_state = CALCULATE;
				end
				else begin 
					we_R = 1;
					INC_RAM = 1;
					nxt_state = RAM_WRITE;
				end
			end
			//In this stage until digit has been calculated
			CALCULATE : begin
				if (done)
					nxt_state = TRANSMIT;
				else begin
					start = 1;
					nxt_state = CALCULATE;
				end
			end
			//Converts digit to ASCI for UART_TX and also sets LED to display the calculated digit
			TRANSMIT : begin
				StateT = 1;
				if(tx_rdy)
					nxt_state = LOAD;
				else 
					nxt_state = TRANSMIT;
			end
			default : nxt_state = LOAD;
		endcase
	end

	/******************************************************
	* State Machine Sequential Logic for the snn design
	******************************************************/	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			state <= LOAD;
		else 
			state <= nxt_state;
	end
	/******************************************************
	LED
	******************************************************/
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			led <= 8'h00;
		else 
			if (StateT)
				led <= {0011,digit};
			else
				led <= led;
	end
	
	/******************************************************/
endmodule
