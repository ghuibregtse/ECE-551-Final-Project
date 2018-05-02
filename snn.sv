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
	wire [7:0] ascii_digit;
	wire [3:0] digit;
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
	uart_tx tx(clk, rst_n, uart_tx, done, ascii_digit,tx_rdy);
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			uart_data <= 8'hFF;
		else if (rx_rdy)
			uart_data <= rx_data;
		else
			uart_data <= uart_data;

	end
	/******************************************************
	Ram Input Unit Instantiation and logic
	******************************************************/
	wire [9:0] ram_addr;
	logic we,clr_write_prog; 
	reg [9:0] ram_prog;
	reg [2:0] write_prog;
	wire write_done, ram_write_done;
	logic inc_write,inc_ram;
	ram_input_unit ram_input_unit(uart_data[write_prog], ram_addr, we, clk, q);
	/******************************************************
	SNN_Core logic
	******************************************************/
	wire [9:0] addr_input_unit;    // address of each q_input being sent to snn_core
	logic start;                   // asserted when finished writing SNN_INPUT to RAM
	snn_core snn_core(clk, rst_n, start, q, addr_input_unit, digit, done);
	
	typedef enum {IDLE,LOAD,RAM_WRITE,CALCULATE_FP,CALCULATE,TRANSMIT} State;
	State state,nxt_state;
	
	/******************************************************
	Chooses the correct address for RAM depending on the state 
	******************************************************/
	assign ram_addr = (state == CALCULATE) ? addr_input_unit : ram_prog;

	/******************************************************
	Write 8 times
	******************************************************/
	assign write_done = (write_prog == 3'h7) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			write_prog <= 3'h0;
		else
			if (clr_write_prog)
				write_prog <= 3'h0;
			else if (inc_write)
				write_prog <= write_prog + 1;
			else
				write_prog <= write_prog;
	end 
	
	/******************************************************
	Counts address of input ram
	******************************************************/
	assign ram_write_done = (ram_prog == 10'h30f) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			ram_prog <= 10'h0;
		else
			if (inc_ram)
				ram_prog <= ram_prog + 1;
			else
				ram_prog <= ram_prog;
	end
	

	/******************************************************
	* State Machine Transition/Combinational Logic for the snn design
	******************************************************/
	
	
	always_comb begin
		inc_write = 0;
		inc_ram = 0;
		we = 0;
		nxt_state = IDLE;
		start = 0;
		clr_write_prog = 0;
		case (state)
			IDLE : begin
				if (!uart_rx) begin
					nxt_state = LOAD;
				end	
			end
			//In this stage until all 98 bytes are loaded into SNN_INPUT
			LOAD : begin
				if (rx_rdy) begin
					nxt_state = RAM_WRITE;
				end else begin
					nxt_state = LOAD;			
				end
			end
			//In this stage until all of RAM_WRITE has been updated to match SNN_INPUT
			RAM_WRITE : begin
				we = 1;
				inc_ram = 1;
				inc_write = 1;				
				if(ram_write_done) begin
					start = 1;
					nxt_state = CALCULATE;
				end
				else if (write_done) begin
					clr_write_prog = 1;
					nxt_state = LOAD;
				end
				else begin 
					nxt_state = RAM_WRITE;
				end
			end
			//In this stage until digit has been calculated
			CALCULATE_FP : begin
				start = 1;
				nxt_state = CALCULATE;
			end
			CALCULATE  : begin
				if(done)
					nxt_state = TRANSMIT;
				else
					nxt_state = CALCULATE;
			end
			//Converts digit to ASCI for UART_TX and also sets LED to display the calculated digit
			TRANSMIT : begin
				if(tx_rdy)
					nxt_state = IDLE;
				else
					nxt_state = TRANSMIT;
			end
			default : nxt_state = IDLE;
		endcase
	end

	/******************************************************
	* State Machine Sequential Logic for the snn design
	******************************************************/	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			state <= IDLE;
		else 
			state <= nxt_state;
	end
	/******************************************************
	LED
	******************************************************/
	assign ascii_digit = {4'h3, digit};
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			led <= 8'h00;
		else 
			if (done)
				led <= ascii_digit;
			else
				led <= led;
	end

	/******************************************************/
endmodule
