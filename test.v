module testVect;
	reg [2:0] testV [1:0] [5:0];
	initial begin
	testV[1][0] <= 0;
		repeat (9) begin
			#5;
			testV[1][0] <= testV[1][0] + 1;
			$display("val:\t%d", testV[1][0]);
		end
	end
endmodule
