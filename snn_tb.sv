module snn_tb();


reg clk, sys_rst_n, uart_tx, uart_rx,tx_rdy;
reg [7:0] led;
reg [7:0] data;
integer i;

snn iDut(clk, sys_rst_n, led, uart_tx, uart_rx);
initial begin
clk = 0;
	forever
	#5 clk = ~clk;
end

initial begin
sys_rst_n = 0;
data = 8'hA5;
@(negedge clk);
sys_rst_n = 1;
uart_rx = 0;
	for (i = 0; i < 8; i= i+1) begin
		repeat (2604) @(posedge clk);
		uart_rx = data[i];
	end	
	repeat (2604) @(posedge clk);
	uart_rx = 1;
	repeat (2604) @(posedge clk);
	repeat(10)repeat(2604) @(posedge clk);
data = 8'h93;
uart_rx = 0;
	for (i = 0; i < 8; i= i+1) begin
		repeat (2604) @(posedge clk);
		uart_rx = data[i];
	end	
	repeat (2604) @(posedge clk);
	uart_rx = 1;
	repeat (2604) @(posedge clk);
	repeat(10)repeat(2604) @(posedge clk);
$stop;
end

endmodule
