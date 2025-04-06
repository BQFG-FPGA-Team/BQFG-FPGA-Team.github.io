# IEEE 754 Floating-Point Multiplier - Special Cases Handling

This document explains how our SystemVerilog implementation handles IEEE 754 special cases for single-precision floating-point multiplication.

## IEEE 754 Special Cases Overview

The IEEE 754 standard defines several special cases for floating-point numbers:

1. **Zero**: Represented with an exponent of all zeros and a fraction of all zeros. The sign bit can be 0 or 1, representing +0 or -0.
2. **Denormal Numbers**: Represented with an exponent of all zeros and a non-zero fraction. Used to represent values very close to zero.
3. **Infinity**: Represented with an exponent of all ones and a fraction of all zeros. The sign bit determines +∞ or -∞.
4. **NaN (Not a Number)**: Represented with an exponent of all ones and a non-zero fraction. Used to represent invalid operations.
5. **Normal Numbers**: All other representations with normalized significands.

## Special Case Detection

Our implementation detects these special cases with the following logic:

```systemverilog
logic is_zero_a = (exp_a == 8'd0) && (float1[22:0] == 23'd0);
logic is_zero_b = (exp_b == 8'd0) && (float2[22:0] == 23'd0);
logic is_inf_a = (exp_a == 8'hFF) && (float1[22:0] == 23'd0);
logic is_inf_b = (exp_b == 8'hFF) && (float2[22:0] == 23'd0);
logic is_nan_a = (exp_a == 8'hFF) && (float1[22:0] != 23'd0);
logic is_nan_b = (exp_b == 8'hFF) && (float2[22:0] != 23'd0);
logic is_denormal_a = (exp_a == 8'd0) && (float1[22:0] != 23'd0);
logic is_denormal_b = (exp_b == 8'd0) && (float2[22:0] != 23'd0);
```

## IEEE 754 Special Case Multiplication Rules

### NaN Handling
- Any operation involving NaN results in NaN
- NaN propagates through all operations
- Our implementation: `if (is_nan_a || is_nan_b) → result = Quiet NaN`

### Infinity Rules
- Infinity × Normal Number = Infinity (with appropriate sign)
- Infinity × Infinity = Infinity (with appropriate sign)
- Infinity × Zero = NaN (invalid operation)
- Our implementation handles all these cases in the special case logic

### Zero Rules
- Zero × Any non-infinity number = Zero (with appropriate sign)
- Our implementation: `if (is_zero_a || is_zero_b) → result = signed zero`

### Denormal Numbers
Denormal numbers require special handling:
1. For inputs: The implicit bit is 0 instead of 1
2. For outputs: When underflow occurs, we use denormal representation

## Implementation Details

### Denormal Input Handling
```systemverilog
// Add implicit '1' bit for normalized numbers, or '0' for denormals
logic [23:0] sig_a = {(exp_a != 8'd0), float1[22:0]};
logic [23:0] sig_b = {(exp_b != 8'd