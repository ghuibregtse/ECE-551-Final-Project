module uart_rx_tb();
reg [7:0] data;
reg clk,rst_n,rx,rx_rdy;
reg [7:0] rx_data;
integer i;

uart_rx iDUT(clk,rst_n,rx,rx_rdy,rx_data);


initial begin
	clk = 0;
	forever 
		#5 clk = ~clk;
end

initial begin
	rst_n = 0;
	rx = 1;
	@(posedge clk);
	rst_n = 1;
	repeat (2) @(posedge clk);
	rx = 0;
	data = 8'hA5;
	for (i = 0; i < 8; i= i+1) begin
		repeat (2604) @(posedge clk);
		rx = data[i];
	end	
	repeat (2604) @(posedge clk);
	rx = 1;
	repeat (2604) @(posedge clk);
	$display("Expected: %h Actual: %h ", data, rx_data);
	if (data == rx_data)
		$display("Pass\n");
	else
		$display("Fail\n");
	rx = 0;
	data = 8'hE7;
	for (i = 0; i < 8; i= i+1) begin
		repeat (2604) @(posedge clk);
		rx = data[i];
	end	
	repeat (2604) @(posedge clk);
	rx = 1;
	repeat (2604) @(posedge clk);
	$display("Expected: %h Actual: %h ", data, rx_data);
	if (data == rx_data)
		$display("Pass\n");
	else
		$display("Fail\n");
	rx = 0;
	data = 8'h24;
	for (i = 0; i < 8; i= i+1) begin
		repeat (2604) @(posedge clk);
		rx = data[i];
	end	
	repeat (2604) @(posedge clk);
	rx = 1;
	repeat (2604) @(posedge clk);
	$display("Expected: %h Actual: %h ", data, rx_data);
	if (data == rx_data)
		$display("Pass\n");
	else
		$display("Fail\n");
	repeat (2604) @(posedge clk);


	$stop;




end
endmodule 