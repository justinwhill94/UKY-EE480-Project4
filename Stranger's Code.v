`define BIT    [0:0]
`define STATE    [4:0] // was [4:0]
`define TEXT     [15:0]
`define DATA     [31:0]
`define REGSIZE  [15:0]
`define CODESIZE [65535:0]
`define MEMSIZE  [65535:0]

// field locations within instruction
`define O      [15:12]
`define D      [11:8]
`define S      [7:4]
`define A      [3:0]
`define I      [7:0] // was [15:0], think it was error

// opcode and state number
`define OPadd    4'b0000
`define OPaddv   4'b0001
`define OPand    4'b0010
`define OPor     4'b0011
`define OPxor    4'b0100
`define OPshift  4'b0101
`define OPpack   4'b0110
`define OPunpack 4'b0111
`define OPli     4'b1000
`define OPmorei  4'b1001
`define OPany    4'b1010
`define OPanyv   4'b1011
`define OPneg    4'b1100
`define OPnegv   4'b1101
`define OPsys    4'b1110
`define OPextra  4'b1111

// state numbers only for extra opcodes
`define OPst     5'b10000
`define OPld     5'b10001
`define OPjnz    5'b10010
`define OPjz     5'b10011
`define OPnop    5'b10100
`define Start    5'b11111
`define Start1   5'b11110

// STATES FOR FIRST STAGE
`define WAITjz		5'b10110
`define WAITjnz	5'b10111

// state to fetch ALU result
`define OPalu    5'b10101

// arg field values for extra opcodes
`define EXst     4'b0001
`define EXld     4'b0010
`define EXjnz    4'b0011
`define EXjz     4'b0100
`define EXnop    4'b1111

// field locations for vector ops
`define V1       [7:0]
`define V2       [15:8]
`define V3       [23:16]
`define V4       [31:24]

`define PC		 1'b1

`define STAGES    [2:0]
`define S1        2'b00
`define S2        2'b01
`define S3        2'b10

// mask for cutting carry chains
`define MASKaddv 32'h80808080


// TESTBENCH MODULE
module testbench;
   reg   clk;
   wire  done;
   reg   reset;
   processor p1(done, clk, reset);

   initial begin
      reset = 1;
      reset = 0;
      clk = 1;
   end

   always begin
      clk <= ~clk;
      #1;

      if( done ) $finish;
   end


endmodule
// END TESTBENCH MODULE



