module qr_decomposition (
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic done1, // the cordic out is ready
    input logic signed  [31:0] a, b, c,
    input logic signed  [31:0] d, e, f,
    input logic signed  [31:0] g, h, i,
    input logic signed  [31:0] cor_x_out,
    input logic signed  [31:0] cor_y_out,
    input logic signed  [31:0] cor_z_out,
    output logic               enable_out,
    output logic signed [31:0] cor_x_in,
    output logic signed [31:0] cor_y_in,
    output logic signed [31:0] cor_z_in,
    output logic               select_out, // for kind of cordic
    output logic signed [31:0] a_out, b_out, c_out,
    output logic signed [31:0] d_out, e_out, f_out,
    output logic signed [31:0] g_out, h_out, i_out, 
    output logic signed [31:0] Q [2:0][2:0],
    output logic               data_valid
);

logic [5:0] current_state, next_state;
parameter IDLE        = 'b00000,
          phase1_1_in = 'b00001,
          phase1_1_out = 'b00010,
          phase1_2_in = 'b00011,
          phase1_2_out = 'b00100,
          phase1_3_in = 'b00101,
          phase1_3_out = 'b00110,
          phase2_1_in = 'b00111,
          phase2_1_out = 'b01000,
          phase2_2_in = 'b01001,
          phase2_2_out = 'b01010,
          phase2_3_in = 'b01011,
          phase2_3_out = 'b01100,
          phase3_1_in = 'b01101,
          phase3_1_out = 'b01110,
          phase3_2_in = 'b01111,
          phase3_2_out = 'b10000,  
          multiply    = 'b10001;

logic signed [31:0] R [2:0][2:0];
logic signed [31:0] a_prime, b_prime, c_prime, d_prime, e_prime, f_prime;
logic signed [31:0] g_prime, h_prime, i_prime, theta1;
logic signed [31:0] phay1 [2:0][2:0], phay2 [2:0][2:0], phay3 [2:0][2:0];
logic signed [31:0] temp [2:0][2:0]; // Intermediate matrix after phay1 * phay2



// State transition logic
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// Next state logic
always_comb begin
    case(current_state)
        IDLE: begin
            if (enable) 
                next_state = phase1_1_in;
            else 
                next_state = IDLE;
        end
        phase1_1_in: next_state = phase1_1_out;
        phase1_1_out: begin
            if (done1) 
                next_state = phase1_2_in;
            else 
                next_state = phase1_1_out;
        end
        phase1_2_in: next_state = phase1_2_out;
        phase1_2_out: begin
            if (done1) 
                next_state = phase1_3_in;
            else 
                next_state = phase1_2_out;
        end
        phase1_3_in: next_state = phase1_3_out;
        phase1_3_out: begin
            if (done1) 
                next_state = phase2_1_in;
            else 
                next_state = phase1_3_out;
        end
        phase2_1_in: next_state = phase2_1_out;
        phase2_1_out: begin
            if (done1) 
                next_state = phase2_2_in;
            else 
                next_state = phase2_1_out;
        end
        phase2_2_in: next_state = phase2_2_out;
        phase2_2_out: begin
            if (done1) 
                next_state = phase2_3_in;
            else 
                next_state = phase2_2_out;
        end
        phase2_3_in: next_state = phase2_3_out;
        phase2_3_out: begin
            if (done1) 
                next_state = phase3_1_in;
            else 
                next_state = phase2_3_out;
        end
        phase3_1_in: next_state = phase3_1_out;
        phase3_1_out: begin
            if (done1) 
                next_state = phase3_2_in;
            else 
                next_state = phase3_1_out;
        end
        phase3_2_in: next_state = phase3_2_out;
        phase3_2_out: begin
            if (done1) 
                next_state = multiply;
            else 
                next_state = phase3_2_out;
        end
        multiply: begin
            if (data_valid) 
                next_state = IDLE;
            else 
                next_state = multiply;
        end
        default: next_state = IDLE;
    endcase
end

