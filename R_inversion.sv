module R_inversion (
  
    input logic clk,
    input logic rst_n,
    input logic signed [31:0] a_in, b_in, c_in,
    input logic signed [31:0] d_in, e_in, f_in,
    input logic signed [31:0] g_in, h_in, i_in, 
    input logic signed [31:0] Q [2:0][2:0],
    input logic               start,
    output logic signed [31:0] A_inv [2:0][2:0],
    output logic data_valid
  );

    logic [1:0] current_state, next_state;
    logic signed [31:0] r11_inv, r22_inv, r33_inv; // Diagonal inverses
    logic signed [31:0] R [2:0][2:0];
    logic signed [31:0] R_inv [2:0][2:0]; // Inverse of R matrix (3x3)
    logic signed [31:0] Q_T [2:0][2:0];
    logic done;
    typedef enum logic [1:0] {
        IDLE,
        INVERT_DIAGONAL,
        INVERT_OFF_DIAGONAL,
        DONE
    } state_t;
    
always_comb begin
    R[0][0] = a_in;
    R[0][1] = b_in; 
    R[0][2] = c_in;
    R[1][0] = d_in;
    R[1][1] = e_in;
    R[1][2] = f_in;
    R[2][0] = g_in;
    R[2][1] = h_in;
    R[2][2] = i_in;
    Q_T[0][0] = Q[0][0];
    Q_T[0][1] = Q[1][0];
    Q_T[0][2] = Q[2][0];
    Q_T[1][0] = Q[0][1];
    Q_T[1][1] = Q[1][1];
    Q_T[1][2] = Q[2][1];
    Q_T[2][0] = Q[0][2];
    Q_T[2][1] = Q[1][2];
    Q_T[2][2] = Q[2][2];
   
end   

    // State Transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Next State Logic
    always_comb begin
        case (current_state)
            IDLE: 
                if (start)
                    next_state = INVERT_DIAGONAL;
                else
                    next_state = IDLE;
            INVERT_DIAGONAL:
                next_state = INVERT_OFF_DIAGONAL;
            INVERT_OFF_DIAGONAL:
                next_state = DONE;
            DONE:
                next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    // Diagonal Inversion
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r11_inv <= 0;
            r22_inv <= 0;
            r33_inv <= 0;
            R_inv[0][0] <= 0;
            R_inv[1][1] <= 0;
            R_inv[2][2] <= 0;
        end
        else if (current_state == INVERT_DIAGONAL) begin
            // Invert diagonal elements (if non-zero)
            r11_inv <= (R[0][0] != 0) ? (1 << 16) / R[0][0] : 0;  // Fixed-point inversion (1/R)
            r22_inv <= (R[1][1] != 0) ? (1 << 16) / R[1][1] : 0;
            r33_inv <= (R[2][2] != 0) ? (1 << 16) / R[2][2] : 0;

            // Store the inverted diagonal elements
            R_inv[0][0] <= r11_inv;
            R_inv[1][1] <= r22_inv;
            R_inv[2][2] <= r33_inv;
        end
    end

    // Off-diagonal Inversion using Back Substitution
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            R_inv[0][1] <= 0;
            R_inv[0][2] <= 0;
            R_inv[1][2] <= 0;
        end
        else if (current_state == INVERT_OFF_DIAGONAL) begin
            // Invert the off-diagonal elements using back substitution
            
            // R_inv[1,2] = R[1,2] / (R[1,1] * R[2,2])
            R_inv[1][2] <= ((R[1][2] * r22_inv * r33_inv) >> 16);  // Fixed-point multiplication

            // R_inv[0,1] = -R[0,1] / (R[0,0] * R[1,1])
            R_inv[0][1] <= -((R[0][1] * r11_inv * r22_inv) >> 16);  // Fixed-point multiplication

            // R_inv[0,2] = -R[0,2] / R[0,0] - (R[0,1] * R[1,2]) / (R[0,0] * R[1,1] * R[2,2])
            R_inv[0][2] <= -(((R[0][2] * r11_inv * r33_inv) >> 16) + 
                            ((R[0][1] * R[1][2] * r11_inv * r22_inv * r33_inv) >> 32));  // Second-order fixed-point multiplication
        end
    end

    assign done = (current_state == DONE);
always_comb begin
   if(done)begin
      for (int i = 0; i < 3; i++) begin
               for (int j = 0; j < 3; j++) begin
                 A_inv[i][j] = 0;
                    for (int k = 0; k < 3; k++) begin
                      A_inv[i][j] = A_inv[i][j] + (R_inv[i][k] * Q_T[k][j]);
                    end
               end
            end
     data_valid = 1;
   end else begin
     data_valid = 0;
     end
end   
endmodule