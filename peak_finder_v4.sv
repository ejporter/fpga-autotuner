module peak_finder_v4(
                    input           clk,
                    input           reset,
                    input           t_valid, 
                    input [31:0]    fft_val, // According to the CORDIC module in lec 10 code 
    
                    output logic [31:0] fund_val,
                    output logic [15:0] fund_index, // FFT_size is 2048
                    output logic [31:0] second_val,
                    output logic [15:0] second_index,
                    output logic [31:0] third_val,
                    output logic [15:0] third_index,
                    output logic [31:0] fourth_val,
                    output logic [15:0] fourth_index,
                    output logic        done,
                    
                    // Test vals
                    output logic [23:0] fft_mem_test,
                    output logic [5:0]  harmonic_counter_test,
                    output logic        find_harmonics_test
    );
    
    parameter FFT_SIZE = 'd1024;
    parameter ROI = 'd5; // HOW MANY VALUES FROM THE PEAK DO YOU WANT TO ZERO OUT?
    
    logic [31:0] fft_mem [2047:0];
    
    logic started;
    logic find_harmonics;

    
    logic [31:0] temp_val1;
    logic [31:0] fft_mem_val;
    logic [15:0] temp_index1;
    
    logic [15:0] counter;
    logic [5:0]  harmonic_counter;
    logic [6:0]  roi_counter;
    logic [15:0] current_roi_index;
    
    integer i;
    
    assign harmonic_counter_test = harmonic_counter;
    assign fft_mem_test = fft_mem[counter];    
    assign find_harmonics_test = find_harmonics;
    
    always_ff @(posedge clk) begin
        if (reset || (t_valid && !started)) begin // RESET
            counter <= 1;
            fund_index <= 0;
            fund_val <= 0;
            second_val <= 0;
            second_index <= 0;
            third_val <= 0;
            third_index <= 0;
            fourth_val <= 0;
            fourth_index <= 0;
            temp_val1 <= 0;
            temp_index1 <= 0;
            harmonic_counter <= 0;
            done <= 0;
            roi_counter <= 0;
            started <= reset? 0 : 1;
            find_harmonics <= 0;
        end else if ((t_valid) && (started == 1)) begin // FILL MEMORY BANK WITH INCOMING VALUES
            counter <= counter + 1;
            fft_mem[counter] <= fft_val;
        end else if (!t_valid && (started == 1)) begin // ONCE MEMORY BANK IF FILLED, START FINDING PEAKS
            counter <= 0; // Only start looking in C3 - C4
            harmonic_counter <= 0;
            find_harmonics <= 1;
            started <= 0;
            temp_val1 <= 0;
            temp_index1 <= 0;
            roi_counter <= 0;
        end else if ((find_harmonics) && (counter < FFT_SIZE) && (harmonic_counter < 4)) begin
            counter <= counter + 1;
            fft_mem_val <= fft_mem[counter];
            if ((fft_mem_val > temp_val1) && (fft_mem_val > 'h700)) begin // ONLY ADD IF ABOVE SOME  ARBITRARY THRESHOLD VALUE
                temp_val1 <= fft_mem_val; 
                temp_index1 <= counter;
              case(harmonic_counter)
                0       :       begin
                                   fund_val <= fft_mem_val;
                                   fund_index <= counter;
                                end  
                1       :       begin
                                    second_val <= fft_mem_val;
                                    second_index <= counter;
                                end
                2       :       begin
                                    third_val <= fft_mem_val;
                                    third_index <= counter;
                                end
                3       :       begin
                                    fourth_val <= fft_mem_val;
                                    fourth_index <= counter;
                                end
              endcase
            end
        end else if ((find_harmonics) && (counter >= FFT_SIZE) && (harmonic_counter < 4) && (roi_counter <= (ROI<<1))) begin // THIS STEP ZEROS THINGS OUT
            roi_counter <= roi_counter + 1;
            current_roi_index <= temp_index1 - ROI + roi_counter;
            fft_mem_val <= fft_mem[current_roi_index];
            fft_mem_val <= 0;
        end else if ((find_harmonics) && (counter >= FFT_SIZE) && (harmonic_counter < 4) && (roi_counter > (ROI<<1))) begin
            roi_counter <= 0;
            counter <= 2;
            harmonic_counter <= harmonic_counter + 1;
            temp_val1 <= 0;
            temp_index1 <= 0;
        end else if ((find_harmonics) && (harmonic_counter >= 4)) begin
            done <= 1;
            find_harmonics <= 0;
        end
    end
endmodule