// Output logic
always_comb begin
    // Default values to prevent latches
    cor_x_in = 0;
    cor_y_in = 0;
    cor_z_in = 0;
    select_out = 0;

    case(current_state)
        IDLE: begin
            cor_x_in = 0;
            cor_y_in = 0;
            cor_z_in = 0;
        end
        phase1_1_in: begin
            enable_out = 1;
            cor_x_in = a;
            cor_y_in = d;
            cor_z_in = 0;
            select_out = 1;
        end
        phase1_1_out: begin
            enable_out = 0;
            a_prime = cor_x_out;
            theta1 = cor_y_out;
        end
        phase1_2_in: begin
           enable_out = 1;
            cor_x_in = b;
            cor_y_in = e;
            cor_z_in = theta1;
            select_out = 0;
        end
        phase1_2_out: begin
           enable_out = 0;
            b_prime = cor_x_out;
            e_prime = cor_y_out;
        end
        phase1_3_in: begin
           enable_out = 1;
            cor_x_in = c;
            cor_y_in = f;
            cor_z_in = theta1;
            select_out = 0;
        end
        phase1_3_out: begin
           enable_out = 0;
            c_prime = cor_x_out;
            f_prime = cor_y_out;
            R[0][0] = a_prime;
            R[0][1] = b_prime;
            R[0][2] = c_prime;
            R[1][0] = 0;
            R[1][1] = e_prime;
            R[1][2] = f_prime;
            R[2][0] = g;
            R[2][1] = h;
            R[2][2] = i;
            phay1[0][0] = c_prime;
            phay1[0][1] = f_prime;
            phay1[0][2] = 0;
            phay1[1][0] = -f_prime;
            phay1[1][1] = c_prime;
            phay1[1][2] = 0;
            phay1[2][0] = 0;
            phay1[2][1] = 0;
            phay1[2][2] = 1;
        end
        phase2_1_in: begin
           enable_out = 1;
            cor_x_in = R[0][0];
            cor_y_in = R[2][0];
            cor_z_in = 0;
            select_out = 1;
        end
        phase2_1_out: begin
           enable_out = 0;
            a_prime = cor_x_out;
            theta1 = cor_y_out;
        end
        phase2_2_in: begin
           enable_out = 1;
            cor_x_in = R[0][1];
            cor_y_in = R[2][1];
            cor_z_in = theta1;
            select_out = 0;
        end
        phase2_2_out: begin
           enable_out = 0;
            b_prime = cor_x_out;
            h_prime = cor_y_out;
        end
        phase2_3_in: begin
           enable_out = 1;
            cor_x_in = R[0][2];
            cor_y_in = R[2][2];
            cor_z_in = theta1;
            select_out = 0;
        end
        phase2_3_out: begin
           enable_out = 0;
            c_prime = cor_x_out;
            i_prime = cor_y_out;
            R[0][0] = a_prime;
            R[0][1] = b_prime;
            R[0][2] = c_prime;
            R[2][0] = 0;
            R[2][1] = h_prime;
            R[2][2] = i_prime;
            phay2[0][0] = c_prime;
            phay2[0][1] = i_prime;;
            phay2[0][2] = 0;
            phay2[1][0] = 0;
            phay2[1][1] = 1;
            phay2[1][2] = 0;
            phay2[2][0] = - i_prime;
            phay2[2][1] = c_prime;
            phay2[2][2] = 1;
        end
        phase3_1_in: begin
           enable_out = 1;
            cor_x_in = R[1][1];
            cor_y_in = R[2][1];
            cor_z_in = 0;
            select_out = 1;
        end
        phase3_1_out: begin
           enable_out = 0;
            e_prime = cor_x_out;
            theta1 = cor_y_out;
        end
        phase3_2_in: begin
           enable_out = 1;
            cor_x_in = R[1][2];
            cor_y_in = R[2][2];
            cor_z_in = theta1;
            select_out = 0;
        end
        phase3_2_out: begin
           enable_out = 0;
            f_prime = cor_x_out;
            i_prime = cor_y_out;
            R[1][1] = e_prime;
            R[1][2] = f_prime;
            R[2][1] = 0;
            R[2][2] = i_prime;
            phay3[0][0] = 1;
            phay3[0][1] = 0;
            phay3[0][2] = 0;
            phay3[1][0] = 0;
            phay3[1][1] = f_prime;
            phay3[1][2] = i_prime;
            phay3[2][0] = 0;
            phay3[2][1] = - i_prime;
            phay3[2][2] = f_prime;
        end
        multiply: begin
             for (int i = 0; i < 3; i++) begin
               for (int j = 0; j < 3; j++) begin
                 temp[i][j] = 0;
                    for (int k = 0; k < 3; k++) begin
                      temp[i][j] = temp[i][j] + (phay1[i][k] * phay2[k][j]);
                    end
               end
            end
              for (int i = 0; i < 3; i++) begin
                 for (int j = 0; j < 3; j++) begin
                   Q[i][j] = 0;
                   for (int k = 0; k < 3; k++) begin
                     Q[i][j] = Q[i][j] + (temp[i][k] * phay3[k][j]);
                   end
                end
            end
           
            data_valid = 1;
        end
    endcase
end

always_comb begin
   a_out= R[0][0];
   b_out= R[0][1]; 
   c_out= R[0][2];
   d_out= R[1][0];
   e_out= R[1][1];
   f_out= R[1][2];
   g_out= R[2][0];
   h_out= R[2][1];
   i_out= R[2][2];
   
end   
endmodule
