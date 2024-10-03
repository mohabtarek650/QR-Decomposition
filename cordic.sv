module cordic (
    input logic clk,
    input logic rst_n,
    input logic select,
    input logic enable,
    input logic signed [31:0] x_in,
    input logic signed [31:0] y_in,
    input logic signed [31:0] z_in,
    output logic signed [31:0] x_out,
    output logic signed [31:0] y_out,
    output logic signed [31:0] z_out,
    output logic done
);
    // Parameters for CORDIC
    parameter ITER = 15;

    // Internal registers and wires
    logic signed [31:0] x [0:ITER-1];
    logic signed [31:0] y [0:ITER-1];
    logic signed [31:0] z [0:ITER-1];
    logic done_1;

    // Arctangent lookup table
    // q8.24 fixed-point format
    logic signed [31:0] arctan_table [0:14] = '{
        32'sb00000000110010010000111111011010,
        32'sb00000000011101101011000110011100,
        32'sb00000000001111101011011011101011,
        32'sb00000000000111111101010110111010,
        32'sb00000000000011111111101010101101,
        32'sb00000000000001111111111101010101,
        32'sb00000000000000111111111111101010,
        32'sb00000000000000011111111111111101,
        32'sb00000000000000001111111111111111,
        32'sb00000000000000000111111111111111,
        32'sb00000000000000000011111111111111,
        32'sb00000000000000000001111111111111,
        32'sb00000000000000000000111111111111,
        32'sb00000000000000000000011111111111,
        32'sb00000000000000000000001111111111
    };
    logic signed [31:0] scaling_factor = 32'b00000000100110110111010011101101;  // Adjust as needed
    logic signed [63:0] x_out_64,y_out_64;
    always_comb begin
        if (enable) begin
            // Initialize inputs
            x[0] = x_in;
            y[0] = y_in;
            z[0] = z_in;

            for (int i = 0; i < ITER-1; i++) begin
                if (!select) begin
                    // Rotational Mode
                    if (z[i] >= 0) begin
                        x[i+1] = x[i] - (y[i] >>> i);
                        y[i+1] = y[i] + (x[i] >>> i);
                        z[i+1] = z[i] - arctan_table[i];
                    end else begin
                        x[i+1] = x[i] + (y[i] >>> i);
                        y[i+1] = y[i] - (x[i] >>> i);
                        z[i+1] = z[i] + arctan_table[i];
                    end
                end else begin
                    // Vectoring Mode
                    if (y[i] >= 0) begin
                        x[i+1] = x[i] + (y[i] >>> i);
                        y[i+1] = y[i] - (x[i] >>> i);
                        z[i+1] = z[i] + arctan_table[i];
                    end else begin
                        x[i+1] = x[i] - (y[i] >>> i);
                        y[i+1] = y[i] + (x[i] >>> i);
                        z[i+1] = z[i] - arctan_table[i];
                    end
                end
            end

            // Assert done after last iteration
            done_1 = 1;
            x_out_64=x[ITER-1] * scaling_factor;
            y_out_64=y[ITER-1] * scaling_factor;
        end else begin
            done_1 = 0;
        end
    end

    // Output the final iteration values
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            done <= 0;
            x_out <= 0;
            y_out <= 0;
            z_out <= 0;
        end else begin
            // Scaling factor to convert the final result back to proper format
            // Multiply by scaling factor, considering fixed-point format (q8.24)
            x_out <= x_out_64[55:24];  // Scaling down to correct fractional bits
            y_out <= y_out_64[55:24];
            z_out <= z[ITER-1];
            done <= done_1;
        end
    end
endmodule


// module cordic (
//     input logic clk,
//     input logic rst_n,
//     input logic select,
//     input logic enable,
//     input logic signed [31:0] x_in,
//     input logic signed [31:0] y_in,
//     input logic signed [31:0] z_in,
//     output logic signed [31:0] x_out,
//     output logic signed [31:0] y_out,
//     output logic signed [31:0] z_out,
//     output logic done
// );
//     // Parameters for CORDIC
//     parameter ITER = 15;

