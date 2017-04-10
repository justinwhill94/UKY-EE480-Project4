// -----------------------------Size parameters----------------------------------
`define WORD    [15:0]
`define OP      [4:0]
`define ARG		[11:0]
`define Opcode	[15:12]
`define Dest    [11:6]
`define Src	    [5:0]
`define REGSIZE [256:0]
`define MEMSIZE [65535:0]

// -----------------------------OPcodes/State Numbers---------------------------
// opcode values/state numbers
`define OPNoArg	4'h0
`define OPCall	4'h1
`define OPJump	4'h2
`define OPJumpF	4'h3
`define OPJumpT	4'h4
`define OPGet	4'h5
`define OPPut	4'h6
`define OPPop	4'h7
`define OPPre	4'h8
`define OPPush	4'h9
`define OPNop 	4'hf

// -----------------------------NoArg Opcodes----------------------------------
`define OPadd	12'h0
`define OPand	12'h1
`define OPdup	12'h2
`define OPload	12'h3
`define OPlt	12'h4
`define OPor	12'h5
`define OPret	12'h6
`define OPstore	12'h7
`define OPsub	12'h8
`define OPsys	12'h9
`define OPtest	12'ha
`define OPxor	12'hb

/*
module decode(src, dest, op, sp);

endmodule
*/
module alu(res, op, in1, in2);
output reg res;
input wire `OP op;
input wire `WORD in1, in2;

always @(op, in1, in2) 
begin
	case(op)
		`OPadd: begin res = in1 + in2; end
		`OPand: begin res = in1 & in2;end
		`OPlt: begin res = in1 < in2;end
		`OPor: begin res = in1 | in2;end
		`OPsub: begin res = in1 - in2;end
		`OPxor: begin res = in1 ^ in2;end
		default: res = in1;
	endcase
end
endmodule

module processor(halt, reset, clk);
/*
Multithreading Declarations
reg `WORD regile [1:0] `REGSIZE;
reg `WORD mainmem [1:0] `MEMSIZE;
reg `WORD ir, srcval[1:0], destval[1:0];
reg `OP stage0op[1:0], stage1op[1:0], stage2op[1:0], stage3op[1:0];
reg `ARG stage0arg[1:0],stage1arg[1:0],stage2arg[1:0],stage3arg[1:0]
reg `WORD stage1src[1:0], stage2src[1:0], stage3src[1:0];
reg `WORD stage1dest[1:0], stage2dest[1:0], stage3dest[1:0];
reg `WORD pc [1:0];
reg thread;
*/
Multithreading Declarations
reg `WORD regfile  `REGSIZE;
reg `WORD mainmem  `MEMSIZE;
reg `WORD ir, aluRES, aluIN1, aluIN2;
reg `ARG aluOP;
reg `OP stage0op, stage1op, stage2op, stage3op;
reg `ARG stage0arg,stage1arg,stage2arg,stage3arg
reg `WORD stage1src, stage2src, stage3src;
reg `WORD stage1dest, stage2dest, stage3dest;
reg `WORD stage2destval, stage3destval;
reg `WORD stage2srcval, stage3srcval;
reg stage0preloaded, stage1preloaded, stage2preloaded, stage3preloaded;
reg [3:0] stage0preReg, [3:0] stage1preReg, [3:0] stage2preReg, [3:0] stage3preReg
reg torf;
reg `WORD pc;

always @(reset)
begin
	halt = 0;
	pc = 2'h0;
	thread = 0;
	stage0op = `OPnop;
	stage1op = `OPnop;
	stage2op = `OPnop;
	stage3op = `OPnop;
end

alu myalu(aluRES, aluOP, aluIN1, aluIN2);

// -----------------------------stage 0----------------------------------
// Instruction Fetch
always @(posedge clk)
begin
	ir = mainmem[pc];
	stage0op = ir `Opcode;
	stage0arg = ir `ARG;
	
end

