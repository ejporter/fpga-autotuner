module hannFSM (
    input logic clk_100mhz,
    input logic sample_trigger,
    input logic [11:0] adc_data,
    input logic rst,
    input logic fft_ready,
    
    output logic  fft_last,
    output logic [9:0] fft_data_counter,
    output logic [15:0] fft_data,
    output logic fft_valid,
    output logic [2:0] state
    
);

    logic [11:0] hann1_addr; // addresses for the BRAMs for each over the switching hann windows
    logic [11:0] hann2_addr;
    logic [11:0] hann1_din; // data input to each
    logic [11:0] hann2_din;
    logic hann2_write; // write enable to each
    logic hann1_write;
    logic hann1_full; // when the hann windows are full and ready to be multiplied and output
    logic hann2_full;
    logic [11:0] hann1_read; // data currently read, offset 2 cycles from addr
    logic [11:0] hann2_read;
    logic [9:0] current_fft_counter; // just to offset the fft_counter window
    
    logic [15:0] scaled_data; // scaled appropriately for input to the FFT
    logic data_ready;
    logic [11:0] hann1_coeff; // coeff for the current hann step (times 2^12)
    logic [11:0] hann2_coeff;
    logic [23:0] multiplied_data; //  holds data after multiplied
    
    // ROMS that hold each of the hann coefficients
    // Memory Type: Single Port ROM
    // Port A Width: 12
    // Port A Depth: 2048
    // Enable Port Type: Always Enabled
    // Load init file: hann_coeffs.coe
    // all other settings default
    hann_coeffs hann1_rom (
              .clka(clk_100mhz),
              .addra(hann1_addr),
                .douta(hann1_coeff));
                
    hann_coeffs hann2_rom (
              .clka(clk_100mhz),
              .addra(hann2_addr),
                .douta(hann2_coeff));            
    // How many to hold in each window before outputting
    parameter FRAMESIZE = 2048;
    
    assign hann1_full = (hann1_addr == FRAMESIZE); // goes high when we're ready to dump the data
    assign hann2_full = (hann2_addr == FRAMESIZE);
    
    
    //states
    parameter INIT = 3'b000;
    parameter LOADING = 3'b001;
    parameter READ1 = 3'b010;
    parameter READ2 = 3'b011;
    parameter DELAY1 = 3'b100; // delay states for reading from the BRAM
    parameter DELAY2 = 3'b101;
    
    //requires a four cycle delay to properly calculate
    logic [1:0] delay_count;
    
    
    
    
    
//    BRAMs for storing each of the two windows
//    IP config:
//    Block Memory Generator (8.4)
//    Native, Single Port RAM, No ECC, Single Bit Error Innjection, Byte Size 9, Everything unchecked
//    Port A: Write width 12, Write Depth 2048, write first, ENA pin, only primitives output register checked.
//    Port B: Same
    hann_bram hann1 (.addra(hann1_addr), .clka(clk_100mhz), .dina(hann1_din),
                    .douta(hann1_read), .ena(1'b1), .wea(hann1_write));
                    
    hann_bram hann2 (.addra(hann2_addr), .clka(clk_100mhz), .dina(hann2_din),
                    .douta(hann2_read), .ena(1'b1), .wea(hann2_write));

    // uncomment for debugging
//    ila_0 myila (.clk(clk_100mhz), .probe0(multiplied_data), .probe1(hann2_read), .probe2(scaled_data), .probe3(hann2_coeff), .probe4(state));
    
    always_ff @(posedge clk_100mhz)begin
        if (rst) state <= INIT; // setting up initial conditions
        else begin

        case (state) 
            INIT: begin
                hann1_addr <= FRAMESIZE/2; // reset everything to initial conditions, offset hann1
                hann2_addr <= 0;
                fft_data_counter <= 0;
                current_fft_counter <= 0;
                fft_last <= 0;
                fft_valid <= 0;
                
                state <= LOADING;
            
            end
        
            LOADING: begin // loadin data into both roms
                fft_last <= 0;
                fft_valid <= 0;
                fft_data_counter <= 0;
                fft_data <= 0;
                if (sample_trigger) begin // when we get an input signal
                    hann1_addr <= hann1_addr + 12'b1;
                    hann1_write <= 1;
                    hann1_din <= adc_data;
                                      

                    hann2_addr <= hann2_addr + 12'b1;
                    hann2_write <= 1;
                    hann2_din <= adc_data;
                    
                    
                
                
                end else begin
                    hann2_write <= 0; // dont write when we dont have a signal
                    hann1_write <= 0;
                
                end
                
                if (hann1_full) begin // if theyre full, prep it and send to next stage
                    hann1_write <= 0;
                    hann1_addr <= 1;
                    delay_count <= 0;
                    state <= DELAY1;
                end if (hann2_full) begin
                    hann2_write <= 0;
                    hann2_addr <= 1;
                    delay_count <= 0;
                    state <= DELAY2;
                end
                
            end
            
            DELAY1 : begin  // started calculating necessary quantities, but offset by 4
                hann1_addr <= hann1_addr + 1;  
                hann1_write <= 1'b0;               
                multiplied_data <=  hann1_coeff*hann1_read;
                scaled_data <= multiplied_data[23:8];                
                if (delay_count == 2'b11) begin
                    state <= READ1; 
                    delay_count <= 2'b0;
                end
                
                delay_count <= delay_count + 1; // we have to wait 4 cycles before outputing to allow the pipeline to catch up
            end
            DELAY2 : begin
                hann2_addr <= hann2_addr + 1;  
                hann2_write <= 1'b0;               
                multiplied_data <=  hann2_coeff*hann2_read;
                scaled_data <= multiplied_data >>8;                
                if (delay_count == 2'b11) begin
                    state <= READ2; 
                    delay_count <= 2'b0;
                end
                
                delay_count <= delay_count + 1;
             end
            
            
            
            READ1: begin // continue push the data through the cycles but actually begin outputting
                hann1_write <= 1'b0;               
                hann1_addr <= hann1_addr + 12'b1;
                multiplied_data <=  hann1_coeff*hann1_read;
                scaled_data <= multiplied_data >>8;
                if (fft_ready) begin           
                    fft_data_counter <= fft_data_counter + 10'b1;         
                    fft_data <= {~scaled_data[15], scaled_data[14:0]};
                    fft_valid <= 1'b1;
                    if (hann1_addr == (FRAMESIZE+4)) begin // extra 4 to account for the offset cycles
                        state <= LOADING;
                        data_ready <= 1'b0;
                        hann1_addr <= 12'b0;
                        fft_last <= 1'b1;                   
                    end
                end else fft_valid <=1'b0;
                
            
            end
            
            READ2: begin
                hann2_write <= 1'b0;               
                hann2_addr <= hann2_addr + 12'b1;
                multiplied_data <=  hann2_coeff*hann2_read;
                scaled_data <= multiplied_data >>8;
                
                
                if ( fft_ready) begin 
                    current_fft_counter <= current_fft_counter + 10'b1;          
                    fft_data_counter <= current_fft_counter;         
                    fft_data <= {~scaled_data[15], scaled_data[14:0]};
                    fft_valid <= 1'b1;
                    if (hann2_addr == (FRAMESIZE+4)) begin
                        state <= LOADING;
                        data_ready <= 1'b0;
                        hann2_addr <= 0;
                        fft_last <= 1;                   
                    end
                end
                else fft_valid <=1'b0;
                
             
            
            end
            default: state <= INIT;
        endcase
                
        end
      end  
      

        
   
endmodule
//HannFSM

