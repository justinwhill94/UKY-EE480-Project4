// basic sizes of things
`define WORD	[15:0]
`define RNAME   [5:0]
`define OP	[4:0]
`define Opcode	[15:12]
`define Dest	[11:6]
`define Src	[5:0]
`define REGSIZE [511:0]
`define MEMSIZE [65535:0]

// opcode values, also state numbers
/Normal curOPs
`define OPget       4'b0001
`define OPpop       4'b0010
`define OPput       4'b0011
`define OPcall      4'b0100
`define OPjumpf     4'b0101
`define OPjump      4'b0110
`define OPjumpt     4'b0111
`define OPpush      4'b1000
`define OPpre       4'b1001

//Extended curOPs
`define OPadd       4'b0001
`define OPlt        4'b0010
`define OPsub       4'b0011
`define OPand       4'b0100
`define OPor        4'b0101
`define OPxor       4'b0110
`define OPdup       4'b0111
`define OPret       4'b1000
`define OPsys       4'b1001
`define OPload      4'b1010
`define OPstore     4'b1011
`define OPtest      4'b1100

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
    case (ir `Opcode)
      `OPjzsz: begin
        regdst = 0;		   // no writing
        case (ir `Src)	           // use Src as extended opcode
          `SRCsys: opout = `OPsys;
          `SRCsz: opout = `OPsz;
          default: opout = `OPjz;
        endcase
      end
      `OPst: begin opout = ir `Opcode; regdst <= 0; end
      default: begin opout = ir `Opcode; regdst <= ir `Dest; end
    endcase
  end
end
endmodule


module alu(result, op, sp, pc);
output reg `WORD result;
input wire `OP op;
inout reg `HALFWORD sp;
inout reg `WORD pc;

always @(op) begin
  case (op)
  `OPsys: begin
            halt <= 1;
        end

  `OPpop: begin
            immed12 <= curOP[11:0];
            if(immed12 > sp) begin
                sp <= 0;
            end
            else begin
                sp <= sp - immed12;
            end

            s <= `Start;
        end

    `OPpush: begin
            immed12 <= curOP[11:0];
            if(immed12[11] == 0) begin
                immed12 <= {4'b0000, immed12};
            end
            else begin
                immed12 <= {4'b1111, immed12};
            end

            if (~loaded) begin
                regfile[sp + 1] <= immed12;
            end
            else if (loaded) begin
                regfile[sp+1] <= {preload, immed12};
            end
            sp <= sp + 1;

            s <= `Start;
        end

    `OPget: begin
            immed12 <= curOP[11:0];
            regfile[sp + 1] <= regfile[sp - immed12];
            sp <= sp + 1;

            s <= `Start;
        end


    `OPput: begin
            immed12 <= curOP[11:0];
            regfile[sp - immed12] <= regfile[sp];

            s <= `Start;
        end

    `OPtest: begin
            if (regfile[sp] != 0) begin
                torf <= 1;
                end
            else begin
                torf <= 0;
            end
            sp <= sp - 1;

            s <= `Start;
        end

    `OPcall: begin
            immed12 = curOP[11:0];
            regfile[sp+1] <= pc + 1;
            if (~loaded) begin
                pc <= {(pc << 12), immed12};
            end
            else if (loaded) begin
                pc <= {preload, immed12[11:0]};
            end
            sp <= sp + 1;

            s <= `Start;
        end

    `OPret: begin
            pc <= regfile[sp];
            sp <= sp - 1;

            s <= `Start;
        end

    `OPjumpf: begin
            immed12 = curOP[11:0];
            if (~torf && ~loaded) begin
                pc <= {`OPjumpf, immed12};
            end
            else if (~torf && loaded) begin
                pc <= {preload, immed12};
                loaded <= 0;
            end

            s <= `Start;
        end

    `OPjump: begin
            immed12 = curOP[11:0];
            if (~loaded) begin
                pc <= {`OPjump, immed12};
            end
            else if (loaded) begin
                pc <= {preload, immed12};
                loaded <= 0;
            end

            s <= `Start;
        end

    `OPjumpt: begin
            immed12 = curOP[11:0];
            if (torf && ~loaded) begin
                pc <= {`OPjumpt, immed12};
            end
            else if (torf && loaded) begin
                pc <= {preload, immed12};
                loaded <= 0;
            end

            s <= `Start;
        end

    `OPpre: begin
            preload <= (immed16 >> 12);
            loaded <= 1;

            s <= `Start;
        end

    `NOARG: begin
            case(curOP[3:0])
              `OPadd: begin
                        regfile[sp-1] <= regfile[sp-1] + regfile[sp];
                        sp <= sp - 1;

                        s <= `Start;
                    end

                `OPlt: begin
                        regfile[sp-1] <= regfile[sp-1] < regfile[sp];
                        sp <= sp - 1;

                        s <= `Start;
                    end

                `OPsub: begin
                        regfile[sp-1] <= regfile[sp-1] - regfile[sp];
                        sp <= sp - 1;

                        s <= `Start;
                    end

                `OPor: begin
                    regfile[sp-1] <= regfile[sp-1] | regfile[sp];
                        sp <= sp - 1;

                        s <= `Start;
                    end

                `OPand: begin
                    regfile[sp-1] <= regfile[sp-1] & regfile[sp];
                        sp <= sp - 1;

                        s <= `Start;
                    end

                `OPxor: begin
                    regfile[sp-1] <= regfile[sp-1] ^ regfile[sp];
                        sp <= sp - 1;

                        s <= `Start;
                    end

                `OPdup: begin
                    regfile[sp+1] <= regfile[sp];
                        sp <= sp + 1;

                        s <= `Start;
                    end

                `OPload: begin
                        regfile[sp] <= memory[regfile[sp]];

                        s <= `Start;
                    end

                `OPstore: begin
                        memory[regfile[sp-1]] <= regfile[sp];
                        regfile[sp-1] <= regfile[sp];
                        sp <= sp - 1;

                        s <= `Start;
                    end
                default: halt <= 1;
            endcase
        end
    default: begin halt <= 1; end
  endcase
