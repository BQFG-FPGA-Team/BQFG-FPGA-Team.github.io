module tb_matrix_mult();

	// Define local constants
	localparam NUM_VAL_BITS	= 16;
	localparam MAX_VAL_BIT	= NUM_VAL_BITS - 1;
	localparam CHECK_DELAY	= 1ns;
	localparam CLK_PERIOD		= 10ns;
	
	// Test coefficient constants
	localparam COEFF1 		= 16'h8000; // 1.0
	localparam COEFF_5 		= 16'h4000; // 0.5
	localparam COEFF_25 	= 16'h2000; // 0.25
	localparam COEFF_125 	= 16'h1000; // 0.125
	localparam COEFF0  		= 16'h0000; // 0.0
	
	// Define our custom test vector type
	typedef struct
	{
		reg [MAX_VAL_BIT:0] coeffs[3:0];
		reg [MAX_VAL_BIT:0] samples[3:0];
		reg [MAX_VAL_BIT:0] results[3:0];
		reg errors[3:0];
	} testVector;
	
	// Test bench dut port signals
	
	
	task reset_dut;
	begin
		tb_n_reset = 1'b0;
		
		@(posedge tb_clk);
		@(posedge tb_clk);
		
		@(negedge tb_clk);
		tb_n_reset = 1;
		
		@(posedge tb_clk);
		@(posedge tb_clk);
	end
	endtask
	
	always
	begin : CLK_GEN
		tb_clk = 1'b0;
		#(CLK_PERIOD / 2.0);
		tb_clk = 1'b1;
		#(CLK_PERIOD / 2.0);
	end
	
	// DUT portmap
	
	task send_coeff;
		input [MAX_VAL_BIT:0] coeff;
	begin
		@(negedge tb_clk);
		
		tb_coeff = coeff;
		tb_load_coeff = 1'b1;
		
		fork : SCF
		begin
			#(CLK_PERIOD * 1.25);
			tb_load_coeff = 0;
			@(negedge tb_modwait);
			disable SCF;
		end
		begin
			#(10 * CLK_PERIOD);
			$error("Module took too long to load coefficient");
			disable SCF;
		end
		join
	end
  endtask
	
	task load_coeff;
		input [MAX_VAL_BIT:0] coeffs [3:0];
		send_coeff(coeffs[0]);
		send_coeff(coeffs[1]);
		send_coeff(coeffs[2]);
		send_coeff(coeffs[3]);
	end
	endtask
	
	task test_sample;
		input [MAX_VAL_BIT:0] sample_value;
		
		input [MAX_VAL_BIT:0] expected_fir_out;
		input expected_err;
		input expected_one_k_samples;
	begin
		@(negedge tb_clk);
		
		tb_test_sample_num += 1;
		tb_sample = sample_value;
		tb_data_ready = 1'b1;
		
		tb_expected_fir_out = expected_fir_out;
		tb_expected_err			= expected_err;
		tb_expected_one_k_samples = expected_one_k_samples;
		
		fork : DL
		begin
			@(posedge tb_modwait);
			tb_data_ready = 0;
			@(negedge tb_modwait);
			disable DL;
		end
		begin
			#(25 * CLK_PERIOD);
			$error("Module took too long to process the sample");
			disable DL;
		end
		join
		
		@(posedge tb_clk); // Wait for a clock cycle to let things propagate (since we don't require the delay of modwait deassertion to take care of it)
		if(expected_fir_out == tb_fir_out)
		begin
			$info("Test Case #%0d Sample #%0d: Had a correct fir_out value", tb_test_case_num, tb_test_sample_num);
		end
		else
		begin
			$error("Test Case #%0d Sample #%0d: Had an incorrect fir_out value", tb_test_case_num, tb_test_sample_num);
		end
		
		if(expected_err == tb_err)
			$info("Test Case #%0d Sample #%0d: Had a correct err value", tb_test_case_num, tb_test_sample_num);
		end
		else
		begin
			$error("Test Case #%0d Sample #%0d: Had an incorrect err value", tb_test_case_num, tb_test_sample_num);
		end
		
		if(expected_one_k_samples == tb_one_k_samples)
		begin
			$info("Test Case #%0d Sample #%0d: Had a correct one_k_samples value", tb_test_case_num, tb_test_sample_num);
		end
		else
		begin
			$error("Test Case #%0d Sample #%0d: Had an incorrect one_k_samples value", tb_test_case_num, tb_test_sample_num);
		end
		
		#(CLK_PERIOD);
	end
	endtask
	
	
	task test_stream;
		input testVector tv;
		
		integer s;
	begin
		tb_test_case_num += 1;
		reset_dut;
		
		load_coeff(tv.coeffs);
		
		tb_test_sample_num = 0;
		for(s = 0; s < 4; s++)
		begin
			test_sample(tv.samples[s], tv.results[s], tv.errors[s], 1'b0);
		end
	end
	endtask
	
	initial
	begin
		tb_test_vectors = new[2];
		tb_test_vectors[0].coeffs		= {{COEFF_5}, {COEFF1}, {COEFF1}, {COEFF_5}};
		tb_test_vectors[0].samples	= {16'd100, 16'd100, 16'd100, 16'd100};
		tb_test_vectors[0].results	= {16'd0, 16'd50, 16'd50 ,16'd50};
		tb_test_vectors[0].errors		= {1'b0, 1'b0, 1'b0, 1'b0};
		tb_test_vectors[1].coeffs		= tb_test_vectors[0].coeffs;
		tb_test_vectors[1].samples	= {16'd1000, 16'd1000, 16'd100, 16'd100};
		tb_test_vectors[1].results	= {16'd450, 16'd500, 16'd50 ,16'd50};
		tb_test_vectors[1].errors		= {1'b0, 1'b0, 1'b0, 1'b0};
		
	end
	
	initial
	begin
		
	end
endmodule
