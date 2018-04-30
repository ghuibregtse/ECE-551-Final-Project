/* ECE 551 Spring 2018 Final Project
 *
 * File:	ram_input_unit.sv
 * Authors:	Garret Huibregtse, Sean Cohen, Austin Wirtz
 *
 */
module ram_input_test(data,addr,we,clk,q);
	
	localparam ADDR_WIDTH = 10;
	localparam DATA_WIDTH = 1;
	
	input [(DATA_WIDTH-1):0] data;
	input [(ADDR_WIDTH-1):0] addr;
	input we, clk;
	output [(DATA_WIDTH-1):0] q;;
	 
	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	initial
	$readmemh("ram_input_contents_sample_0.txt", ram);

	always @ (posedge clk)
	begin
	if (we) // Write
		ram[addr] <= data;
	addr_reg <= addr;
	end
	assign q = ram[addr_reg];
	endmodule

