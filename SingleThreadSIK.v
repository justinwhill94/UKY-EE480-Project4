// -----------------------------Size parameters----------------------------------
`define WORD    [15:0]
`define OP      [4:0]
`define ARG		[11:0]
`define Opcode	[15:12]
`define Dest    [11:6]
`define Src	    [5:0]
`define REGSIZE [63:0]
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

always @op, in1, in2) 
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
reg `WORD regile  `REGSIZE;
reg `WORD mainmem  `MEMSIZE;
reg `WORD ir;
reg `OP stage0op, stage1op, stage2op, stage3op;
reg `ARG stage0arg,stage1arg,stage2arg,stage3arg
reg `WORD stage1src, stage2src, stage3src;
reg `WORD stage1dest, stage2dest, stage3dest;
reg `WORD stage2destval, stage3destval;
reg `WORD stage2srcval, stage3srcval;
reg stage1preloaded, stage2preloaded, stage3preloaded;
reg [3:0] stage1preReg, [3:0] stage2preReg, [3:0] stage3preReg
reg torf;

reg `WORD pc ;
reg thread;

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
			stage1preloaded = 0;
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
			stage1preloaded = 0;
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

				stage1preloaded = 0;
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

				stage1preloaded = 0;
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
		end
	
		`OPPush:
		begin
			stage1dest = sp +1;
			stage1src = 0;
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

	endcase
end

// -----------------------------stage 3----------------------------------
// ALU/Memory write
always @(posedge clk)
begin
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
/*
// opcode values, also state numbers
`define OPadd	  4'b0000
`define OPinvf	4'b0001
`define OPaddf	4'b0010
`define OPmulf	4'b0011
`define OPand	4'b0100
`define OPor	4'b0101
`define OPxor	4'b0110
`define OPany	4'b0111
`define OPdup	4'b1000
`define OPshr	4'b1001
`define OPf2i	4'b1010
`define OPi2f	4'b1011
`define OPld	4'b1100
`define OPst	4'b1101
`define OPjzsz	4'b1110
`define OPli	  4'b1111

// extended opcode values
`define OPjz	5'b10000
`define OPsz	5'b10001
`define OPsys	5'b10010
`define OPnop	5'b11111

// source field values for sys and sz
`define SRCsys	6'b000000
`define SRCsz	6'b000001


module decode(opout, regdst, opin, ir);
output reg `OP opout;
output reg `RNAME regdst;
input wire `OP opin;
input `WORD ir;

    always @(opin, ir) begin
        case (ir `Opcode)   // check top 4 bits of instruction register
          `OPjzsz: begin
                    regdst = 0;		   // no writing
                    case (ir `Src)	           // use Src as extended opcode
                        `SRCsys: opout = `OPsys;
                        `SRCsz: opout = `OPsz;
                        default: opout = `OPjz;
                    endcase
                end
          `OPst: begin opout = ir `Opcode; regdst = 0; end
           default: begin opout = ir `Opcode; regdst = ir `Dest; end
        endcase
    end
endmodule


module alu(result, op, in1, in2);
output reg `WORD result;
input wire `OP op;
input wire `WORD in1, in2;

always @(op, in1, in2) begin
  case (op)
    `OPadd: begin result = in1 + in2; end
    `OPand: begin result = in1 & in2; end
    `OPany: begin result = |in1; end
    `OPor: begin result = in1 | in2; end
    `OPshr: begin result = in1 >> 1; end
    `OPxor: begin result = in1 ^ in2; end
    default: begin result = in1; end
  endcase
end
endmodule


module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile [1:0] `REGSIZE;
reg `WORD mainmem [1:0] `MEMSIZE;
reg `WORD ir, srcval, dstval;
reg ifsquash, rrsquash;
wire `OP op;
wire `RNAME regdst;
wire `WORD res;
reg `OP s0op, s1op, s2op;
reg `RNAME s0src, s0dst, s0regdst, s1regdst, s2regdst;
reg `WORD pc [0:1];
reg `WORD s1srcval, s1dstval;
reg `WORD s2val;
reg switch;
    always @(reset) begin
      halt = 0;
      pc[0] = 0;
      pc[1] = 0;
      s0op = `OPnop;
      s1op = `OPnop;
      s2op = `OPnop;
	  switch = 0;
    //   $readmemh0(regfile);
    //   $readmemh1(mainmem);
    end

    decode mydecode(op, regdst, s0op, ir);
    alu myalu(res, s1op, s1srcval, s1dstval);
    
	always @(*) ir = mainmem[pc[switch]];

    // new pc value
    always @(*) pc[switch] = (((s1op == `OPjz) && (s1dstval == 0)) ? s1srcval : (pc[switch] + 1));

    // IF squash? Only for jz... with 2-cycle delay if taken
    always @(*) ifsquash = ((s1op == `OPjz) && (s1dstval == 0));

    // RR squash? For both jz and sz... extra cycle allows sz to squash li
    always @(*) rrsquash = (((s1op == `OPsz) || (s1op == `OPjz)) && (s1dstval == 0));


    // Instruction Fetch
    always @(posedge clk) if (!halt) begin
      s0op = (ifsquash ? `OPnop : op);
      s0regdst = (ifsquash ? 0 : regdst);
      s0src = ir `Src;
      s0dst = ir `Dest;
	  #5 switch = ~ switch;
    end

    // Register Read
    always @(posedge clk) if (!halt) begin
      s1op = (rrsquash ? `OPnop : s0op);
      s1regdst = (rrsquash ? 0 : s0regdst);
      s1srcval = srcval;
      s1dstval = dstval;
    end

    // ALU and data memory operations
    always @(posedge clk) if (!halt) begin
      s2op = s1op;
      s2regdst = s1regdst;
      s2val = ((s1op == `OPld) ? mainmem[s1srcval] : res);
      if (s1op == `OPst) mainmem[s1srcval] = s1dstval;
      if (s1op == `OPsys) halt = 1;
    end

    // Register Write
    always @(posedge clk) if (!halt) begin
      if (s2regdst != 0) regfile[s2regdst] = s2val;
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

*/
