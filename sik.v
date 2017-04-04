//#######################################################################
// Initialize Constants with `define
//#######################################################################

// Standard Sizes
`define WORD	[15:0]
`define Opcode	[15:12]
`define Immed	[11:0]
`define STATE	[7:0]
`define PRE	[3:0]
`define REGSIZE	[255:0]
`define REGNUM	[7:0]
`define MEMSIZE [65535:0]

// Opcode State Numbers
`define OPadd 
`define OPand 
`define OPcall 
`define OPdup 
`define OPget 
`define OPjumpf 
`define OPjump 
`define OPjumpt 
`define OPload 
`define OPlt 
`define OPor 
`define OPpop 
`define OPpre 
`define OPpush 
`define OPput 
`define OPret 
`define OPstore 
`define OPsub 
`define OPsys 
`define OPtest 
`define OPxor 
`define OPstart 
`define OPstart1 

//#######################################################################
// Main Processor Module
//#######################################################################
module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile `REGSIZE;
reg `WORD mainmem `MEMSIZE;
reg `WORD pc = 0;
reg `WORD iReg;
reg `STATE CurrState = `Start;
reg `REGNUM sp = -1;
reg `REGNUM dest;
reg `REGNUM src;
reg torf;
reg preit = 0;
reg `PRE pre;
integer a;

// Reset
always @(reset)
begin

end

//#######################################################################
// Thread 1
//#######################################################################

// Stage 1
always @(posedge clk)
begin
end

// Stage 2
always @(posedge clk)
begin
end

// Stage 3
always @(posedge clk)
begin
end

// Stage 4
always @(posedge clk)
begin
end


//#######################################################################
// Thread 2
//#######################################################################

// Stage 1
always @(negedge clk)
begin
end

// Stage 2
always @(negedge clk)
begin
end

// Stage 3
always @(negedge clk)
begin
end

// Stage 4
always @(negedge clk)
begin
end
endmodule


//#######################################################################
// Test Bench
//#######################################################################
module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
processor PE(halted, reset, clk);
	initial begin
		$dumpfile;
		$dumpvars(0, PE);
		#10 reset = 1;
		#10 reset = 0;
		while (!halted) begin
			#10 clk = 1;
			#10 clk = 0;
		end
		$finish;
	end
endmodule
