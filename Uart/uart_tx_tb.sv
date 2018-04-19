module uart_tx_tb();

reg [7:0] tx_data;
reg clk,rst_n,tx,tx_rdy,tx_start;

uart_tx iDUT(clk,rst_n,tx,tx_start,tx_data,tx_rdy);

initial begin
	clk = 0;
	forever 
		#5 clk = ~clk;
end

initial begin
	rst_n = 0;
	tx_data = 8'hA1;
	tx_start = 0;
	repeat (2) @(posedge clk);
	rst_n = 1;
	repeat (2) @(posedge clk);
	tx_start = 1;
	repeat(10) repeat (2604) @(posedge clk);
	tx_data = 8'h53;
	repeat(10) repeat (2604) @(posedge clk);


	$stop;



end


endmodule
