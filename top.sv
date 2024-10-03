module top (
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic signed  [31:0] a, b, c,
    input logic signed  [31:0] d, e, f,
    input logic signed  [31:0] g, h, i,
    output logic signed [31:0] A_inv [2:0][2:0],
    output logic               data_valid
  
  );


  
    logic done1_top;
    logic enable_top;
    logic signed [31:0] cor_x_out_top;
    logic signed [31:0] cor_y_out_top;
    logic signed [31:0] cor_z_out_top;
    logic signed [31:0] cor_x_in_top;
    logic signed [31:0] cor_y_in_top;
    logic signed [31:0] cor_z_in_top;
    logic               select_out_top;
    logic               valid_top;
    logic signed [31:0] Q_top [2:0][2:0];
    logic signed [31:0] a_out, b_out, c_out;
    logic signed [31:0] d_out, e_out, f_out;
    logic signed [31:0] g_out, h_out, i_out;
   
   cordic u0_cordic (
.clk(clk),
.rst_n(rst_n),
.select(select_out_top),
.enable(enable_top),
.x_in(cor_x_in_top),
.y_in(cor_y_in_top),
.z_in(cor_z_in_top),
.x_out(cor_x_out_top),
.y_out(cor_y_out_top),
.z_out(cor_z_out_top),
.done(done1_top) 
);

  qr_decomposition u0_qr_decomposition (
.clk(clk),
.rst_n(rst_n),
.enable(enable),
.done1(done1_top), 
.a(a), 
.b(b), 
.c(c),
.d(d), 
.e(e), 
.f(f),
.g(g), 
.h(h), 
.i(i),
.enable_out(enable_top),
.cor_x_out(cor_x_out_top),
.cor_y_out(cor_y_out_top),
.cor_z_out(cor_z_out_top),
.cor_x_in(cor_x_in_top),
.cor_y_in(cor_y_in_top),
.cor_z_in(cor_z_in_top),
.select_out(select_out_top),
.a_out(a_out), 
.b_out(b_out), 
.c_out(c_out),
.d_out(d_out), 
.e_out(e_out), 
.f_out(f_out),
.g_out(g_out), 
.h_out(h_out), 
.i_out(i_out),
.Q(Q_top),
.data_valid(valid_top)
);

R_inversion u0_R_inversion(
  
.clk(clk),
.rst_n(rst_n),
.a_in(a_out), 
.b_in(b_out), 
.c_in(c_out),
.d_in(d_out), 
.e_in(e_out), 
.f_in(f_out),
.g_in(g_out), 
.h_in(h_out), 
.i_in(i_out), 
.Q(Q_top),
.start(valid_top),
.A_inv(A_inv),
.data_valid(data_valid)
  );
endmodule