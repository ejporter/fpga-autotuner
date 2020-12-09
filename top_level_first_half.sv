//2020, jodalyst.
//meant for Fall 2020 6.111
//Based in part off of Labs 03 and 05A from that term
//Discussed in Fall 2020  Lecture 10: https://6111.io/F20/lectures/lecture10 

module top_level(   input clk_100mhz,
                    input [15:0] sw,
                    input btnc, btnu, btnd, btnr, btnl,
                    input vauxp3,
                    input vauxn3,
                    input vn_in,
                    input vp_in,
                    output logic[3:0] vga_r,
                    output logic[3:0] vga_b,
                    output logic[3:0] vga_g,
                    output logic vga_hs,
                    output logic vga_vs,
                    output logic [15:0] led,
                    output logic aud_pwm,
                    output logic aud_sd
    );  

    parameter SAMPLE_COUNT = 2082;//gets approximately (will generate audio at approx 48 kHz sample rate.

 
    logic [11:0] adc_data;
    logic sample_trigger;
    logic adc_ready;            
    logic [15:0] fft_data;
    logic       fft_ready;
    logic       fft_valid;
    logic       fft_last;
    logic [9:0] fft_data_counter;
    
    logic fft_out_ready;
    logic fft_out_valid;
    logic fft_out_last;
    logic [31:0] fft_out_data;
    
    logic sqsum_valid;
    logic sqsum_last;
    logic sqsum_ready;
    logic [31:0] sqsum_data;
    
    logic [23:0] sqrt_data;
    logic sqrt_valid;
    logic sqrt_last;
    
    logic pixel_clk;
   
    vga_clk myvga (.clk_in1(clk_100mhz), .clk_out1(pixel_clk));
    
   
    assign led = sw; //just to look pretty 
  
    logic oversample_trigger;
    logic [11:0] oversampled_data;
    logic [2:0] state;
    
    hannFSM hann (.clk_100mhz(clk_100mhz), .sample_trigger(oversample_trigger), .adc_data(oversampled_data),
                    .fft_last(fft_last), .fft_valid(fft_valid), .state(state),
                    .fft_data_counter(fft_data_counter), .fft_data(fft_data), .fft_ready(fft_ready));
                    
    oversampler  OS (.clk_100mhz(clk_100mhz), .rst(btnc), .data_in(adc_data), .sample_trigger(oversample_trigger), .data_out(oversampled_data));
       
    xadc_wiz_0 my_adc ( .dclk_in(clk_100mhz), .daddr_in(8'h13), //read from 0x13 for a
                        .vauxn3(vauxn3),.vauxp3(vauxp3),
                        .vp_in(1),.vn_in(1),
                        .di_in(16'b0),
                        .do_out(adc_data),.drdy_out(adc_ready),
                        .den_in(1), .dwe_in(0));
 
 

    //FFT module:
    //CONFIGURATION:
    //1 channel
    //transform length: 2048
    //target clock frequency: 100 MHz
    //target Data throughput: 50 Msps
    //Auto-select architecture
    //IMPLEMENTATION:
    //Fixed Point, Scaled, Truncation
    //Natural ordering!!
    //Input Data Width, Phase Factor Width: Both 16 bits
    //Result uses 12 DSP48 Slices and 6 Block RAMs (under Impl Details)
    xfft_0 my_fft (.aclk(clk_100mhz), .s_axis_data_tdata(fft_data), 
                    .s_axis_data_tvalid(fft_valid),
                    .s_axis_data_tlast(fft_last), .s_axis_data_tready(fft_ready),
                    .s_axis_config_tdata(0), 
                     .s_axis_config_tvalid(0),
                     .s_axis_config_tready(),
                    .m_axis_data_tdata(fft_out_data), .m_axis_data_tvalid(fft_out_valid),
                    .m_axis_data_tlast(fft_out_last), .m_axis_data_tready(fft_out_ready));
    
    //for debugging commented out, make this whatever size,detail you want:
    
    //custom module (was written with a Vivado AXI-Streaming Wizard so format looks inhuman
    //this is because it was a template I customized.
    square_and_sum_v1_0 mysq(.s00_axis_aclk(clk_100mhz), .s00_axis_aresetn(1'b1),
                            .s00_axis_tready(fft_out_ready),
                            .s00_axis_tdata(fft_out_data),.s00_axis_tlast(fft_out_last),
                            .s00_axis_tvalid(fft_out_valid),.m00_axis_aclk(clk_100mhz),
                            .m00_axis_aresetn(1'b1),. m00_axis_tvalid(sqsum_valid),
                            .m00_axis_tdata(sqsum_data),.m00_axis_tlast(sqsum_last),
                            .m00_axis_tready(sqsum_ready));
    
  

    //AXI4-STREAMING Square Root Calculator:
    //CONFIGUATION OPTIONS:
    // Functional Selection: Square Root
    //Architec Config: Parallel (can't change anyways)
    //Pipelining: Max
    //Data Format: UnsignedInteger
    //Phase Format: Radians, the way God intended.
    //Input Width: 32
    //Output Width: 17
    //Round Mode: Truncate
    //0 on the others, and no scale compensation
    //AXI4 STREAM OPTIONS:
    //Has TLAST!!! need to propagate that
    //Don't need a TUSER
    //Flow Control: Blocking
    //optimize Goal: Performance
    //leave other things unchecked.
    cordic_0 mysqrt (.aclk(clk_100mhz), .s_axis_cartesian_tdata(sqsum_data),
                     .s_axis_cartesian_tvalid(sqsum_valid), .s_axis_cartesian_tlast(sqsum_last),
                     .s_axis_cartesian_tready(sqsum_ready),.m_axis_dout_tdata(sqrt_data),
                     .m_axis_dout_tvalid(sqrt_valid), .m_axis_dout_tlast(sqrt_last));
    
    logic [10:0] addr_count;
    logic [10:0] draw_addr;
    logic [15:0] spec_bram_addr; // keep track of location in the spec bram
    logic [15:0] spec_draw_addr; // keep track of where on the screen you are drawing spec
    logic [31:0] amp_out;
    logic [11:0] spec_pixels;   // output of spec bram
    logic [10:0] hcount;
    logic [9:0] vcount;
    logic       vsync;
    logic       hsync;
    logic       blanking;
    logic [11:0] rgb;
    
    // UPDATE TO ALSO PUT DATA IN SPEC BRAM
    logic [1:0] spec_bram_count;
    logic spec_bram_flag;

    always_ff @(posedge clk_100mhz)begin
        if (sqrt_valid)begin
            if (sqrt_last)begin
                addr_count <= 'd2047; //allign
                spec_bram_addr <= spec_bram_addr + 1;         // allign spec
                spec_bram_count <= 0;                         // reset count
            end else if (spec_bram_count == 2'b11) begin      // write every 4th value to bram (scale 2048 down ro 256)
                    addr_count <= addr_count + 1'b1;          // always update live mags
                    spec_bram_addr <= spec_bram_addr + 1'b1;  // increase spec bram address
                    spec_bram_count <= 0;                     // count back to 0
                    spec_bram_flag <= 1;                      // turn write enable to spec bram on
                end else begin
                    addr_count <= addr_count + 1'b1;          // always update live mags
                    spec_bram_count <= spec_bram_count + 1'b1;// increase count
                    spec_bram_flag <= 0;                      // turn write enable to spec bram off
                end  
        end
    end 
         
    //Two Port BRAM: The FFT pipeline files values inot this and the VGA side of things
    //reads the values out as needed!  Separate clocks on both sides so we don't need to
    //worry about clock domain crossing!! (at least not directly)
    //BRAM Generator (v. 8.4)
    //BASIC:
    //Interface Type: Native
    //Memory Type: True Dual Port RAM (leave common clock unticked...since using100 and 65 MHz)
    //leave ECC as is
    //leave Write enable as is (unchecked Byte Write Enabe)
    //Algorithm Options: Minimum Area (not too important anyways)
    //PORT A OPTIONS:
    //Write Width: 32
    //Read Width: 32
    //Write Depth: 2048
    //Read Depth: 2048
    //Operating Mode; Write First (not too important here)
    //Enable Port Type: Use ENA Pin
    //Keep Primitives Output Register checked
    //leave other stuff unchecked
    //PORT B OPTIONS:
    //Should mimic Port A (and should auto-inheret most anyways)
    //leave other tabs as is. the summary tab should report one 36K BRAM being used
    value_bram mvb (.addra(addr_count+3), .clka(clk_100mhz), .dina({8'b0,sqrt_data}),
                    .douta(), .ena(1'b1), .wea(sqrt_valid),.dinb(0),
                    .addrb(draw_addr), .clkb(pixel_clk), .doutb(amp_out),
                    .web(1'b0), .enb(1'b1));     

    //Two Port BRAM: The FFT pipeline files values inot this and the VGA side of things
    //reads the values out as needed!  Separate clocks on both sides so we don't need to
    //worry about clock domain crossing!! (at least not directly)
    //BRAM Generator (v. 8.4)
    //BASIC:
    //Interface Type: Native
    //Memory Type: True Dual Port RAM (leave common clock unticked...since using100 and 65 MHz)
    //leave ECC as is
    //leave Write enable as is (unchecked Byte Write Enabe)
    //Algorithm Options: Minimum Area (not too important anyways)
    //PORT A OPTIONS:
    //Write Width: 12 (save memory by only using the 12 bits that are going to be RGB
    //Read Width: 12
    //Write Depth: 65536    (256 x 256 spectrogram)
    //Read Depth: 65536
        // ^^^ Only real changes from Joe's setup
    
    //Operating Mode; Write First (not too important here)
    //Enable Port Type: Use ENA Pin
    //Keep Primitives Output Register checked
    //leave other stuff unchecked
    //PORT B OPTIONS:
    //Should mimic Port A (and should auto-inheret most anyways)
    //leave other tabs as is. the summary tab should report 22 36K BRAM being used  
    // saved using 36 extra 36k BRAMs by only storing 12 bits
    spec_values spec_bram (.addra(spec_bram_addr), .clka(clk_100mhz), .dina(sqrt_data[11:0]),
                    .douta(), .ena(1'b1), .wea(spec_bram_flag),.dinb(0),
                    .addrb(spec_draw_addr), .clkb(pixel_clk), .doutb(spec_pixels),
                    .web(1'b0), .enb(1'b1));

    // THIS IS WHERE THE SYNTHESIS PORTION STARTS

    logic [31:0]    fft_val;

    // Intermediate values
    logic [31:0] fund_val;
    logic [15:0] fund_index; // FFT_size is 2048
    logic [31:0] second_val;
    logic [15:0] second_index;
    logic [31:0] third_val;
    logic [15:0] third_index;
    logic [31:0] fourth_val;
    logic [15:0] fourth_index;
    logic        done;
    logic [23:0]    fcw1;
    logic [23:0]    fcw2;
    logic [23:0]    fcw3;
    logic [23:0]    fcw4;
    
    // Output sine wave
    logic [11:0]    sin_out1;
    logic [11:0]    sin_out2;
    logic [11:0]    sin_out3;
    logic [11:0]    sin_out4;
    logic [11:0]    true_sin_out;
    
    assign true_sin_out = (sin_out1 >> 1) + (sin_out2 >> 1) + (sin_out3 >> 2) + (sin_out4 >> 2); 

    // lab5a vals
    logic [15:0] sample_counter;
    logic [11:0] sample_gen_data;
    logic [7:0] vol_out;
    logic pwm_val; //pwm signal (HI/LO)
    logic sample_trigger2;
    logic [1:0] scale_choice;
    
    assign scale_choice = sw[8:7];


    assign aud_sd = 1;
    assign sample_trigger2 = (sample_counter == SAMPLE_COUNT);

    always_ff @(posedge clk_100mhz)begin
        if (sample_counter == SAMPLE_COUNT)begin
            sample_counter <= 16'b0;
        end else begin
            sample_counter <= sample_counter + 16'b1;
        end
        if (sample_trigger2) begin
            sample_gen_data <= {~true_sin_out[11],true_sin_out[10:4]}; // data is already in offset binary
            //https://en.wikipedia.org/wiki/Offset_binary
        end
    end

    // EVERYTHING UNTIL THIS POINT WAS IN LAB5A

    ///////////////
    /// TEST VALS
    ///////////////
    logic [5:0]  test_harmonic_counter;
    logic [31:0] test_fft_mem;
    logic        find_harmoincs_test;

    ///////////////
    // PEAK FINDER
    ///////////////
    peak_finder_v4 #(.FFT_SIZE('d1024), .ROI('d3)) v3_test (.clk(clk_100mhz), .reset(btnd), .t_valid(sqsum_valid), .fft_val(sqsum_data[31:0]),
                            .fund_val(fund_val), .fund_index(fund_index),
                            .second_val(second_val), .second_index(second_index),
                            .third_val(third_val), .third_index(third_index),
                            .fourth_val(fourth_val), .fourth_index(fourth_index),
                            .done(done),
                            
                            // Test vals
                            .harmonic_counter_test(test_harmonic_counter),
                            .fft_mem_test(test_fft_mem),
                            .find_harmonics_test(find_harmonics_test)
                        );
                        
    ///////////////
    /// ILA
    ///////////////
    //ila_0 myila (.clk(clk_100mhz), .probe0(sqrt_data), .probe1(fund_val), .probe2(second_val), .probe3(fund_index), .probe4(second_index), .probe5(third_index), .probe6(sqrt_valid), .probe7(done), .probe8(find_harmonics_test), .probe9(test_harmonic_counter), .probe10(test_fft_mem));
    ila_0 myila (.clk(clk_100mhz), .probe0(sqsum_valid), .probe1(sqsum_data));

    ///////////////
    /// TUNING
    ///////////////
    tuning tune_test1 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(fund_index),
                      .scale_choice(scale_choice), .fcw(fcw1));
    tuning tune_test2 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(second_index),
                      .scale_choice(scale_choice), .fcw(fcw2));
    tuning tune_test3 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(third_index),
                      .scale_choice(scale_choice), .fcw(fcw3));
    tuning tune_test4 (.clk(clk_100mhz), .rst(btnd), .fundamental_index(fourth_index),
                      .scale_choice(scale_choice), .fcw(fcw4));
    
    ///////////////
    /// SINE GENERATION
    ///////////////
    sine_resyn resyn_test (.clk(clk_100mhz), .reset(btnd), .fcw(fcw1),
                      .sin_out(sin_out1));
    sine_resyn resyn_test1 (.clk(clk_100mhz), .reset(btnd), .fcw(fcw2),
                      .sin_out(sin_out2));
    sine_resyn resyn_test2 (.clk(clk_100mhz), .reset(btnd), .fcw(fcw3),
                      .sin_out(sin_out3));
    sine_resyn resyn_test3 (.clk(clk_100mhz), .reset(btnd), .fcw(fcw4),
                      .sin_out(sin_out4));


    ///////////////
    /// VOLUME
    ///////////////
    volume_control vc (.vol_in(sw[15:13]),
                       .signal_in(sample_gen_data), .signal_out(vol_out));

    ///////////////
    /// AUDIO OUTPUT
    ///////////////
    pwm (.clk_in(clk_100mhz), .rst_in(btnd), .level_in({~vol_out[7],vol_out[6:0]}), .pwm_out(pwm_val));
    assign aud_pwm = pwm_val?1'bZ:1'b0; 


//////////////////////////////////////
//      
//          Visualizations 
//
//////////////////////////////////////

    // parameterizations (graph sizes, locations, colors, etc)
    
    // SPECTROGRAM
    parameter [11:0] SPEC_LOC_X = 700;      // actual graph at ()
    parameter [10:0] SPEC_LOC_Y = 75;
    parameter [9:0] SPEC_SIZE = 256;       // graph is 256 x 256 
    
    // REAL TIME MAGS
    parameter [11:0] MAGS_LOC_X = 700;      // actual graph at ()
    parameter [10:0] MAGS_LOC_Y = 400;
    parameter [9:0] MAGS_SIZE = 256;       // graph is 256 x 256 
    
    // AUDIO SLIDERS
    parameter [11:0] SLIDER_LOC_X = 15;   // first slider at (100, 200)
    parameter [10:0] SLIDER_LOC_Y = 200;   // other sliders placed relative to this
    
    
    
    // DESIGN FOR SPEC
    logic [11:0] x_axis_spec, y_axis_spec, x_label_spec, y_label_spec, graph_color_spec, graph_title_spec;
    
    // use blob to make x_axis
    blob #(.WIDTH(SPEC_SIZE + 5), .HEIGHT(5))
    x_axis_blob (.x_in(SPEC_LOC_X - 5), .hcount_in(hcount), .y_in(SPEC_LOC_Y + SPEC_SIZE), .vcount_in(vcount),
                .pixel_out(x_axis_spec));

    // use blob to make y_axis
    blob #(.WIDTH(5), .HEIGHT(SPEC_SIZE))
    y_axis_blob (.x_in(SPEC_LOC_X - 5), .hcount_in(hcount), .y_in(SPEC_LOC_Y), .vcount_in(vcount),
                .pixel_out(y_axis_spec));
                
    // make labels
    letters_time time_text(.x_in(SPEC_LOC_X - 5 + (SPEC_SIZE>>1)), .hcount_in(hcount), .y_in(SPEC_LOC_Y + SPEC_SIZE + 20), .vcount_in(vcount),
                .pixel_out(x_label_spec));

    letters_freq1 freq_text1(.x_in(SPEC_LOC_X - 25), .hcount_in(hcount), .y_in(SPEC_LOC_Y + (SPEC_SIZE>>1)), .vcount_in(vcount),
                .pixel_out(y_label_spec));
    
    letters_spectrogram spec_text(.x_in(SPEC_LOC_X - 5 + (SPEC_SIZE>>1)), .hcount_in(hcount), .y_in(SPEC_LOC_Y - 20), .vcount_in(vcount),
                .pixel_out(graph_title_spec));

    // DESIGN FOR MAGS
    logic [11:0] x_axis_mag, y_axis_mag, x_label_mag, y_label_mag, graph_title_mag;
    
    letters_freq2 freq_text2(.x_in(MAGS_LOC_X - 5 + (MAGS_SIZE>>1)), .hcount_in(hcount), .y_in(MAGS_LOC_Y + MAGS_SIZE + 20), .vcount_in(vcount),
                .pixel_out(x_label_mag));
    
    letters_mag mag_text(.x_in(MAGS_LOC_X - 25), .hcount_in(hcount), .y_in(MAGS_LOC_Y + (MAGS_SIZE>>1)), .vcount_in(vcount),
                .pixel_out(y_label_mag));
                
    // use blob to make x_axis
    blob #(.WIDTH(MAGS_SIZE + 5), .HEIGHT(5))
    x_axis_blob2 (.x_in(MAGS_LOC_X - 5), .hcount_in(hcount), .y_in(MAGS_LOC_Y + MAGS_SIZE), .vcount_in(vcount),
                .pixel_out(x_axis_mag));

    // use blob to make y_axis
    blob #(.WIDTH(5), .HEIGHT(MAGS_SIZE))
    y_axis_blob2 (.x_in(MAGS_LOC_X - 5), .hcount_in(hcount), .y_in(MAGS_LOC_Y), .vcount_in(vcount),
                .pixel_out(y_axis_mag));
                
                
//    // DESIGN FOR SLIDERS (you can ignore for now, they're just pictures)
//    logic [11:0] slider1, slider2, slider3, slider4, test_blob;
    
//    picture_blob #(.WIDTH(200), .HEIGHT(34))
//            audio_blob1 (.pixel_clk_in(pixel_clk), .x_in(SLIDER_LOC_X),.y_in(SLIDER_LOC_Y),.hcount_in(hcount),.vcount_in(vcount),
//                 .pixel_out(slider1));
    
//    picture_blob #(.WIDTH(200), .HEIGHT(34))
//            audio_blob2 (.pixel_clk_in(pixel_clk), .x_in(SLIDER_LOC_X),.y_in(SLIDER_LOC_Y + 200),.hcount_in(hcount),.vcount_in(vcount),
//                  .pixel_out(slider2));
    
//    picture_blob #(.WIDTH(200), .HEIGHT(34))
//            audio_blob3 (.pixel_clk_in(pixel_clk), .x_in(SLIDER_LOC_X + 250),.y_in(SLIDER_LOC_Y),.hcount_in(hcount),.vcount_in(vcount),
//                  .pixel_out(slider3));
                     
//    picture_blob #(.WIDTH(200), .HEIGHT(34))
//            audio_blob4 (.pixel_clk_in(pixel_clk), .x_in(SLIDER_LOC_X + 250),.y_in(SLIDER_LOC_Y + 200),.hcount_in(hcount),.vcount_in(vcount),
//                  .pixel_out(slider4));
    
//    picture_blob #(.WIDTH(10), .HEIGHT(10))
//            test_blob1 (.pixel_clk_in(pixel_clk), .x_in(550),.y_in(555),.hcount_in(hcount),.vcount_in(vcount),
//                 .picture_in(1'b1), .pixel_out(test_blob));
//    //draw bargraphs from amp_out extracted (scale with switches)                

    // adjust to 256x256 in bottom right of screen
    always_ff @(posedge pixel_clk)begin
        if (!blanking)begin //time to draw!
            rgb <= 12'b1000_1000_1000;
        end

        if (((hcount >= MAGS_LOC_X) && (hcount < MAGS_LOC_X + MAGS_SIZE)) && 
            ((vcount >= MAGS_LOC_Y)&& (vcount < MAGS_LOC_Y + MAGS_SIZE))) begin
            draw_addr <= (hcount - MAGS_LOC_X)*4; // taking every 4 values
            if ((amp_out>>sw[3:0])>=(MAGS_LOC_Y + MAGS_SIZE)-vcount)begin
//                rgb <= sw[15:4];
                  rgb <= amp_out[11:0]; // only take 12 bits from sqrt data
              end else rgb <= 12'b1000_1000_1000;   // background of real time (gray)
        end else if (((hcount >= SPEC_LOC_X) && (hcount < SPEC_LOC_X + SPEC_SIZE )) && 
            ((vcount >= SPEC_LOC_Y)&& (vcount < SPEC_LOC_Y + SPEC_SIZE ))) begin
            
                // gets the spec bram address
                spec_draw_addr <= ((hcount - SPEC_LOC_X)*SPEC_SIZE - (vcount - SPEC_LOC_Y));  
                                   
                // read the spec values
                rgb <= spec_pixels;
            
        // sets pixel as all other possible things on the screen
        end else begin
             rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                        x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag ;
//                        slider1 | slider2 | slider3 | slider4 | test_blob; 
            end     
       
    end

                    
    xvga myyvga (.vclock_in(pixel_clk),.hcount_out(hcount),  
                .vcount_out(vcount),.vsync_out(vsync), .hsync_out(hsync),
                 .blank_out(blanking));               
                        
    assign vga_r = ~blanking ? rgb[11:8]: 0;
    assign vga_g = ~blanking ? rgb[7:4] : 0;
    assign vga_b = ~blanking ? rgb[3:0] : 0;
    
    assign vga_hs = ~hsync;
    assign vga_vs = ~vsync;

    

endmodule

// this is the module from Joe

module square_and_sum_v1_0 #
    (
        // Users to add parameters here

        // User parameters ends
        // Do not modify the parameters beyond this line


        // Parameters of Axi Slave Bus Interface S00_AXIS
        parameter integer C_S00_AXIS_TDATA_WIDTH    = 32,

        // Parameters of Axi Master Bus Interface M00_AXIS
        parameter integer C_M00_AXIS_TDATA_WIDTH    = 32,
        parameter integer C_M00_AXIS_START_COUNT    = 32
    )
    (
        // Users to add ports here

        // User ports ends
        // Do not modify the ports beyond this line


        // Ports of Axi Slave Bus Interface S00_AXIS
        input wire  s00_axis_aclk,
        input wire  s00_axis_aresetn,
        output wire  s00_axis_tready,
        input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
        input wire  s00_axis_tlast,
        input wire  s00_axis_tvalid,

        // Ports of Axi Master Bus Interface M00_AXIS
        input wire  m00_axis_aclk,
        input wire  m00_axis_aresetn,
        output wire  m00_axis_tvalid,
        output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
        output wire  m00_axis_tlast,
        input wire  m00_axis_tready
    );
    
    reg m00_axis_tvalid_reg_pre;
    reg m00_axis_tlast_reg_pre;
    reg m00_axis_tvalid_reg;
    reg m00_axis_tlast_reg;
    reg [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata_reg;
    
    reg s00_axis_tready_reg;
    reg signed [31:0] real_square;
    reg signed [31:0] imag_square;
    
    wire signed [15:0] real_in;
    wire signed [15:0] imag_in;
    assign real_in = s00_axis_tdata[31:16];
    assign imag_in = s00_axis_tdata[15:0];
    
    assign m00_axis_tvalid = m00_axis_tvalid_reg;
    assign m00_axis_tlast = m00_axis_tlast_reg;
    assign m00_axis_tdata = m00_axis_tdata_reg;
    assign s00_axis_tready = s00_axis_tready_reg;
    
    always @(posedge s00_axis_aclk)begin
        if (s00_axis_aresetn==0)begin
            s00_axis_tready_reg <= 0;
        end else begin
            s00_axis_tready_reg <= m00_axis_tready; //if what you're feeding data to is ready, then you're ready.
        end
    end
    
    always @(posedge m00_axis_aclk)begin
        if (m00_axis_aresetn==0)begin
            m00_axis_tvalid_reg <= 0;
            m00_axis_tlast_reg <= 0;
            m00_axis_tdata_reg <= 0;
        end else begin
            m00_axis_tvalid_reg_pre <= s00_axis_tvalid; //when new data is coming, you've got new data to put out
            m00_axis_tlast_reg_pre <= s00_axis_tlast; //
            real_square <= real_in*real_in;
            imag_square <= imag_in*imag_in;
            
            m00_axis_tvalid_reg <= m00_axis_tvalid_reg_pre; //when new data is coming, you've got new data to put out
            m00_axis_tlast_reg <= m00_axis_tlast_reg_pre; //
            m00_axis_tdata_reg <= real_square + imag_square;
        end
    end
    
    
endmodule


//PWM generator for audio generation!
module pwm (input clk_in, input rst_in, input [7:0] level_in, output logic pwm_out);
    logic [7:0] count;
    assign pwm_out = count<level_in;
    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            count <= 8'b0;
        end else begin
            count <= count+8'b1;
        end
    end
endmodule

//Volume Control
module volume_control (input [2:0] vol_in, input signed [7:0] signal_in, output logic signed[7:0] signal_out);
    logic [2:0] shift;
    assign shift = 3'd7 - vol_in;
    assign signal_out = signal_in>>>shift;
endmodule