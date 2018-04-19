/* ECE 551 Spring 2018 Final Project
 *
 * File:	rom_hidden_weight.sv
 * Authors:	Garret Huibregtse, Sean Cohen, Austin Wirtz
 *
 */
module rom_hidden_weight(addr,clk,q);
	localparam ADDR_WIDTH = 15;
	localparam DATA_WIDTH = 8;
	
	input [(ADDR_WIDTH-1):0] addr;
	input clk;
	output reg [(DATA_WIDTH-1):0] q;
	
	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom [2**ADDR_WIDTH-1:0];
	
	initial
		readmemh("Initialization file", rom);
	
	always@(posedge clk) begin
		q <= rom[addr];
	end
	
	endmodule