//     // Internal registers and wires
//     logic signed [31:0] x [0:ITER-1];
//     logic signed [31:0] y [0:ITER-1];
//     logic signed [31:0] z [0:ITER-1];
//     logic [3:0] counter;  // 4-bit counter for 15 iterations

//     // Arctangent lookup table
//     // q8.24 fixed-point format
//     logic signed [31:0] arctan_table [0:14] = '{
//         32'sb00000000110010010000111111011010,
//         32'sb00000000011101101011000110011100,
//         32'sb00000000001111101011011011101011,
//         32'sb00000000000111111101010110111010,
//         32'sb00000000000011111111101010101101,
//         32'sb00000000000001111111111101010101,
//         32'sb00000000000000111111111111101010,
//         32'sb00000000000000011111111111111101,
//         32'sb00000000000000001111111111111111,
//         32'sb00000000000000000111111111111111,
//         32'sb00000000000000000011111111111111,
//         32'sb00000000000000000001111111111111,
//         32'sb00000000000000000000111111111111,
//         32'sb00000000000000000000011111111111,
//         32'sb00000000000000000000001111111111
//     };
//     logic signed [31:0] scaling_factor = 32'b00000000100110110111010011101101;  // Adjust as needed
//     logic signed [63:0] x_out_64, y_out_64;

//     // Sequential logic with counter for pipeline iterations
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             // Reset state
//             counter <= 0;
//             done <= 0;
//         end else if (enable && counter <(ITER-1)) begin
//             if (counter == 0) begin
//                 // Initialize inputs on first clock cycle
//                 x[0] <= x_in;
//                 y[0] <= y_in;
//                 z[0] <= z_in;
//             end else begin
//                 // Perform CORDIC iteration
//                 if (!select) begin
//                     // Rotational Mode
//                     if (z[counter] >= 0) begin
//                         x[counter+1] <= x[counter] - (y[counter] >>> (counter));
//                         y[counter+1] <= y[counter] + (x[counter] >>> (counter));
//                         z[counter+1] <= z[counter] - arctan_table[counter];
//                     end else begin
//                         x[counter+1] <= x[counter] + (y[counter] >>> (counter));
//                         y[counter+1] <= y[counter] - (x[counter] >>> (counter));
//                         z[counter+1] <= z[counter] + arctan_table[counter];
//                     end
//                 end else begin
//                     // Vectoring Mode
//                     if (y[counter] >= 0) begin
//                         x[counter+1] <= x[counter] + (y[counter] >>> (counter));
//                         y[counter+1] <= y[counter] - (x[counter] >>> (counter));
//                         z[counter+1] <= z[counter] + arctan_table[counter];
//                     end else begin
//                         x[counter+1] <= x[counter] - (y[counter] >>> (counter));
//                         y[counter+1] <= y[counter] + (x[counter] >>> (counter));
//                         z[counter+1] <= z[counter] - arctan_table[counter];
//                     end
//                 end
//             end


//             // Assert done signal and calculate output after the final iteration
//             if (counter == ITER-2) begin
//                 done <= 1;
//                 x_out_64 <= x[ITER-1] * scaling_factor;
//                 y_out_64 <= y[ITER-1] * scaling_factor;
//                counter <= 0;
//             end else begin
//                 done <= 0;
//                 // Increment counter
//                 counter <= counter + 1;
//             end
//         end else if (!enable) begin
//             // Reset counter if enable is deasserted
//             counter <= 0;
//         end
//     end

//     // Output the final values
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             // Reset output
//             x_out <= 0;
//             y_out <= 0;
//             z_out <= 0;
//         end else if (done) begin
//             // Scaling and output assignment
//             x_out <= x_out_64[55:24];  // Scale to match fixed-point format
//             y_out <= y_out_64[55:24];
//             z_out <= z[ITER-1];
//         end
//     end
// endmodule