module oversampler (
    input logic clk_100mhz,
    input logic [11:0] data_in,
    input logic rst,
    
    output logic sample_trigger,
    output logic [11:0] data_out
);
    
    parameter OVERSAMPLE_N_BITS = 6; // over sample by a factor of 2^6
    parameter SAMPLE_COUNT = 33280; // 100Mhz/desired rate (100Mhz/3khz ~ 33280)
    parameter OVERSAMPLE_COUNT = SAMPLE_COUNT>>OVERSAMPLE_N_BITS; 
    
    logic [15:0] sample_counter;
    logic [9:0] oversample_counter;
    logic [17:0] sum; // size is length of data in + OVERSAMPLE_N_BITS
    
    assign sample_trigger = (sample_counter == SAMPLE_COUNT);
    assign oversample_trigger = (oversample_counter == OVERSAMPLE_COUNT);
    
    always_ff @(posedge clk_100mhz)begin
        if (rst) begin
            sample_counter <= 16'b0;  
            oversample_counter <= 10'b0;  
            sum <= data_in; 
            

        end
        else begin
        
        if (sample_counter == SAMPLE_COUNT)begin // when were starting a new sample averaging
            sample_counter <= 16'b0;  
            oversample_counter <= 10'b0;                      
            sum <= data_in;                        // start off with the initial piece of data
        end else begin
            sample_counter <= sample_counter + 16'b1; // incremement as we go
            oversample_counter <= oversample_counter + 10'b1;
        end
        if (sample_trigger) begin // external trigger so it knows when to take a sample
            data_out <= sum>>OVERSAMPLE_N_BITS; // divide by appropriate factor
        end
        if (oversample_trigger) begin // when we take a new sample for sum
            oversample_counter <= 10'b0;
            sum <= sum + data_in;
        end
        
        end
    end        
endmodule
// oversampler



