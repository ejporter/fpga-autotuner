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

//////////////////////////////////////
//      
//          Button / Switch Setup
//
//////////////////////////////////////
    
    logic clean_up, clean_down, clean_right, clean_left, rst;
    logic [15:0] clean_sw;
    
    debounce db1(.reset_in(rst),.clock_in(pixel_clk),.noisy_in(btnu),.clean_out(clean_up));
    debounce db2(.reset_in(rst),.clock_in(pixel_clk),.noisy_in(btnd),.clean_out(clean_down));
    debounce db3(.reset_in(rst),.clock_in(pixel_clk),.noisy_in(btnr),.clean_out(clean_right));
    debounce db4(.reset_in(rst),.clock_in(pixel_clk),.noisy_in(btnl),.clean_out(clean_left));
    debounce db5(.reset_in(rst),.clock_in(pixel_clk),.noisy_in(btnc),.clean_out(rst));
    debounce db6(.reset_in(rst),.clock_in(pixel_clk),.noisy_in(sw),.clean_out(clean_sw));
  
    logic oversample_trigger;
    logic [11:0] oversampled_data;
    logic [2:0] state;
    
    hannFSM_final hann (.clk_100mhz(clk_100mhz), .sample_trigger(oversample_trigger), .adc_data(oversampled_data),
                    .fft_last(fft_last), .fft_valid(fft_valid), .state(state),
                    .fft_data_counter(fft_data_counter), .fft_data(fft_data), .fft_ready(fft_ready));
                    
    oversampler  OS (.clk_100mhz(clk_100mhz), .rst(rst), .data_in(adc_data), .sample_trigger(oversample_trigger), .data_out(oversampled_data));
   
    ila_0 myila (.clk(clk_100mhz), .probe0(oversample_trigger), .probe1(oversampled_data), .probe2(adc_data), .probe3(fft_data), .probe4(state));
    
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

