module Edge_detector(input clk, rst_n, a, b, output Y0, output reg Y1);
	
	parameter S0 = 0;
	parameter S1 = 1;
	parameter S2 = 2;

	reg [1:0] cs, ns;

	always @(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				begin
					cs <= S0;
				end
			else
				begin
					cs <= ns;
				end
		end

	always @(*)
		begin
			ns = S0;
			case (cs)
				S0:
					begin
						Y1 = 1;
						if(!a)
							begin
								ns = S0;
							end
						else if(a & b)
							begin
								ns = S2;
							end
						else
							begin
								ns = S1;
							end
					end
				S1:
					begin
						Y1 = 1;
						if(a)
							begin
								ns = S0;
							end
						else
							begin
								ns = S1;
							end
					end

				S2:
					begin
						ns = S0;
					end

				default: ns = S0;
			endcase
		end

	assign Y0 = a&b&(cs == S0) ? 1 : 0;

endmodule