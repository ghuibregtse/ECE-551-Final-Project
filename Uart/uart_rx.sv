
module uart_rx(clk,rst_n,rx,rx_rdy,rx_data);

input clk,rst_n,rx;
output logic rx_rdy; // data is ready
logic shift, load;
logic clr, baud_half, baud_full, bit_full;
output reg [7:0] rx_data; // data received
reg [9:0] rec_data; // stores the data and the start/end bits
reg [11:0] baud_cnt; // baud counter that counts to 2604 and increases each cycle
reg [3:0] bit_ind_cnt; // index counter that counts to 10 and increases when baud expires

typedef enum {IDLE,FRONT_PORCH,RX,BACK_PORCH} State;
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

assign baud_half = (baud_cnt == 12'h516) ? 1'b1 : 1'b0;
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

assign bit_full = (bit_ind_cnt == 4'h9) ? 1'b1 : 1'b0;
/******************************************************
* 10-bit shifter to get rx data with asynch reset
******************************************************/

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		rec_data <= 10'h0;
	else 
		if (load)
			rec_data <= 10'h0;
		else if (shift)
			rec_data <= {rx,rec_data[9:1]};
		else
			rec_data <= rec_data;	
end	

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		rx_data <= 8'h0;
	else
		rx_data <= rec_data[8:1];


end

/******************************************************
* State Machine Transition/Combinational Logic for the UART design
******************************************************/

always_comb begin

	rx_rdy = 0;
	clr = 0;
	shift = 0;
	load = 0;
	nxt_state = IDLE;
	case (state)
		IDLE : begin
			if(!rx) begin
				clr = 1;
				load = 1;
				nxt_state = FRONT_PORCH;
			end else begin
				clr = 1;
				nxt_state = IDLE;
			end
		end
		FRONT_PORCH : begin
			if(baud_half)
				nxt_state = RX;
			else
				nxt_state = FRONT_PORCH;
		end
		RX : begin
			if(bit_full)
				if (rx) begin
					if (baud_half)
						nxt_state = BACK_PORCH;
					else 
						nxt_state = RX;
				end else 
					nxt_state = IDLE;
			else begin
				if(baud_full) begin
					clr = 1;
					shift = 1;
					nxt_state = RX;
				end else
					nxt_state = RX;
			end
		end
		BACK_PORCH : begin
			if(baud_full) begin
				rx_rdy = 1;
				nxt_state = IDLE;
			end else
				nxt_state = BACK_PORCH;
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




