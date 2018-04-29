/* ECE 551 Spring 2018 Final Project
 *
 * File:	rom_act_func_lut.sv
 * Authors:	Garret Huibregtse, Sean Cohen, Austin Wirtz
 *
 */
module rom_act_func_lut(addr,clk,q);
	localparam ADDR_WIDTH = 11;
	localparam DATA_WIDTH = 8;
	
	input [(ADDR_WIDTH-1):0] addr;
	input clk;
	output reg [(DATA_WIDTH-1):0] q;
	
	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom [2**ADDR_WIDTH-1:0];
	
	initial
		$readmemh("rom_act_func_lut_contents.txt", rom);
	
	always@(posedge clk) begin
		q <= rom[addr];
	end
	
	endmodule