end
endmodule


module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile `REGSIZE;
reg `WORD mainmem `MEMSIZE;
reg `WORD ir[0:1], srcval, dstval;
reg ifsquash, rrsquash;
wire `OP op[0:1];
wire `RNAME regdst;
wire `WORD res;
reg `OP s0op, s1op, s2op;
reg `RNAME s0src, s0dst, s0regdst, s1regdst, s2regdst;
reg `WORD pc[0:1];
reg `WORD s1srcval, s1dstval;
reg `WORD s2val;
integer count = 0;
reg switch = 0;

always @(reset) begin
  halt = 0;
  pc[0] = 0;
  pc[1] = 1;
  s0op = `OPnop;
  s1op = `OPnop;
  s2op = `OPnop;
  $readmemh0(regfile);
  $readmemh1(mainmem);
end

always @(*) begin
  if(count % 2 == 0)
      switch = 1;
  else
      switch = 0;
  end
  count=count+1;
end

decode mydecode(op, regdst, s0op, ir[switch]);
alu myalu(res, s1op, s1srcval, s1dstval);

always @(*) ir[switch] = mainmem[pc[switch]];

// new pc value
always @(*) pc[1] = (((s1op == `OPjz) && (s1dstval == 0)) ? s1srcval :
                     (pc[1] + 1));

// IF squash? Only for jz... with 2-cycle delay if taken
always @(*) ifsquash = ((s1op == `OPjz) && (s1dstval == 0));

// RR squash? For both jz and sz... extra cycle allows sz to squash li
always @(*) rrsquash = (((s1op == `OPsz) || (s1op == `OPjz)) && (s1dstval == 0));


// Instruction Fetch
always @(posedge clk) if (!halt) begin
  s0op <= (ifsquash ? `OPnop : op);
  s0regdst <= (ifsquash ? 0 : regdst);
  s0src <= ir[switch] `Src;
  s0dst <= ir[switch] `Dest;
  pc[0] <= pc[1];
end

// Register Read
always @(posedge clk) if (!halt) begin
  s1op <= (rrsquash ? `OPnop : s0op);
  s1regdst <= (rrsquash ? 0 : s0regdst);
  s1srcval <= srcval;
  s1dstval <= dstval;
end

// ALU and data memory operations
always @(posedge clk) if (!halt) begin
  s2op <= s1op;
  s2regdst <= s1regdst;
  s2val <= ((s1op == `OPld) ? mainmem[s1srcval] : res);
  if (s1op == `OPst) mainmem[s1srcval] <= s1dstval;
  if (s1op == `OPsys) halt <= 1;
end

// Register Write
always @(posedge clk) if (!halt) begin
  if (s2regdst != 0) regfile[s2regdst] <= s2val;
end
endmodule

module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
integer i = 0;
processor PE(halted, reset, clk);
initial begin
  $dumpfile;
  $dumpvars(0, PE);
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
