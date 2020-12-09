`timescale 1ns / 1ps

module HannFSM_tb;



    logic clk;
    logic sample_trigger;
    logic [11:0] data_in;
    logic rst;
    
    logic fft_last;
    logic [9:0] fft_data_counter;
    logic [15:0] fft_data;
    logic fft_valid;
    logic fft_ready;
    logic [2:0] state;
    
    
    // generate a HannFSM with a 32 window size for debugging
    hannFSM #(.FRAMESIZE(32)) uut (.clk_100mhz(clk), .rst(rst), 
                                    .sample_trigger(sample_trigger), 
                                    .adc_data(data_in), .fft_last(fft_last), 
                                    .fft_data_counter(fft_data_counter), 
                                    .fft_data(fft_data), .fft_valid(fft_valid), 
                                    .state(state), .fft_ready(fft_ready));
    
    
    
    always #5 clk = ~clk;
    always #60 data_in = data_in + 1; // just to give some differentiatable data
    
    
    initial begin
        clk = 0;
        data_in = 255; 
        rst = 0;
        fft_ready = 1;
        #10;
        rst = 1;
        #20
        rst = 0;
        for (int i = 0; i < 150; i = i + 1) begin
            #1190;
            sample_trigger = 1; // trigger a sample every 60 times the data has changed
            #10;
            sample_trigger = 0; 
        end
         
    end
    
endmodule
