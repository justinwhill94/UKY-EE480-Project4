//Things we probably need
`define WORD        [15:0]
`define OPCODE      [15:12]
`define STATE       [6:0]

//Registers we need
`define REGSIZE     [255:0]
`define MEMSIZE     [65535:0]
`define HALFWORD    [7:0]
`define IMMED12     [11:0]
`define IMMED16     [15:0]
`define PRE         [3:0]

//Normal curOPs
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

`define NOARG   4'b0000

`define Start   5'b11111
`define Start1  5'b11110

module processor(halt0, halt1, reset0, reset1, clk);
    input reset0;
    input reset1;
    input clk;

    output reg halt0;
    output reg halt1;

    //Two one-bit regs
    reg torf [1:0];
    reg loaded [1:0];

    //Other regs
    reg `PRE preload [1:0];
    reg `WORD pc [1:0];
    reg `HALFWORD sp [1:0];
    reg `WORD regfile `REGSIZE; //4096 big, 256 16-bit regs are initialized
    reg `WORD memory `MEMSIZE;  //???
    reg `WORD curOP [1:0];
    reg `IMMED12 immed12;
    reg `IMMED16 immed16;
    reg `STATE s [1:0];

    always @(reset)
    begin
        halt = 1'b0;
        pc = 16'b0;
        s = `Start;
        torf[0] = 1'b0;
        torf[1] = 1'b0;
        loaded[0] = 1'b0;
        loaded[1] = 1'b0;
        preload[0] = 4'b0;
        preload[1] = 4'b0;
        sp[0] = 8'b0;
        sp[1] = 8'b0;
        s[0] = `Start;
        s[1] = `Start + 1;
        $readmemh0(regfile);
        $readmemh1(memory);

    end

    always @(posedge clk)
    begin
        case (s)
            `Start: begin
                    curOP <= memory[pc];
                    s <= `Start1;
                end

            `Start1: begin
                     pc <= pc + 1;            // bump pc
                     s <= curOP `OPCODE;
                end

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

module testbench;
reg reset[1:0] = 0;
reg clk = 0;
wire halted[1:0];
processor PE(halted[0], halted[1], reset[0], reset[1], clk);
initial begin
  $dumpfile;
  $dumpvars(0, PE);
  #10 reset = 1;
  #10 reset = 0;
  // halt only both threads are halted.
  while (!halted[0] && !halted[1]) begin
    #10 clk = 1;
    #10 clk = 0;
  end
  $finish;
end
endmodule