//////////////////////////////////////
//      
//      FFT outputs -> BRAMs
//
//////////////////////////////////////
    
    logic [1:0] spec_bram_count;
    logic spec_bram_flag;
    
    always_ff @(posedge clk_100mhz)begin
        if (sqrt_valid)begin
            if (sqrt_last)begin
                addr_count <= 'd2047; //allign
                spec_bram_addr <= spec_bram_addr + 1;         // allign spec
                spec_bram_count <= 0;                         // reset count
            end else if (spec_bram_count == 2'b11) begin      // write every 4th value to bram (scale 2048 down to 256)
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
    //Write Depth: 1024
    //Read Depth: 1024
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
    logic [2:0] scale_color;

    spec_values spec_bram (.addra(spec_bram_addr), .clka(clk_100mhz), .dina((sqrt_data[11:0] << scale_color)),
                    .douta(), .ena(1'b1), .wea(spec_bram_flag),.dinb(0),
                    .addrb(spec_draw_addr), .clkb(pixel_clk), .doutb(spec_pixels),
                    .web(1'b0), .enb(1'b1));
                


//////////////////////////////////////
//      
//          Visualizations (UI Setup)
//
//////////////////////////////////////
                    
    logic [1:0] musical_scale;
    logic [1:0] mag_scale;
    logic [11:0] color;
    logic live;
    logic [2:0] param;
    logic [3:0] button_state;
    // instantiate module for selecting parameters for display
    param_selector(.clk_65mhz(pixel_clk),.rst(rst),.up(clean_up),.down(clean_down),.next(clean_right),.set(clean_left),.sw(clean_sw),
                    .scale_choice(musical_scale),.scale_color(scale_color),.mag_scale(mag_scale),.color(color),
                    .live(live),.button_state(button_state), .selector_val(param));
           
    // param visuals
    logic [11:0] selector_line, selected_line, live_on_switch, live_off_switch, color_on_switch, color_off_switch,
                 scale_line, scale_button, color_scale_line, color_scale_button, pixels_0, pixels_3, color_pixels_0, color_pixels_4, color_label,
                 display_label, mag_scale_label, color_scale_label, musical_scale_label, scales_image, musical_scale_sel;
    logic [11:0] selector_line_x, scale_x, color_scale_x, musical_scale_sel_x;
    logic [10:0] selector_line_y;
    
    // default locations for all parameter visuals
    parameter SELECTOR_LOC_X = 110;
    parameter SELECTOR_LOC_Y = 200;
    
    parameter ON_LOC_X = 75;
    parameter ON_LOC_Y = 600;
    
    parameter OFF_LOC_X = 75;
    parameter OFF_LOC_Y = 600;
    
    parameter SCALE_LOC_X = 200;
    parameter SCALE_LOC_Y = 450;
    
    parameter COLOR_SCALE_LOC_X = 200;
    parameter COLOR_SCALE_LOC_Y = 300;
    
    parameter MUSICAL_SCALE_LOC_X = 150;
    parameter MUSICAL_SCALE_LOC_Y = 125;
    
    // selector line (selecting)
    blob #(.WIDTH(100), .HEIGHT(10), .COLOR(12'hF00))
    sel_line1 (.x_in(selector_line_x), .hcount_in(hcount), .y_in(selector_line_y), .vcount_in(vcount),
                .pixel_out(selector_line));   
                
    // selector line (selected)
    blob #(.WIDTH(100), .HEIGHT(10), .COLOR(12'h0F0))
    sel_line2 (.x_in(selector_line_x), .hcount_in(hcount), .y_in(selector_line_y), .vcount_in(vcount),
                .pixel_out(selected_line));
                
    // DISPLAY ON switch
    picture_ON 
        live_on_sw (.pixel_clk_in(pixel_clk), .x_in(ON_LOC_X), .hcount_in(hcount), .y_in(ON_LOC_Y), .vcount_in(vcount),
                .pixel_out(live_on_switch));
    
    // DISPLAY OFF switch
    picture_OFF 
        live_off_sw (.pixel_clk_in(pixel_clk), .x_in(OFF_LOC_X), .hcount_in(hcount), .y_in(OFF_LOC_Y), .vcount_in(vcount),
                .pixel_out(live_off_switch));
    
   // DISPLAY switch label             
   picture_display 
        display_lab (.pixel_clk_in(pixel_clk), .x_in(OFF_LOC_X + 5), .hcount_in(hcount), .y_in(OFF_LOC_Y - 58), .vcount_in(vcount),
                .pixel_out(display_label));
             
    // COLOR ON switch
    picture_ON 
        color_on_sw (.pixel_clk_in(pixel_clk), .x_in(ON_LOC_X + 250), .hcount_in(hcount), .y_in(ON_LOC_Y), .vcount_in(vcount),
                .pixel_out(color_on_switch));
    
    // COLOR OFF switch
    picture_OFF 
        color_off_sw (.pixel_clk_in(pixel_clk), .x_in(OFF_LOC_X + 250), .hcount_in(hcount), .y_in(OFF_LOC_Y), .vcount_in(vcount),
                .pixel_out(color_off_switch));
   
   // COLOR switch label             
   picture_color 
        color_lab (.pixel_clk_in(pixel_clk), .x_in(OFF_LOC_X + 255), .hcount_in(hcount), .y_in(OFF_LOC_Y - 55), .vcount_in(vcount),
                .pixel_out(color_label));
    
    // magnitude scale slider
    blob #(.WIDTH(200), .HEIGHT(10), .COLOR(12'b1000_1000_1000))
        scale1 (.x_in(SCALE_LOC_X), .hcount_in(hcount), .y_in(SCALE_LOC_Y), .vcount_in(vcount),
                .pixel_out(scale_line));  
                
    // magnitude scale "button"
    blob #(.WIDTH(5), .HEIGHT(10))
        scale2 (.x_in(scale_x), .hcount_in(hcount), .y_in(SCALE_LOC_Y + 10), .vcount_in(vcount),
                .pixel_out(scale_button));
     
    // magnitude scale number values           
    text_3 three (.x_in(SCALE_LOC_X + 205), .hcount_in(hcount), .y_in(SCALE_LOC_Y), .vcount_in(vcount),
              .pixel_out(pixels_3));
    
    text_0 zero (.x_in(SCALE_LOC_X - 12), .hcount_in(hcount), .y_in(SCALE_LOC_Y), .vcount_in(vcount),
              .pixel_out(pixels_0));
    
    // magnitude scale label             
    picture_mag_scale 
        mag_scale_lab (.pixel_clk_in(pixel_clk), .x_in(SCALE_LOC_X - 75), .hcount_in(hcount), .y_in(SCALE_LOC_Y - 60), .vcount_in(vcount),
                .pixel_out(mag_scale_label));
              
    // color scale slider
    blob #(.WIDTH(200), .HEIGHT(10), .COLOR(12'b1000_1000_1000))
        scale3 (.x_in(COLOR_SCALE_LOC_X), .hcount_in(hcount), .y_in(COLOR_SCALE_LOC_Y), .vcount_in(vcount),
                .pixel_out(color_scale_line));  
                
    // color scale "button"
    blob #(.WIDTH(5), .HEIGHT(10))
        scale4 (.x_in(color_scale_x), .hcount_in(hcount), .y_in(COLOR_SCALE_LOC_Y + 10), .vcount_in(vcount),
                .pixel_out(color_scale_button));
   
    // color scale number values             
    text_4 four (.x_in(COLOR_SCALE_LOC_X + 205), .hcount_in(hcount), .y_in(COLOR_SCALE_LOC_Y), .vcount_in(vcount),
              .pixel_out(color_pixels_4));
    
    text_0 zero2 (.x_in(COLOR_SCALE_LOC_X - 12), .hcount_in(hcount), .y_in(COLOR_SCALE_LOC_Y), .vcount_in(vcount),
              .pixel_out(color_pixels_0));
          
    // COLOR_SCALE label             
    picture_color_scale
        color_scale_lab (.pixel_clk_in(pixel_clk), .x_in(COLOR_SCALE_LOC_X - 33), .hcount_in(hcount), .y_in(COLOR_SCALE_LOC_Y - 60), .vcount_in(vcount),
                .pixel_out(color_scale_label));        

    // MUSICAL SCALES name            
    picture_scales
        scales (.pixel_clk_in(pixel_clk), .x_in(MUSICAL_SCALE_LOC_X ), .hcount_in(hcount), .y_in(MUSICAL_SCALE_LOC_Y ), .vcount_in(vcount),
                .pixel_out(scales_image));  
   
    // MUSICAL SCALES label           
    picture_musical_scale
        mus_scales_lab (.pixel_clk_in(pixel_clk), .x_in(MUSICAL_SCALE_LOC_X + 2), .hcount_in(hcount), .y_in(MUSICAL_SCALE_LOC_Y - 60), .vcount_in(vcount),
                .pixel_out(musical_scale_label));   
    
    // musical scales selector line
    blob #(.WIDTH(75), .HEIGHT(10), .COLOR(12'h00F))
        scale_sel_line (.x_in(musical_scale_sel_x), .hcount_in(hcount), .y_in(MUSICAL_SCALE_LOC_Y + 40), .vcount_in(vcount),
                .pixel_out(musical_scale_sel)); 
     
    // parameters included for combinational logic: displaying certain things based on states
    // PARAMS           
    parameter MAGNITUDE_SCALE = 3'b000;
    parameter SHOW_LIVE = 3'b001;
    parameter COLOR_PICK = 3'b010;
    parameter SCALE_COLOR = 3'b011;
    parameter MUSICAL_SCALE = 3'b100;    
    
    // STATES
    parameter WAITING = 4'b0000;        // waiting for a button press
    parameter UP_PRESSED = 4'b0001;     // 4 states for when any button is being held still
    parameter DOWN_PRESSED = 4'b0010;
    parameter NEXT_PRESSED = 4'b0011;
    parameter SET_PRESSED = 4'b0100;
    parameter UP_FUNCTION = 4'b0101;    // 4 states for respective button functions, 
    parameter DOWN_FUNCTION = 4'b0110;  // after button is released
    parameter NEXT_FUNCTION = 4'b0111;
    parameter SET_FUNCTION = 4'b1000;
    parameter SCROLL_PRESSED = 4'b1001; // scrolling through the next_state options
    parameter SCROLL_FUNCTION = 4'b1010;         
    
//////////////////////////////////////
//      
//          Visualizations (Graphs Setup)
//
//////////////////////////////////////
    
    // SPECTROGRAM
    parameter [11:0] SPEC_LOC_X = 600;      // actual graph at ()
    parameter [10:0] SPEC_LOC_Y = 75;
    parameter [9:0] SPEC_SIZE = 256;       // graph is 256 x 256 
    
    // REAL TIME MAGS
    parameter [11:0] MAGS_LOC_X = 600;      // actual graph at ()
    parameter [10:0] MAGS_LOC_Y = 400;
    parameter [9:0] MAGS_SIZE = 256;       // graph is 256 x 256 
    
    
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
                

    always_ff @(posedge pixel_clk)begin
        if (!blanking)begin //time to draw!
            rgb <= 12'b1000_1000_1000;
        end
        // check if you're in the part of the screen you want the mags graphs
        if (((hcount >= MAGS_LOC_X) && (hcount < MAGS_LOC_X + MAGS_SIZE)) && 
            ((vcount >= MAGS_LOC_Y)&& (vcount < MAGS_LOC_Y + MAGS_SIZE))) begin
            if (live) begin // display different data based on params
                draw_addr <= (hcount - MAGS_LOC_X)*8; // taking every 4 values
            end else draw_addr <= (hcount - MAGS_LOC_X)*4; // taking every 4 values
            if ((amp_out>>mag_scale)>=(MAGS_LOC_Y + MAGS_SIZE)-vcount)begin
                if (color) begin // display different data based on params
                    rgb <= sw[15:4];           // if color switch is ON, use switches
                end else rgb <= (amp_out[11:0] << scale_color); // if not, color based on magnitude
            end else rgb <= 12'b1000_1000_1000;   // background of real time (gray)
        end else if (((hcount >= SPEC_LOC_X) && (hcount < SPEC_LOC_X + SPEC_SIZE )) && 
            ((vcount >= SPEC_LOC_Y)&& (vcount < SPEC_LOC_Y + SPEC_SIZE ))) begin // check if you're in the part of the screen you want the mags graphs
            
                // gets the spec bram address
                spec_draw_addr <= ((hcount - SPEC_LOC_X)*SPEC_SIZE - (vcount - SPEC_LOC_Y));  
                                   
                // read the spec values
                rgb <= spec_pixels;
            
        // if not in eother grah territory, set pixel as all other possible things on the screen
        end else begin
            if (live && color) begin // dispalys on switches..
                if ((button_state == NEXT_PRESSED) | (button_state == NEXT_FUNCTION)| (button_state == SCROLL_PRESSED) | (button_state == SCROLL_FUNCTION)) begin 
                // displays green bar..    
                    rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selected_line | live_on_switch | color_on_switch 
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label | musical_scale_label | scales_image | musical_scale_sel;
                // displays red bar...
                end else rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selector_line | live_on_switch | color_on_switch
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label| musical_scale_label | scales_image | musical_scale_sel;
            end else if (color) begin   // dispalys color on, display off
                if ((button_state == NEXT_PRESSED) | (button_state == NEXT_FUNCTION)| (button_state == SCROLL_PRESSED) | (button_state == SCROLL_FUNCTION)) begin 
                    rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selected_line | live_off_switch | color_on_switch
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label| musical_scale_label | scales_image | musical_scale_sel;
                end else rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selector_line | live_off_switch | color_on_switch
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label| musical_scale_label | scales_image | musical_scale_sel;
            end else if (live) begin // dispaly display on, color off
                if ((button_state == NEXT_PRESSED) | (button_state == NEXT_FUNCTION)| (button_state == SCROLL_PRESSED) | (button_state == SCROLL_FUNCTION)) begin 
                    rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selected_line | live_on_switch | color_off_switch
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label| musical_scale_label | scales_image | musical_scale_sel;
                end else rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selector_line | live_on_switch | color_off_switch
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label| musical_scale_label | scales_image | musical_scale_sel;
            end else begin  // displays both off
                if ((button_state == NEXT_PRESSED) | (button_state == NEXT_FUNCTION)| (button_state == SCROLL_PRESSED) | (button_state == SCROLL_FUNCTION)) begin 
                    rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selected_line | live_off_switch | color_off_switch
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label| musical_scale_label | scales_image | musical_scale_sel;
                end else rgb <= x_axis_spec | y_axis_spec | x_label_spec | y_label_spec | graph_color_spec | graph_title_spec |
                                x_axis_mag | y_axis_mag | x_label_mag | y_label_mag | graph_title_mag | selector_line | live_off_switch | color_off_switch
                                | scale_button | scale_line | pixels_3 | pixels_0 | color_pixels_4 | color_pixels_0 | color_scale_line | color_scale_button
                                | color_label | display_label | mag_scale_label | color_scale_label| musical_scale_label | scales_image | musical_scale_sel;
            end                    
        end
    end



    always_ff @ (posedge vsync) begin        // every time there's a vsync, update the screen param selector info
            case (param)
                // selecotr bar has to change locations depending on the current parameter
                MAGNITUDE_SCALE: begin
                    // scaling slider
                    selector_line_x <= SCALE_LOC_X + 50;
                    selector_line_y <= SCALE_LOC_Y + 30;
                end
                COLOR_PICK: begin
                    // color switch
                    selector_line_x <= ON_LOC_X + 280;
                    selector_line_y <= ON_LOC_Y + 70;
                end
                SHOW_LIVE: begin
                    // display switch
                    selector_line_x <= ON_LOC_X + 30;
                    selector_line_y <= ON_LOC_Y + 70;
                end
                SCALE_COLOR: begin
                    // color scaling slider
                    selector_line_x <= COLOR_SCALE_LOC_X + 50;
                    selector_line_y <= COLOR_SCALE_LOC_Y + 30;
                end
                MUSICAL_SCALE: begin
                    // musical scaling
                    selector_line_x <= MUSICAL_SCALE_LOC_X + 115;
                    selector_line_y <= MUSICAL_SCALE_LOC_Y + 55;
                end
                default : begin // default location to default parameter
                    selector_line_x <= SCALE_LOC_X + 50;
                    selector_line_y <= SCALE_LOC_Y + 30;
                end
            endcase 
            
            case (mag_scale) 
                // location of slider for magnitude
                2'b00 : scale_x <= SCALE_LOC_X;
                2'b01 : scale_x <= SCALE_LOC_X + 70;
                2'b10 : scale_x <= SCALE_LOC_X + 70 + 70;
                2'b11 : scale_x <= SCALE_LOC_X + 195;
                default: scale_x <= SCALE_LOC_X;
            endcase
            
            case (scale_color) 
                // location of slider for color
                3'b000 : color_scale_x <= COLOR_SCALE_LOC_X;
                3'b001 : color_scale_x <= COLOR_SCALE_LOC_X + 40;
                3'b010 : color_scale_x <= COLOR_SCALE_LOC_X + 40 + 40;
                3'b011 : color_scale_x <= COLOR_SCALE_LOC_X + 40 + 40 + 40;
                3'b100 : color_scale_x <= COLOR_SCALE_LOC_X + 195;
                default: color_scale_x <= COLOR_SCALE_LOC_X;
            endcase
            
            case (musical_scale)
                // location of selector under different music scales
                2'b00 : musical_scale_sel_x <= MUSICAL_SCALE_LOC_X + 20;                 // c major
                2'b01 : musical_scale_sel_x <= MUSICAL_SCALE_LOC_X + 20 + 115;           // f major
                2'b10 : musical_scale_sel_x <= MUSICAL_SCALE_LOC_X + 115 + 115;          // c minor
                default: musical_scale_sel_x <= MUSICAL_SCALE_LOC_X + 20; 
            endcase
         
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

///////////////////////////////////////////////////////////////////////////////
//
// Pushbutton Debounce Module (video version - 24 bits)  
//
///////////////////////////////////////////////////////////////////////////////

module debounce (input reset_in, clock_in, noisy_in,
                 output logic clean_out);

   logic [19:0] count;
   logic new_input;

   always_ff @(posedge clock_in)
     if (reset_in) begin 
        new_input <= noisy_in; 
        clean_out <= noisy_in; 
        count <= 0; end
     else if (noisy_in != new_input) begin new_input<=noisy_in; count <= 0; end
     else if (count == 1000000) clean_out <= new_input;
     else count <= count+1;


endmodule



////////////////////////////////////////////////////////////////////////////////////
//// Update: 8/8/2019 GH 
//// Create Date: 10/02/2015 02:05:19 AM
//// Module Name: xvga
////
//// xvga: Generate VGA display signals (1024 x 768 @ 60Hz)
////
////                              ---- HORIZONTAL -----     ------VERTICAL -----
////                              Active                    Active
////                    Freq      Video   FP  Sync   BP      Video   FP  Sync  BP
////   640x480, 60Hz    25.175    640     16    96   48       480    11   2    31
////   800x600, 60Hz    40.000    800     40   128   88       600     1   4    23
////   1024x768, 60Hz   65.000    1024    24   136  160       768     3   6    29
////   1280x1024, 60Hz  108.00    1280    48   112  248       768     1   3    38
////   1280x720p 60Hz   75.25     1280    72    80  216       720     3   5    30
////   1920x1080 60Hz   148.5     1920    88    44  148      1080     4   5    36
////
//// change the clock frequency, front porches, sync's, and back porches to create 
//// other screen resolutions
//////////////////////////////////////////////////////////////////////////////////

//module xvga(input vclock_in,
//            output logic [10:0] hcount_out,    // pixel number on current line
//            output logic [9:0] vcount_out,     // line number
//            output logic vsync_out, hsync_out,
//            output logic blank_out);

//   parameter DISPLAY_WIDTH  = 1024;      // display width
//   parameter DISPLAY_HEIGHT = 768;       // number of lines

//   parameter  H_FP = 24;                 // horizontal front porch
//   parameter  H_SYNC_PULSE = 136;        // horizontal sync
//   parameter  H_BP = 160;                // horizontal back porch

//   parameter  V_FP = 3;                  // vertical front porch
//   parameter  V_SYNC_PULSE = 6;          // vertical sync 
//   parameter  V_BP = 29;                 // vertical back porch

//   // horizontal: 1344 pixels total
//   // display 1024 pixels per line
//   logic hblank,vblank;
//   logic hsyncon,hsyncoff,hreset,hblankon;
//   assign hblankon = (hcount_out == (DISPLAY_WIDTH -1));    
//   assign hsyncon = (hcount_out == (DISPLAY_WIDTH + H_FP - 1));  //1047
//   assign hsyncoff = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE - 1));  // 1183
//   assign hreset = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE + H_BP - 1));  //1343

//   // vertical: 806 lines total
//   // display 768 lines
//   logic vsyncon,vsyncoff,vreset,vblankon;
//   assign vblankon = hreset & (vcount_out == (DISPLAY_HEIGHT - 1));   // 767 
//   assign vsyncon = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP - 1));  // 771
//   assign vsyncoff = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE - 1));  // 777
//   assign vreset = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE + V_BP - 1)); // 805

//   // sync and blanking
//   logic next_hblank,next_vblank;
//   assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
//   assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
//   always_ff @(posedge vclock_in) begin
//      hcount_out <= hreset ? 0 : hcount_out + 1;
//      hblank <= next_hblank;
//      hsync_out <= hsyncon ? 0 : hsyncoff ? 1 : hsync_out;  // active low

//      vcount_out <= hreset ? (vreset ? 0 : vcount_out + 1) : vcount_out;
//      vblank <= next_vblank;
//      vsync_out <= vsyncon ? 0 : vsyncoff ? 1 : vsync_out;  // active low

//      blank_out <= next_vblank | (next_hblank & ~hreset);
//   end
//endmodule

      