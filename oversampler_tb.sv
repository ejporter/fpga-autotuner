`timescale 1ns / 1ps


module oversampler_tb;
    logic clk;
    logic [11:0] data_in;
    logic rst;
    
    logic [11:0] data_out;
    logic sample_trigger;
    
    oversampler  #(.OVERSAMPLE_N_BITS(3), .SAMPLE_COUNT(128)) uut 
    (
    .clk_100mhz(clk),
    .rst(rst), 
    .data_in(data_in), 
    .data_out(data_out), 
    .sample_trigger(sample_trigger)
    );
    
    
    
    always #5 clk = ~clk;
    always #21 data_in = data_in + 50;
    always #27 data_in  = data_in - 64;
    always #189 data_in = data_in - 2;
    
    
    initial begin
        clk = 0;
        data_in = 255; 
        rst = 0;
        #10;
        rst = 1;
        #20
        rst = 0;
        #100000;    
    end
     
    
endmodule
