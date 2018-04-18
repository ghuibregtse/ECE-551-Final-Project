module uart_tx(clk, rst_n, tx, tx_start, tx_data, tx_rdy);

input clk, rst_n, tx_start;
output reg tx; // data transmitted 1 bit at a time
output logic tx_rdy; // when asserted data is ready to be transmitted
input [7:0] tx_data; // data being transmitted
logic clr, shift, load; // state machine outputs
wire baud_full, bit_full; // asserted when the respective counters are full
reg [9:0] tran_data; // stores the data and the start/end bits
reg [11:0] baud_cnt; // baud counter that counts to 2604 and increases each cycle
reg [3:0] bit_ind_cnt; // index counter that counts to 10 and increases when baud expires

typedef enum {IDLE,TX} State;
State state,nxt_state;

/******************************************************
* 12-bit baud counter with asynch reset
******************************************************/
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		baud_cnt <= 12'h0;
	else
		if (clr)
			baud_cnt <= 12'h0;
		else	
			baud_cnt <= baud_cnt + 1;
end

assign baud_full = (baud_cnt == 12'hA2C) ? 1'b1 : 1'b0;

/******************************************************
* 4-bit index counter with asynch reset
******************************************************/
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		bit_ind_cnt <= 4'h0;
	else
		if (load)
			bit_ind_cnt <= 4'h0;
		else if (shift)
			bit_ind_cnt <= bit_ind_cnt + 1;
		else
			bit_ind_cnt <= bit_ind_cnt;
end

assign bit_full = (bit_ind_cnt == 4'hA) ? 1'b1 : 1'b0;

/******************************************************
* 10-bit shifter to get tx data with asynch reset
******************************************************/

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		tran_data <= 10'h0;
	else 
		if (load)
			tran_data <= {1'b1, tx_data, 1'b0};
		else if (shift)
			tran_data <= {1'b1,tran_data[9:1]};
		else
			tran_data <= tran_data;	
end	

/******************************************************
* register to set tx with asynch reset
******************************************************/

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		tx <= 1'b0;
	else
		tx <= tran_data[0];

end

/******************************************************
* State Machine Transition/Combinational Logic for the UART design
******************************************************/

always_comb begin

	tx_rdy = 0;
	clr = 0;
	shift = 0;
	load = 0;
	nxt_state = IDLE;
	case (state)
		IDLE : begin
			if(tx_start) begin
				clr = 1;
				load = 1;
				nxt_state = TX;
			end else begin
				clr = 1;
				tx_rdy = 1;
			end
		end
		TX : begin
			if(bit_full)
				nxt_state = IDLE;
			else begin
				if(baud_full) begin
					clr = 1;
					shift = 1;
					nxt_state = TX;
				end else
					nxt_state = TX;
			end
		end
		default : nxt_state = IDLE;
	endcase
end

/******************************************************
* State Machine Sequential Logic for the UART design
******************************************************/	
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) 
		state <= IDLE;
	else 
		state <= nxt_state;
end



endmodule