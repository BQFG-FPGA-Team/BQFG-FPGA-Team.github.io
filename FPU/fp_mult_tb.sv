`timescale 1ns / 1ps

module fpu_multiplier_tb;

    reg [31:0] a, b;
    wire [31:0] result;

    // Instantiate a multiplier module
    fpu_multiplier uut (
        .float1(a),
        .float2(b),
        .result(result)
    );

    // Helper task to print results
    task display_result;
        begin
            $display("a = 0x%h, b = 0x%h => result = 0x%h", a, b, result);
        end
    endtask

    initial begin
        // Test 1: 1.0 * 1.0 = 1.0
        // 1.0 = 0x3F800000
        a = 32'h3F800000;
        b = 32'h3F800000;
        #10;
        display_result();

        // Test 2: 2.0 * 0.5 = 1.0
        // 2.0 = 0x40000000, 0.5 = 0x3F000000
        a = 32'h40000000;
        b = 32'h3F000000;
        #10;
        display_result();

        // Test 3: -1.5 * 2.0 = -3.0
        // -1.5 = 0xBFC00000, 2.0 = 0x40000000
        a = 32'hBFC00000;
        b = 32'h40000000;
        #10;
        display_result();

        // Test 4: 0.0 * 123.456 = 0.0
        a = 32'h00000000;
        b = 32'h42F6E979; // Approx 123.456 in IEEE 754
        #10;
        display_result();

        // Test 5: Random values
        a = 32'h41200000; // 10.0
        b = 32'hC1200000; // -10.0
        #10;
        display_result(); // Expect -100.0 (0xC2C80000)

        // End simulation
        $finish;
    end
endmodule