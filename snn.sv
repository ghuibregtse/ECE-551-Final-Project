module snn(clk, sys_rst_n, led, uart_tx, uart_rx,tx_rdy);
	
	/*****************************************************
	Pin declarations
	*****************************************************/
	input clk;		//50MHz clock
	input sys_rst_n;	//Unsynchronized reset from push button. Needs to be synchronized.
	input uart_rx;	
	output reg [7:0] led;	//Drives LEDs of DE0 nano board
	output uart_tx, tx_rdy;
	
	/*****************************************************
	State declaration for FSM control unit
	*****************************************************/
	typedef enum {LOAD,RAM_WRITE,CALCULATE,TRANSMIT} State;
	State state,nxt_state;
	
	/******************************************************
	Reset synchronizer
	******************************************************/
	logic rst_n;		//Synchronized active low reset
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
	
	
	// Double flop RX for meta-stability reasons
	logic uart_rx_ff, uart_rx_synch;
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			uart_rx_ff <= 1'b1;
			uart_rx_synch <= 1'b1;
		end else begin
	  		uart_rx_ff <= uart_rx;
	 		uart_rx_synch <= uart_rx_ff;
		end
	end
	
	/*********************************************************************
	 Instantiate UART_RX and UART_TX and connect them below
	 For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx". 
	**********************************************************************/
	reg [7:0] rx_data, uart_data;
	wire [7:0] out_digit;
	wire rx_rdy;
	
	uart_rx rx(clk,rst_n,uart_rx_synch,rx_rdy,rx_data);
	uart_tx tx(clk, rst_n, uart_tx, done, out_digit,tx_rdy);
	
	/***************************************************************************
	 uart_data[0] holds the input bit that is to be written to ram_input_unit, 
	 upon rx_rdy, uart_data is set to rx_data and put in a shifter so that 
	 uart_data[0] always holds the bit that needs to be written to ram_input_unit
	****************************************************************************/
	logic clr_uart;
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			uart_data <= 8'hFF;
		else if (clr_uart)
			uart_data <= 8'hFF;
		else if (rx_rdy)
			uart_data <= rx_data;
		else
			uart_data <= {1'b1,uart_data[7:1]};
	end
	
	/******************************************************
	 SNN_Core Logic Instantiation
	******************************************************/
	wire [9:0] addr_input_unit;    // address of each q_input being sent to snn_core
	logic start;                   // asserted when finished writing SNN_INPUT to RAM
	wire [3:0] digit;              // calculated digit
	
	snn_core snn_core(clk, rst_n, start, q, addr_input_unit, digit, done);
	
	/******************************************************
	 ram_prog holds the address for ram_input_unit whenever 
	 not in state == Calculate
	******************************************************/
	logic clr_ram_prog,inc_ram;
	wire  ram_write_done;
	reg [9:0] ram_prog; 
	
	assign ram_write_done = (ram_prog == 10'h30f) ? 1 : 0;
	always@(posedge clk, negedge rst_n) begin
		if (!rst_n)
			ram_prog <= 10'h0;
		else
			if (clr_ram_prog)
				ram_prog <= 10'h0;
			else if (inc_ram)
				ram_prog <= ram_prog + 1;
			else
				ram_prog <= ram_prog;
	end
	
	/***********************************************************
	 Chooses the correct ram_addr for ram_input_unit depending 
	 on the state 
	***********************************************************/
	wire [9:0] ram_addr; 
	assign ram_addr = (state == CALCULATE) ? addr_input_unit : ram_prog;
	
	/******************************************************
	 ram_input_unit instantiation and logic
	******************************************************/
	logic we;
	ram_input_unit ram_input_unit(uart_data[0], ram_addr, we, clk, q);
	
	/******************************************************
	 write_prog increments by 1 from 0-7 everytime data is 
	 written to ram_input_unit, when write_prog reaches
	 7 the FSM transitions back to LOAD to wait for the next 
	 byte of data to be ready to write to ram_input_unit
	******************************************************/
	logic clr_write_prog,inc_write;
	wire write_done;
	reg [2:0] write_prog;
	
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
	
	/****************************************************************
	 State Machine Transition/Combinational Logic for the snn design
	****************************************************************/
	always_comb begin
		//set default values
		inc_write = 0;
		inc_ram = 0;
		clr_ram_prog = 0;
		we = 0;
		nxt_state = LOAD;
		start = 0;
		clr_write_prog = 0;
		clr_uart = 0;
		case (state)
			/**********************************************************
	 		 LOAD is the default state. The FSM is in this state until 
			 SNN has loaded in a byte of data (when rx_rdy is asserted) 
			 and transitions to RAM_WRITE to begin writing the input 
			 bits to ram_input_unit
			**********************************************************/
			LOAD : begin
				if (rx_rdy) begin
					nxt_state = RAM_WRITE;
				end else begin
					nxt_state = LOAD;			
				end
			end
			/**********************************************************
	 		 RAM_WRITE is where ram_input_unit is initialized to the input 
			 bitmap. When write_done is asserted, 8 bits have been written
			 and the FSM transitions back to LOAD to grab the next byte of 
			 input data. When ram_write_done is asserted all 784 input
			 bits have been written and the FSM transitions to CALCULATE 
			 to begin finding the correct value for the digit. 
			**********************************************************/
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
			/*******************************************************
	 		 CALCULATE is where the digit is calculated. When the 
			 SNN_CORE is done calculating, done will be asserted and
			 the FSM transitions to TRANSMIT.
			*******************************************************/
			CALCULATE  : begin
				if(done)
					nxt_state = TRANSMIT;
				else
					nxt_state = CALCULATE;
			end
			/*******************************************************
	 		 TRANSMIT sends the calculated digit to the PC and sets
			 LED to the calculated digit value
			*******************************************************/
			TRANSMIT : begin
				clr_write_prog = 1;
				clr_ram_prog = 1;
				clr_uart = 1;
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
	assign out_digit = {4'h0, digit};
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			led <= 8'h00;
		else 
			if (done)
				led <= out_digit;
			else
				led <= led;
	end

	/******************************************************/
endmodule