// -----------------------------stage 1----------------------------------
// Instruction Decoding
always @(posedge clk)
begin
	stage1op = stage0op;
	stage1arg = stage0arg;
	stage1preloaded = stage0preloaded;
	stage1preReg = stage0preReg;
	case (stage1op)
		`OpNoArg:
		begin
			case (stage1arg)
				`OPdup:
				begin
					stage1dest =sp +1;
					stage1src = sp;
					sp = sp -1;
				end

				`OPload:
					stage1dest =sp;
					stage1src = 0;
				begin
				end

				`OPret:
					stage1dest =0;
					stage1src = sp;
					stage0op = `OpNop;
					sp = sp -1;
				begin
				end

				`OPstore:
					stage1dest =sp -1;
					stage1src = sp;
					sp = sp - 1;
				begin
				end

				`OPsys:
					stage1dest = 0;
					stage1src = 0;
				begin
				end

				`OPtest:
					stage1dest = 0;
					stage1src = sp;
					sp = sp-1;
				begin
				end

				default:
				begin
					stage1dest = sp -1;
					stage1src = sp;
					sp = sp -1;
				end

			endcase
		end

		`OPCall:
		begin
			stage1dest = sp +1;
			stage1src = 0;
			stage0op = `OpNop; 

			if (stage1preloaded)
			begin
				pc = {stage1preReg, stage1arg};
			end

			else
			begin
				pc =((pc-1) & 16'hf000) | (stage1arg & 16'h0fff); 
			end
			stage0preloaded = 0;
			sp = sp + 1;
		end
	
		`OPJump:
		begin
			stage1dest = 0;
			stage1src = 0;
			stage0op = `OpNop;

			if (stage1preloaded)
			begin
				pc = {stage1preReg, stage1arg};
			end

			else
			begin
				pc =((pc-1) & 16'hf000) | (stage1arg & 16'h0fff); 
			end
			stage0preloaded = 0;
			stage1op = `OpNop;
		end
	
		`OPJumpF:
		begin
			stage1dest = 0;
			stage1src = 0;
			if(!torf)
			begin
				stage0op = `OpNop;
				if (stage1preloaded)
				begin
					pc = {stage1preReg, stage1arg};
				end

				else
				begin
					pc =((pc-1) & 16'hf000) | (stage1arg & 16'h0fff); 
				end

				stage0preloaded = 0;
				stage1op = `OpNop;
			end
		end
	
		`OPJumpT:
		begin
			stage1dest = 0;
			stage1src = 0;
			if(torf)
			begin
				stage0op = `OpNop;
				if (stage1preloaded)
				begin
					pc = {stage1preReg, stage1arg};
				end

				else
				begin
					pc =((pc-1) & 16'hf000) | (stage1arg & 16'h0fff); 
				end

				stage0preloaded = 0;
				stage1op = `OpNop;
			end
		end
	
		`OPGet:
		begin
			stage1dest = sp + 1;
			stage1src = sp - stage1arg;
			sp = sp + 1;
		end
	
		`OPPut:
		begin
			stage1dest = sp - stage1arg;
			stage1src = sp;
		end
	
		`OPPop:
		begin
			stage1dest = 0;
			stage1src = 0;
			sp = sp - stage1arg;
		end
	
		`OPPre:
		begin
			stage1dest = 0;
			stage1src = 0;
			stage0preloaded = 1;
			stage0preReg = stage1arg;
			stage1op = `OpNop;
		end
	
		`OPPush:
		begin
			stage1dest = sp +1;
			stage1src = 0;
			stage0preloaded = 0;
			sp = sp + 1;
		end
	
		`OPNop:
		begin
			stage1dest = 0;
			stage1src = 0;
		end

 		default:
		begin
			stage1dest = 0;
			stage1src = 0;
		end

	endcase
end

// -----------------------------stage 2----------------------------------
// Memory Fetch
always @(posedge clk)
begin
	stage2src = stage1src;
	stage2dest = stage1dest;
	stage2op = stage1op;
	stage2arg = stage1arg;
	stage2destval = regfile[stage2dest];
	stage2srcval = regfile[stage2src];
	stage2preloaded = stage1preloaded;
	stage2preReg = stage1preReg;
end

// -----------------------------stage 3----------------------------------
// ALU/Memory write
always @(posedge clk)
begin
	stage3op = stage2op;
	stage3arg = stage2arg;
	stage3src = stage2src;
	stage3dest = stage2dest;
	stage3destval = stage2destval;
	stage3srcval = stage3srcval;
	stage3preloaded = stage2preloaded;
	stage3preReg = stage2preReg;
	case (stage3op)
		`OpNoArg:
		begin
			case (stage3arg)
				`OpDup:
				begin
					regfile[stage3dest] = stage3srcval;
				end

				`OpLoad:
				begin
					regfile[stage3dest] = mainmem[stage3destval];
				end

				`OpRet:
				begin
					stage0op = `OpNop;
					stage1op = `OpNop;
					stage2op = `OpNop;
					pc = stage3srcval;
				end

				`OpStore:
				begin
				end

				`OpSys:
				begin
				end

				`OpTest:
				begin
				end
				
				default:
				begin
					aluIN1 = stage3destval;
					aluIN2 = stage3srcval;
					aluOP = stage3arg;
					stage3destval = aluRES;
					regfile[stage3dest] = stage3destval;
				end
			endcase
		end
	endcase
end
endmodule

module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
integer i = 0;
processor PE(halted, reset, clk);
initial begin
//   $dumpfile;
//   $dumpvars(0, PE);
  #10 reset = 1;
  #10 reset = 0;
  while (!halted && (i < 200)) begin
    #10 clk = 1;
    #10 clk = 0;
    i=i+1;
  end
  $finish;
end
endmodule


