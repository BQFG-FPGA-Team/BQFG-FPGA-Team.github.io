module fpu_multiplier (
    input logic [31:0] float1,      
    input logic [31:0] float2,      
    output logic [31:0] result
);
    // Extract sign, exponent, and mantissa

    // Sign is stored in MSB
    logic sign_a = float1[31];
    logic sign_b = float2[31];

    // Exponent is from 30:23
    logic [7:0] exp_a = float1[30:23];
    logic [7:0] exp_b = float2[30:23];

    // Handle zeroes, infinity, nan, and denormals
    logic is_zero_a = (exp_a == 8'd0) && (float1[22:0] == 23'd0);
    logic is_zero_b = (exp_b == 8'd0) && (float2[22:0] == 23'd0);
    logic is_inf_a = (exp_a == 8'hFF) && (float1[22:0] == 23'd0);
    logic is_inf_b = (exp_b == 8'hFF) && (float2[22:0] == 23'd0);
    logic is_nan_a = (exp_a == 8'hFF) && (float1[22:0] != 23'd0);
    logic is_nan_b = (exp_b == 8'hFF) && (float2[22:0] != 23'd0);
    logic is_denormal_a = (exp_a == 8'd0) && (float1[22:0] != 23'd0);
    logic is_denormal_b = (exp_b == 8'd0) && (float2[22:0] != 23'd0);

    // Add implicit '1' bit for normalized numbers, or '0' for denormals
    logic [23:0] sig_a = {(exp_a != 8'd0), float1[22:0]};
    logic [23:0] sig_b = {(exp_b != 8'd0), float2[22:0]};
    
    // Handle denormal inputs
    logic [8:0] true_exp_a = is_denormal_a ? 9'd1 : {1'b0, exp_a};
    logic [8:0] true_exp_b = is_denormal_b ? 9'd1 : {1'b0, exp_b};

    // Result sign is XOR of input signs
    logic sign_result = sign_a ^ sign_b;

    // Add exponents and remove bias
    logic [9:0] exp_sum = true_exp_a + true_exp_b - 10'd127;

    // Significand multiplication (48-bit result)
    logic [47:0] sig_mult = sig_a * sig_b;

    // Normalize result
    logic [47:0] pre_round_sig;
    logic [9:0] pre_round_exp;
    
    // Check if we need to shift for normalization
    if (sig_mult[47]) begin
        pre_round_sig = sig_mult;
        pre_round_exp = exp_sum + 10'd1;
    end
    else begin
        pre_round_sig = sig_mult << 1;
        pre_round_exp = exp_sum;
    end

    // IEEE 754 round-to-nearest-even (round-to-nearest, ties to even)
    logic round_bit = pre_round_sig[23];
    logic sticky_bit = |pre_round_sig[22:0];
    logic guard_bit = pre_round_sig[24];
    logic round_up = guard_bit && (round_bit || sticky_bit || pre_round_sig[25]);
    
    // Perform rounding
    logic [23:0] rounded_sig = pre_round_sig[47:24] + round_up;
    logic [9:0] final_exp = pre_round_exp;
    
    // Check if rounding caused overflow in significand
    if (rounded_sig[24]) begin
        rounded_sig = rounded_sig >> 1;
        final_exp = final_exp + 10'd1;
    end
    
    // Check for overflow and underflow
    logic overflow = (final_exp >= 10'd255);
    logic underflow = $signed(final_exp) <= 0;
    
    // Prepare final values
    logic [7:0] exp_result;
    logic [22:0] sig_result;

    // Handle special cases and results
    always_comb begin
        if (is_nan_a || is_nan_b) begin
            // NaN propagation
            result = 32'h7FC00000; // Quiet NaN
        end
        else if ((is_inf_a && is_zero_b) || (is_inf_b && is_zero_a)) begin
            // Infinity * Zero = NaN
            result = 32'h7FC00000; // Quiet NaN
        end
        else if (is_inf_a || is_inf_b) begin
            // Infinity * anything = Infinity with appropriate sign
            result = {sign_result, 8'hFF, 23'd0};
        end
        else if (is_zero_a || is_zero_b) begin
            // Zero * anything = Zero with appropriate sign
            result = {sign_result, 31'd0};
        end
        else if (overflow) begin
            // Overflow to infinity
            result = {sign_result, 8'hFF, 23'd0};
        end
        else if (underflow) begin
            // Handle underflow - two cases:
            if ($signed(final_exp) < -23) begin
                // Complete underflow - result is zero
                result = {sign_result, 31'd0};
            end
            else begin
                // Denormal result
                logic [22:0] denorm_sig = rounded_sig[23:1] >> -$signed(final_exp);
                result = {sign_result, 8'd0, denorm_sig};
            end
        end
        else begin
            // Normal case
            exp_result = final_exp[7:0];
            sig_result = rounded_sig[22:0];
            result = {sign_result, exp_result, sig_result};
        end
    end
endmodule