// PROCESSOR MODULE
module processor(halt, clk, reset);
   output reg halt;
   input      reset, clk;


   // GENERAL REGISTER AND DATA MEM
   reg 	      `TEXT codemem `CODESIZE;
   reg 	      `DATA mainmem `MEMSIZE;
   reg signed	`DATA regfile `REGSIZE;


   // STATE VARS
   reg 	      `STATE states `STAGES;


   // INSTRUCTION MEMORY FIELDS
   reg 	      `O ir_o `STAGES;
   reg 	      `D ir_d `STAGES;
   reg 	      `S ir_s `STAGES;
   reg 	      `A ir_a `STAGES;


   // STAGE 1 SPECIFIC
   reg         `TEXT s1_pc;


   // STAGE 2 SPECIFIC
   reg         `TEXT s2_jump_addr;
   reg			`BIT  s2_jump_rdy = 1'b0;
   reg         `BIT  s2_take_jump = 1'b0;
   reg         `BIT  s2_need_data = 1'b0;
   reg 	      `TEXT s2_mar_out;
   reg 	      `DATA s2_mdr_out;
   reg         `TEXT s2_ld_dest;
   reg         `D    s2_op_dest;
   reg         `BIT  s2_need_alu;
   reg signed  `DATA s2_alu_a, s2_alu_b;


   // STAGE 3 SPECIFIC
   reg         `D    s3_op_dest;
   reg         `TEXT s3_data_dest;
   reg         `DATA s3_mdr_out;
   reg         `BIT  s3_has_data = 1'b0;
   reg signed  `DATA s3_alu_a, s3_alu_b;
   reg         `BIT  s3_has_alu;


   // ALU INSTANTIATION
	wire        `DATA alu_out;
   alu a(alu_out, s3_alu_a, s3_alu_b, ir_o[`S3]);



	// PROCESSOR RESET
   always @(reset) begin
      $readmemh("text.vmem", codemem);
      $readmemh("data.vmem", mainmem);
      $readmemh("reg.vmem", regfile);

      halt = 0;
      regfile[`PC] = 0;
      s1_pc = 0;
      states[`S1] = `Start;
      states[`S2] = `Start;
      states[`S3] = `Start;

      $display("processor reset");
   end



   // STAGE 1 - INSTRUCTION MEM
   always @(posedge clk) begin
      case ( states[`S1] )
      `Start: begin
         $display("\ns1: $u0: %d\n$u1: %d\n$u2: %d\n$u3: %d\n$u4: %d\n$u5: %d\n$u6: %d\n$u7: %d\n$u8: %d\n$u9: %d\n------------------------\n\n", regfile[6], regfile[7], regfile[8], regfile[9], regfile[10], regfile[11],regfile[12], regfile[13], regfile[14], regfile[15]);

         // INSTRUCTION FETCH
         ir_o[`S1] <= codemem[regfile[`PC]] `O;
         ir_d[`S1] <= codemem[regfile[`PC]] `D;
         ir_s[`S1] <= codemem[regfile[`PC]] `S;
         ir_a[`S1] <= codemem[regfile[`PC]] `A;

         states[`S1] <= `Start1;
      end
      `Start1: begin
			// DECODE FOR JUMP DELAY STATES
			case( ir_o[`S1] )
			`OPextra: begin
				case( ir_a[`S1] )
				`OPjnz: begin
					$display("s1: jnz");

					states[`S1] <= `WAITjnz;
				end
				`OPjz: begin
					$display("s1: jz");
					states[`S1] <= `WAITjz;
				end
				default: states[`S1] <= `Start;
				endcase
			end
			default: states[`S1] <= `Start;
			endcase

			regfile[`PC] <= regfile[`PC] + 1;
		   s1_pc <= s1_pc + 1;
   	end

		`WAITjnz: begin
			$display("s1: `WAITjnz");

			if( s2_jump_rdy ) begin
				if( s2_take_jump ) begin
					regfile[`PC] `TEXT <= s2_jump_addr;
				end
				states[`S1] <= `Start;
			end
		end

		`WAITjz: begin
			$display("s1: WAITjz");

			if( s2_jump_rdy ) begin
				if( s2_take_jump ) begin
					regfile[`PC] `TEXT <= s2_jump_addr;
				end
				states[`S1] <= `Start;
			end
		end
      endcase
   end



   // STAGE 2 - WORKING REGISTER MEM
   always @(posedge clk) begin

      // MOVE INSTRUCTION THROUGH PIPE
      ir_o[`S2] <= ir_o[`S1];
      ir_d[`S2] <= ir_d[`S1];
      ir_s[`S2] <= ir_s[`S1];
      ir_a[`S2] <= ir_a[`S1];


      case( states[`S2] )

      `Start: begin
         $display("\ns2: $u0: %d\n$u1: %d\n$u2: %d\n$u3: %d\n$u4: %d\n$u5: %d\n$u6: %d\n$u7: %d\n$u8: %d\n$u9: %d\n------------------------\n\n", regfile[6], regfile[7], regfile[8], regfile[9], regfile[10], regfile[11],regfile[12], regfile[13], regfile[14], regfile[15]);


         if( s3_has_data ) begin
            regfile[s3_data_dest] <= s3_mdr_out;
            s2_need_data <= 0;
         end

         if( s3_has_alu ) begin
            $display("s2: s3 has alu");
            $display("s2: s3_op_dest: %d, alu_out: %d",s3_op_dest, alu_out);
            regfile[s3_op_dest] <= alu_out;
            s2_need_alu <= 0;
         end

         // DECODE INSTRUCTION
         case( ir_o[`S2] )
         `OPextra: begin
            case( ir_a[`S2] )      // EXTENDED OPCODE
            `EXst: begin
               s2_mar_out <= regfile[ir_s[`S2]] `TEXT;
               s2_mdr_out <= regfile[ir_d[`S2]];
            end
            `EXld: begin
               // SET LOOKUP ADDRESS
               s2_mar_out <= regfile[ir_s[`S2]] `TEXT;

               // SAVE DESTINATION
               s2_ld_dest <= regfile[ir_d[`S2]] `TEXT;

               // REQUEST DATA LOOKUP
               s2_need_data <= 1;
            end
            `EXjnz: begin
               $display("s2: jnz");

               s2_take_jump <= regfile[ir_d[`S2]] ? 1 : 0;
               s2_jump_addr <= regfile[ir_s[`S2]] `TEXT;
               s2_jump_rdy  <= 1;
            end
            `EXjz: begin
               $display("s2: jz");

               s2_take_jump <= regfile[ir_d[`S2]] ? 0 : 1;
               s2_jump_addr <= regfile[ir_s[`S2]] `TEXT;
               s2_jump_rdy  <= 1;
            end
            default: states[`S2] <= `Start; // nop
            endcase
         end

         `OPli: begin
            $display("s2: li");
            regfile[ir_d[`S2]] <= (( {ir_s[`S2],ir_a[`S2]} & 8'h80) ? 32'hffffff00 : 0) | ( {ir_s[`S2],ir_a[`S2]} & 8'hff);
         end

         `OPmorei: begin
            $display("s2: morei");
            regfile[ir_d[`S2]] <= (regfile[ir_d[`S2]] << 8) | ( {ir_s[`S2],ir_a[`S2]} & 8'hff);
         end

         `OPpack: begin
            $display("s2: pack");
         end

         `OPunpack: begin
            $display("s2: unpack");
         end

         // REMAINING REQUIRE ALU OP THEN STORE ARE ALU
         default: begin
            s2_alu_a <= regfile[ir_s[`S2]];
            // SPECIAL CASE FOR 4 OPS WITH SECONDARY ARG OF ZERO
            s2_alu_b <= (ir_o[`S2] == `OPneg | ir_o[`S2] == `OPnegv | ir_o[`S2] == `OPany | ir_o[`S2] == `OPanyv) ? 0 : regfile[ir_a[`S2]];

            $display("s2: alu_a: %d, alu_b: %d", s2_alu_a, s2_alu_b);

            s2_op_dest <= ir_d[`S2];
            s2_need_alu <= 1;

            // ALSO NOT JUMPING
            s2_jump_rdy <= 0;
         end
         endcase
      end
      default: $display("s2: default");
      endcase

   end



   // STAGE 3 - ALU AND DATA MEM
   always @(posedge clk) begin
      ir_o[`S3] <= ir_o[`S2];
      ir_d[`S3] <= ir_d[`S2];
      ir_s[`S3] <= ir_s[`S2];
      ir_a[`S3] <= ir_a[`S2];

      $display("\ns3: $u0: %d\n$u1: %d\n$u2: %d\n$u3: %d\n$u4: %d\n$u5: %d\n$u6: %d\n$u7: %d\n$u8: %d\n$u9: %d\n------------------------\n\n", regfile[6], regfile[7], regfile[8], regfile[9], regfile[10], regfile[11],regfile[12], regfile[13], regfile[14], regfile[15]);

		case( states[`S3] )
		`Start: begin
		   if( s2_need_data ) begin
		      s3_mdr_out <= mainmem[s2_mar_out];
		      s3_data_dest <= s2_ld_dest;
		      s3_has_data <= 1;
		   end else begin
		      s3_has_data <= 0;
         end

         if( s2_need_alu ) begin
            s3_alu_a <= s2_alu_a;
            s3_alu_b <= s2_alu_b;
            s3_op_dest <= s2_op_dest;
            s3_has_alu <= 1;
         end else begin
            s3_has_alu <= 0;
         end

		   if( ir_o[`S3] == `OPsys ) begin
		      $display("s3: sys");
		      halt <= 1;
		   end
		end
		default: begin
		   $display("s3 default");
		   halt <= 1;
		end
		endcase // case (s3_state)
   end
endmodule // END PROCESSOR MODULE


module alu(bus_out, a, b, ctrl);
   output reg `DATA bus_out;
   input  signed `DATA a, b;
   input [3:0] 	 ctrl;

   always @(ctrl or a or b) begin
      case(ctrl)
	`OPadd:    bus_out = a + b;
	`OPaddv:   bus_out = ((a & ~(`MASKaddv)) + (b & ~(`MASKaddv))) ^ ((a & `MASKaddv) ^ (b & `MASKaddv));
	`OPand:    bus_out = a & b;
	`OPany:    bus_out = (a ? 1 : 0);
	`OPanyv: begin
	   bus_out[0]  = (a & 32'h000000FF ? 1 : 0);
	   bus_out[8]  = (a & 32'h0000FF00 ? 1 : 0);
	   bus_out[16] = (a & 32'h00FF0000 ? 1 : 0);
	   bus_out[24] = (a & 32'hFF000000 ? 1 : 0);
	end
	`OPor:     bus_out = a | b;
	`OPxor:    bus_out = a ^ b;
	`OPneg:    bus_out = -a;
	`OPnegv: begin
	   bus_out `V1 = -(a `V1);
	   bus_out `V2 = -(a `V2);
	   bus_out `V3 = -(a `V3);
	   bus_out `V4 = -(a `V4);
	end
	`OPshift: begin
	   bus_out = ( (b < 0) ? (a >> -b) : (a << b) );
	end
      endcase // case (ctrl)
   end
endmodule // alu
Contact GitHub API Training Shop Blog About
© 2016 GitHub, Inc. Terms Privacy Security Status Help
