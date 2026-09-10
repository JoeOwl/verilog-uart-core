module half_adder_DF (
	input A,
	input B,
	output Sum,
	output Cout
);
assign Sum = A ^ B;
assign Cout = A & B;
endmodule

module half_adder_S (
	input A,
	input B,
	output Sum,
	output Cout
);
xor(Sum, A, B);
and(Cout, A, B);
endmodule

module full_adder (
	input A,
	input B,
	input Cin,
	output Sum,
	output Cout
);
	wire sum0;
	wire cout0;
	wire cout1;
	half_adder_DF h1_DF(A, B, sum0, cout0);
	half_adder_S h2_S(Cin, sum0, Sum, cout1);
	assign Cout = cout0 | cout1;

endmodule