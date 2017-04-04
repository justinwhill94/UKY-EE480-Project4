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
reg `WORD pc [1:0];
reg `WORD iReg [1:0];
reg `STATE CurrState [1:0];
reg `REGNUM sp [1:0];
reg `REGNUM dest [1:0];
reg `REGNUM src [1:0];
reg  torf [1:0];
reg  preit [1:0];
reg `PRE pre [1:0];
integer a [1:0];

// Reset
always @(reset)
begin
    halt = 0;
    pc[0] = 0;
    pc[1] = 0;
    sn <= `OPstart;
		CurrState[0] = `Start;
		CurrState[1] = `Start;
		sp[0] = -1;
		sp[1] = -1;
		preit[0] = 0;
		preit[0] = 0;
    $readmemh0(r);
    $readmemh1(m);
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
