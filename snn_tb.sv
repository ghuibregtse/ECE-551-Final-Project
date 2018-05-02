module snn_tb();


reg clk, rst_n, uart_tx,tx_rdy;
reg [7:0] led;
reg [7:0] tx_data;
reg [9:0] addr;
reg we,data,tx_start,inc_addr,rdy;
reg q;
integer i,j;
ram_input_test test(data,addr,we,clk,q);
uart_tx iTX(clk, rst_n, tx, tx_start, tx_data, rdy);
snn iDut(clk, rst_n, led, uart_tx, tx,tx_rdy);
initial begin
clk = 0;
	forever
	#5 clk = ~clk;
end



initial begin
rst_n = 0;
inc_addr = 0;
we = 0;
data = 0;
tx_start = 0;
addr = 0;
tx_data = 8'hFF;
@(negedge clk);
rst_n = 1;
for (j = 0; j < 98; j = j+1) begin
	for (i = 0; i < 8; i= i+1) begin
		tx_data[i] = q;
		addr = addr + 1;
		@(posedge clk);
	end	
	tx_start = 1;
	@(posedge clk)
	tx_start = 0;
	@(posedge rdy);
	//repeat(8) @(posedge clk);
end
$stop; 
end

endmodule
