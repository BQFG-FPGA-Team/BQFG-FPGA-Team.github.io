task send_bit;
  begin
    // Synchronize to the negative edge of clock to prevent timing errors
    @(negedge tb_clk);
    
    // Activate the shift enable
    tb_shift_enable = 1'b1;

    // Wait for the value to have been shifted in on the rising clock edge
    @(posedge tb_clk);
    #(PROPAGATION_DELAY);

    // Turn off the Shift enable
    tb_shift_enable = 1'b0;
  end
  endtask

  // Task to manage the timing of loading a new bit vector into the shift register
  task load_value;
    input logic [SR_MAX_BIT:0] value_to_load;
  begin
    // Synchronize to the negative edge of clock to prevent timing errors
    @(negedge tb_clk);
    
    // Set the value of the load port (parallel_in)
    tb_parallel_in = value_to_load;

    // Activate the load enable
    tb_load_enable = 1'b1;

    // Wait for the value to have been shifted in on the rising clock edge
    @(posedge tb_clk);
    #(PROPAGATION_DELAY);

    // Turn off the Shift enable
    tb_load_enable = 1'b0;
  end
  endtask

  // Task to contiguosly send a stream of bits through the shift register
  task send_stream;
    input logic [SR_MAX_BIT:0] bits_to_stream;
  begin
    // Load the stream to send in SR sized chunks
    load_value(bits_to_stream);

    // Coniguously stream out all of the bits in the provided input vector
    for(tb_bit_num = 0; tb_bit_num < SR_SIZE_BITS; tb_bit_num++) begin
      // Update the expected output (serial out MSB-first)
      tb_curr_bit_index = (SR_MAX_BIT - tb_bit_num);
      tb_expected_ouput = bits_to_stream[tb_curr_bit_index];
      // Check that the correct value was sent out for this bit
      $sformat(tb_stream_check_tag, "during bit %0d", tb_bit_num);
      check_output(tb_stream_check_tag);
      // Advance to the next bit
      send_bit();
    end
  end
  endtask
