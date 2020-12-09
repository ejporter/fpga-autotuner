`timescale 1ns / 1ps


//////////////////////////////////////////////////////////////////////
//
// blob: generate rectangle on screen
//
//////////////////////////////////////////////////////////////////////
module blob
   #(parameter WIDTH = 64,            // default width: 64 pixels
               HEIGHT = 64,           // default height: 64 pixels
               COLOR = 12'hFFF)  // default color: white
   (input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

   always_comb begin
      if ((hcount_in >= x_in && hcount_in < (x_in+WIDTH)) &&
	       (vcount_in >= y_in && vcount_in < (y_in+HEIGHT)))
	       pixel_out = COLOR;
      else pixel_out = 0;
   end
endmodule

////////////////////////////////////////////////////
//
// picture_blob: generate visuals for UI
//
//////////////////////////////////////////////////
module picture_blob
   #(parameter WIDTH = 256,     // default picture width
               HEIGHT = 256)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for SLIDER image
    slider_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    slider_red rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
    slider_green gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
    slider_blue bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], green_mapped[7:4], blue_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule


////////////////////////////////////////////////////
//
// picture_ON: generate on version of switch
//
//////////////////////////////////////////////////
module picture_ON
   #(parameter WIDTH = 147,     // default picture width
               HEIGHT = 62)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for SLIDER image
    ON_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    ON_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
    ON_gcm gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
    ON_bcm bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], green_mapped[7:4], blue_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule


////////////////////////////////////////////////////
//
// picture_OFF: generate off version of switch
//
//////////////////////////////////////////////////
module picture_OFF
   #(parameter WIDTH = 150,     // default picture width
               HEIGHT = 78)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for SLIDER image
    OFF_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    OFF_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
    OFF_gcm gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
    OFF_bcm bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], green_mapped[7:4], blue_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule

////////////////////////////////////////////////////
//
// picture_color: generate visuals for UI
//
//////////////////////////////////////////////////
module picture_color
   #(parameter WIDTH = 137,     // default picture width
               HEIGHT = 50)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for "COLOR" label
    color_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    color_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
//    slider_green gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
//    slider_blue bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], red_mapped[7:4], red_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule


////////////////////////////////////////////////////
//
// picture_display: generate visuals for UI
//
//////////////////////////////////////////////////
module picture_display
   #(parameter WIDTH = 170,     // default picture width
               HEIGHT = 51)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for "DISPLAY" label
    display_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    display_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
//    slider_green gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
//    slider_blue bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], red_mapped[7:4], red_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule


////////////////////////////////////////////////////
//
// picture_mag_scale: generate visuals for UI
//
//////////////////////////////////////////////////
module picture_mag_scale
   #(parameter WIDTH = 353,     // default picture width
               HEIGHT = 47)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for "MAGNITUDE SCALE" label
    mag_scale_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    mag_scale_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
//    slider_green gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
//    slider_blue bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], red_mapped[7:4], red_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule


////////////////////////////////////////////////////
//
// picture_color_scale: generate visuals for UI
//
//////////////////////////////////////////////////
module picture_color_scale
   #(parameter WIDTH = 261,     // default picture width
               HEIGHT = 47)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for "COLOR SCALE" label
    color_scale_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    color_scale_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
//    slider_green gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
//    slider_blue bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], red_mapped[7:4], red_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule


////////////////////////////////////////////////////
//
// picture_musical_scale: generate visuals for UI
//
//////////////////////////////////////////////////
module picture_musical_scale
   #(parameter WIDTH = 301,     // default picture width
               HEIGHT = 52)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for "MUSICAL SCALE" label
    musical_scale_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    musical_scale_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
//    slider_green gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
//    slider_blue bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], red_mapped[7:4], red_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule

////////////////////////////////////////////////////
//
// picture_scales: generate visuals for UI
//
//////////////////////////////////////////////////
module picture_scales
   #(parameter WIDTH = 308,     // default picture width
               HEIGHT = 32)    // default picture height
   (input pixel_clk_in,
    input [10:0] x_in,hcount_in,
    input [9:0] y_in,vcount_in,
    output logic [11:0] pixel_out);

    logic [17:0] image_addr; 
    assign image_addr = (hcount_in-x_in) + (vcount_in-y_in) * WIDTH;

    logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;
    
    // color map information for different scales
    scales_image image(.clka(pixel_clk_in), .addra(image_addr), .douta(image_bits));
    
    scales_rcm rcm(.clka(pixel_clk_in), .addra(image_bits), .douta(red_mapped));
//    slider_green gcm(.clka(pixel_clk_in), .addra(image_bits), .douta(green_mapped));
//    slider_blue bcm(.clka(pixel_clk_in), .addra(image_bits), .douta(blue_mapped));

    always @ (posedge pixel_clk_in) begin
      if ((hcount_in >= x_in  && hcount_in < (x_in+WIDTH)) &&
          (vcount_in >= y_in && vcount_in < (y_in+HEIGHT))) begin

             // use MSB 4 bits
             pixel_out <= {red_mapped[7:4], red_mapped[7:4], red_mapped[7:4]};
         end else pixel_out <= 0;
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Update: 8/8/2019 GH
// Create Date: 10/02/2015 02:05:19 AM
// Module Name: xvga
//
// xvga: Generate VGA display signals (1024 x 768 @ 60Hz)
//
//                              ---- HORIZONTAL -----     ------VERTICAL -----
//                              Active                    Active
//                    Freq      Video   FP  Sync   BP      Video   FP  Sync  BP
//   640x480, 60Hz    25.175    640     16    96   48       480    11   2    31
//   800x600, 60Hz    40.000    800     40   128   88       600     1   4    23
//   1024x768, 60Hz   65.000    1024    24   136  160       768     3   6    29
//   1280x1024, 60Hz  108.00    1280    48   112  248       768     1   3    38
//   1280x720p 60Hz   75.25     1280    72    80  216       720     3   5    30
//   1920x1080 60Hz   148.5     1920    88    44  148      1080     4   5    36
//
// change the clock frequency, front porches, sync's, and back porches to create
// other screen resolutions
////////////////////////////////////////////////////////////////////////////////

module xvga(input vclock_in,
            output reg [10:0] hcount_out,    // pixel number on current line
            output reg [9:0] vcount_out,     // line number
            output reg vsync_out, hsync_out,
            output reg blank_out);

   parameter DISPLAY_WIDTH  = 1024;      // display width
   parameter DISPLAY_HEIGHT = 768;       // number of lines

   parameter  H_FP = 24;                 // horizontal front porch
   parameter  H_SYNC_PULSE = 136;        // horizontal sync
   parameter  H_BP = 160;                // horizontal back porch

   parameter  V_FP = 3;                  // vertical front porch
   parameter  V_SYNC_PULSE = 6;          // vertical sync
   parameter  V_BP = 29;                 // vertical back porch

   // horizontal: 1344 pixels total
   // display 1024 pixels per line
   reg hblank,vblank;
   wire hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount_out == (DISPLAY_WIDTH -1));
   assign hsyncon = (hcount_out == (DISPLAY_WIDTH + H_FP - 1));  //1047
   assign hsyncoff = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE - 1));  // 1183
   assign hreset = (hcount_out == (DISPLAY_WIDTH + H_FP + H_SYNC_PULSE + H_BP - 1));  //1343

   // vertical: 806 lines total
   // display 768 lines
   wire vsyncon,vsyncoff,vreset,vblankon;
   assign vblankon = hreset & (vcount_out == (DISPLAY_HEIGHT - 1));   // 767
   assign vsyncon = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP - 1));  // 771
   assign vsyncoff = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE - 1));  // 777
   assign vreset = hreset & (vcount_out == (DISPLAY_HEIGHT + V_FP + V_SYNC_PULSE + V_BP - 1)); // 805

   // sync and blanking
   wire next_hblank,next_vblank;
   assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
   assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   always_ff @(posedge vclock_in) begin
      hcount_out <= hreset ? 0 : hcount_out + 1;
      hblank <= next_hblank;
      hsync_out <= hsyncon ? 0 : hsyncoff ? 1 : hsync_out;  // active low

      vcount_out <= hreset ? (vreset ? 0 : vcount_out + 1) : vcount_out;
      vblank <= next_vblank;
      vsync_out <= vsyncon ? 0 : vsyncoff ? 1 : vsync_out;  // active low

      blank_out <= next_vblank | (next_hblank & ~hreset);
   end

endmodule

////////////////////////////////////////////////////
//
// letters_time: writes the word 'time'
//
//////////////////////////////////////////////////
module letters_time(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] pixels_t, pixels_i, pixels_m, pixels_e;

    text_t t (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_t));
    text_i i (.x_in(x_in + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_i));
    text_m m (.x_in(x_in + 12 + 6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_m));
    text_e e (.x_in(x_in + 12 + 6 + 18), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_e));

    assign pixel_out = pixels_t | pixels_i | pixels_m | pixels_e;
endmodule

////////////////////////////////////////////////////
//
// letters_freq: writes the word 'freq' (VERTICALLY FOR SPEC)
//
//////////////////////////////////////////////////
module letters_freq1(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] pixels_f, pixels_r, pixels_e, pixels_q;

    text_f f (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_f));
    text_r r (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in+16), .vcount_in(vcount_in),
              .pixel_out(pixels_r));
    text_e e (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in+16+16), .vcount_in(vcount_in),
              .pixel_out(pixels_e));
    text_q q (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in+16+16+16), .vcount_in(vcount_in),
              .pixel_out(pixels_q));

    assign pixel_out = pixels_f | pixels_r | pixels_e | pixels_q;
endmodule

////////////////////////////////////////////////////
//
// letters_freq: writes the word 'freq' (HORIZONTALLY FOR MAG)
//
//////////////////////////////////////////////////
module letters_freq2(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] pixels_f, pixels_r, pixels_e, pixels_q;

    text_f f (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_f));
    text_r r (.x_in(x_in + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_r));
    text_e e (.x_in(x_in + 12 + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_e));
    text_q q (.x_in(x_in + 12 + 12 +12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_q));

    assign pixel_out = pixels_f | pixels_r | pixels_e | pixels_q;
endmodule

////////////////////////////////////////////////////
//
// letters_mag: writes the word 'mag'
//
//////////////////////////////////////////////////
module letters_mag(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );
    
    logic [11:0] pixels_m, pixels_a, pixels_g;

    text_m m (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_m));
              
    text_a a (.x_in(x_in+2), .hcount_in(hcount_in), .y_in(y_in + 16), .vcount_in(vcount_in),
              .pixel_out(pixels_a));
              
    text_g g (.x_in(x_in+2), .hcount_in(hcount_in), .y_in(y_in + 16 + 16), .vcount_in(vcount_in),
              .pixel_out(pixels_g));
              
    assign pixel_out = pixels_m | pixels_a | pixels_g;
endmodule

////////////////////////////////////////////////////
//
// letters_spectrogram: writes the word 'spectrogram'
//
//////////////////////////////////////////////////
module letters_spectrogram(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] pixels_s, pixels_p, pixels_e, pixels_c,
                pixels_t, pixles_r1, pixels_o, pixels_g,
                pixels_r2, pixels_a, pixels_m;

    text_s s (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_s));
    text_p p (.x_in(x_in + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_p));
    text_e e (.x_in(x_in + 12 + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_e));
    text_c c (.x_in(x_in + 12 + 12 + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
              .pixel_out(pixels_c));

    assign pixel_out = pixels_s | pixels_p | pixels_e | pixels_c;
endmodule

////////////////////////////////////////////////////
//
// letters_volume: writes the word 'volume'
//
//////////////////////////////////////////////////
//module letters_volume(
//   input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   logic [11:0] pixels_v, pixels_o, pixels_l, pixels_u,
//                pixels_m, pixels_e;

//    text_v v (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//              .pixel_out(pixels_v));
//    text_o o (.x_in(x_in + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//              .pixel_out(pixels_o));
//    text_l l (.x_in(x_in + 12 + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//              .pixel_out(pixels_l));
//    text_u u (.x_in(x_in + 12 + 12 + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//              .pixel_out(pixels_u));
//    text_m m (.x_in(x_in + 12 + 12 + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//              .pixel_out(pixels_m));
//    text_e e (.x_in(x_in + 12 + 12 + 12), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//              .pixel_out(pixels_e));

//    assign pixel_out = pixels_v | pixels_o | pixels_l | pixels_u | pixels_m | pixels_e;
//endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate a T
//
//////////////////////////////////////////////////////////////////////
module text_t(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel;

   //top bar
   blob #(.WIDTH(9), .HEIGHT(3))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //long bar
   blob #(.WIDTH(3), .HEIGHT(10))
     blob2 (.x_in(x_in + 3), .hcount_in(hcount_in), .y_in(y_in + 3), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel;

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate a I
//
//////////////////////////////////////////////////////////////////////
module text_i
   (input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   //long bar
   blob #(.WIDTH(3), .HEIGHT(13))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(pixel_out));

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an m
//
//////////////////////////////////////////////////////////////////////
module text_m(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel;

   //top bar
   blob #(.WIDTH(15), .HEIGHT(3))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //left leg
   blob #(.WIDTH(3), .HEIGHT(10))
     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 3), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));

   //middle leg
   blob #(.WIDTH(3), .HEIGHT(10))
     blob3 (.x_in(x_in + 6), .hcount_in(hcount_in), .y_in(y_in + 3), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   //right leg
   blob #(.WIDTH(3), .HEIGHT(10))
     blob4 (.x_in(x_in + 12), .hcount_in(hcount_in), .y_in(y_in + 3), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel;

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an e
//
//////////////////////////////////////////////////////////////////////
module text_e(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel;

   //spine
   blob #(.WIDTH(3), .HEIGHT(13))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //top bar
   blob #(.WIDTH(10), .HEIGHT(3))
     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));

   //middle bar
   blob #(.WIDTH(8), .HEIGHT(1))
     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 6), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   //bottom bar
   blob #(.WIDTH(10), .HEIGHT(3))
     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 10), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel;

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an f
//
//////////////////////////////////////////////////////////////////////
module text_f(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel;

   //spine
   blob #(.WIDTH(3), .HEIGHT(13))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //top bar
   blob #(.WIDTH(10), .HEIGHT(3))
     blob2 (.x_in(x_in ), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));

   //bottom bar
   blob #(.WIDTH(7), .HEIGHT(3))
     blob3 (.x_in(x_in + 3), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel;

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an q
//
//////////////////////////////////////////////////////////////////////
module text_q(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel;

   //left wall
   blob #(.WIDTH(3), .HEIGHT(10))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //right wall
   blob #(.WIDTH(3), .HEIGHT(10))
     blob2 (.x_in(x_in + 6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));
   //top bar
   blob #(.WIDTH(9), .HEIGHT(3))
     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   //bottom bar
   blob #(.WIDTH(9), .HEIGHT(3))
     blob4 (.x_in(x_in + 3), .hcount_in(hcount_in), .y_in(y_in + 10), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel;

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an r
//
//////////////////////////////////////////////////////////////////////
module text_r(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;

   //spine
   blob #(.WIDTH(3), .HEIGHT(13))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //right wall of head
   blob #(.WIDTH(3), .HEIGHT(6))
     blob2 (.x_in(x_in + 5), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));

   //leg
   blob #(.WIDTH(3), .HEIGHT(7))
     blob3 (.x_in(x_in+7), .hcount_in(hcount_in), .y_in(y_in + 6), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   //top bar of head
   blob #(.WIDTH(8), .HEIGHT(3))
     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));

   //bottom bar of head
   blob #(.WIDTH(9), .HEIGHT(1))
     blob5 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
             .pixel_out(blob5_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel;

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an p
//
//////////////////////////////////////////////////////////////////////
module text_p(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel;
   
   //spine
   blob #(.WIDTH(3), .HEIGHT(13))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));
             
   // top
   blob #(.WIDTH(9), .HEIGHT(3))
     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));
             
   //bottom of head
   blob #(.WIDTH(9), .HEIGHT(2))
     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 6), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));
             
   //right wall of head
   blob #(.WIDTH(3), .HEIGHT(6))
     blob4 (.x_in(x_in + 6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel;          
endmodule


//////////////////////////////////////////////////////////////////////
//
// text: generate an s
//
//////////////////////////////////////////////////////////////////////
module text_s(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;
   
   //top
   blob #(.WIDTH(8), .HEIGHT(3))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));
             
   //side1
   blob #(.WIDTH(3), .HEIGHT(6))
     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));
             
   // middle
   blob #(.WIDTH(9), .HEIGHT(2))
     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in+5), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));
             
   //side2
   blob #(.WIDTH(3), .HEIGHT(7))
     blob4 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in+6), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));
  
   //bottom
   blob #(.WIDTH(9), .HEIGHT(3))
     blob5 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in+10), .vcount_in(vcount_in),
             .pixel_out(blob5_pixel));
      
   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel;          
endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an c
//
//////////////////////////////////////////////////////////////////////
module text_c(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel;
   
   //spine
   blob #(.WIDTH(3), .HEIGHT(13))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));
             
   // top
   blob #(.WIDTH(9), .HEIGHT(3))
     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));
  
   //bottom
   blob #(.WIDTH(9), .HEIGHT(3))
     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in+10), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));
      
   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel;          
endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate an a
//
//////////////////////////////////////////////////////////////////////
module text_a(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel;
   
   // left side
   blob #(.WIDTH(3), .HEIGHT(10))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 3), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));
  
   // right side
   blob #(.WIDTH(3), .HEIGHT(10))
     blob2 (.x_in(x_in + 8), .hcount_in(hcount_in), .y_in(y_in + 3), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));
             
   // top
   blob #(.WIDTH(5), .HEIGHT(3))
     blob3 (.x_in(x_in + 3), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));
  
   // middle
   blob #(.WIDTH(9), .HEIGHT(1))
     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 6), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));
  
  assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel; 
endmodule
  
  
//////////////////////////////////////////////////////////////////////
//
// text: generate an g
//
//////////////////////////////////////////////////////////////////////
module text_g(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;
   
   // left side
   blob #(.WIDTH(3), .HEIGHT(10))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 2), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));
  
   // right side
   blob #(.WIDTH(2), .HEIGHT(4))
     blob2 (.x_in(x_in + 8), .hcount_in(hcount_in), .y_in(y_in + 7), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));
             
   // top
   blob #(.WIDTH(8), .HEIGHT(3))
     blob3 (.x_in(x_in + 2), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));
     
   // middle
   blob #(.WIDTH(3), .HEIGHT(1))
     blob4 (.x_in(x_in + 6), .hcount_in(hcount_in), .y_in(y_in + 6), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));  
             
   // bottom
   blob #(.WIDTH(8), .HEIGHT(3))
     blob5 (.x_in(x_in + 2), .hcount_in(hcount_in), .y_in(y_in + 10), .vcount_in(vcount_in),
             .pixel_out(blob5_pixel));
  

  
  assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel; 
endmodule
  

//////////////////////////////////////////////////////////////////////
//
// text: generate an 0
//
//////////////////////////////////////////////////////////////////////
module text_0(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel;

   //left
   blob #(.WIDTH(3), .HEIGHT(10))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //right
   blob #(.WIDTH(3), .HEIGHT(10))
     blob2 (.x_in(x_in + 6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));
   //top
   blob #(.WIDTH(9), .HEIGHT(3))
     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   //bottom
   blob #(.WIDTH(9), .HEIGHT(3))
     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 10), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel;

endmodule

////////////////////////////////////////////////////////////////////////
////
//// text: generate a 1
////
////////////////////////////////////////////////////////////////////////
//module text_1
//   (input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   //long bar
//   blob #(.WIDTH(3), .HEIGHT(13))
//     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(pixel_out));

//endmodule

////////////////////////////////////////////////////////////////////////
////
//// text: generate a 2
////
////
////////////////////////////////////////////////////////////////////////
//module text_2(
//   input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;

//   //top
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob1_pixel));

//   //bottom
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in +10), .vcount_in(vcount_in),
//             .pixel_out(blob2_pixel));

//   //middle
//   blob #(.WIDTH(9), .HEIGHT(1))
//     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
//             .pixel_out(blob3_pixel));

//   //lower left connection
//   blob #(.WIDTH(3), .HEIGHT(6))
//     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in+5), .vcount_in(vcount_in),
//             .pixel_out(blob4_pixel));

//   //upper right connection
//   blob #(.WIDTH(3), .HEIGHT(6))
//     blob5 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob5_pixel));

//   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel;

//endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate a 3
//
//////////////////////////////////////////////////////////////////////
module text_3(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel;

   //spine
   blob #(.WIDTH(3), .HEIGHT(13))
     blob1 (.x_in(x_in+7), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //top
   blob #(.WIDTH(10), .HEIGHT(3))
     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));

   //middle
   blob #(.WIDTH(7), .HEIGHT(1))
     blob3 (.x_in(x_in+3), .hcount_in(hcount_in), .y_in(y_in + 6), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   //bottom
   blob #(.WIDTH(10), .HEIGHT(3))
     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 10), .vcount_in(vcount_in),
             .pixel_out(blob4_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel;

endmodule

//////////////////////////////////////////////////////////////////////
//
// text: generate a 4
//
//
//////////////////////////////////////////////////////////////////////
module text_4(
   input [10:0] x_in,hcount_in,
   input [9:0] y_in,vcount_in,
   output logic [11:0] pixel_out
   );

   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel;


   //horizontal
   blob #(.WIDTH(9), .HEIGHT(2))
     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
             .pixel_out(blob1_pixel));

   //left side
   blob #(.WIDTH(3), .HEIGHT(5))
     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob2_pixel));

   //spine
   blob #(.WIDTH(3), .HEIGHT(13))
     blob3 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
             .pixel_out(blob3_pixel));

   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel;

endmodule

////////////////////////////////////////////////////////////////////////
////
//// text: generate a 5
////
////
////////////////////////////////////////////////////////////////////////
//module text_5(
//   input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;

//   //top
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob1_pixel));

//   //bottom
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in +10), .vcount_in(vcount_in),
//             .pixel_out(blob2_pixel));

//   //middle
//   blob #(.WIDTH(9), .HEIGHT(1))
//     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
//             .pixel_out(blob3_pixel));

//   //upper left connection
//   blob #(.WIDTH(3), .HEIGHT(6))
//     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob4_pixel));

//   //lower right connection
//   blob #(.WIDTH(3), .HEIGHT(6))
//     blob5 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
//             .pixel_out(blob5_pixel));

//   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel;

//endmodule

////////////////////////////////////////////////////////////////////////
////
//// text: generate a 6
////
////
////////////////////////////////////////////////////////////////////////
//module text_6(
//   input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;

//   //top
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob1_pixel));

//   //bottom
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in +10), .vcount_in(vcount_in),
//             .pixel_out(blob2_pixel));

//   //middle
//   blob #(.WIDTH(9), .HEIGHT(1))
//     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
//             .pixel_out(blob3_pixel));

//   //left
//   blob #(.WIDTH(3), .HEIGHT(13))
//     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob4_pixel));

//   //lower right 
//   blob #(.WIDTH(3), .HEIGHT(6))
//     blob5 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
//             .pixel_out(blob5_pixel));

//   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel;

//endmodule

////////////////////////////////////////////////////////////////////////
////
//// text: generate an 7
////
////
////////////////////////////////////////////////////////////////////////
//module text_7(
//   input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   logic [11:0] blob1_pixel, blob2_pixel;

//   //top
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob1_pixel));

//   //right
//   blob #(.WIDTH(3), .HEIGHT(13))
//     blob5 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob2_pixel));

//   assign pixel_out = blob1_pixel | blob2_pixel;

//endmodule

////////////////////////////////////////////////////////////////////////
////
//// text: generate an 8
////
////
////////////////////////////////////////////////////////////////////////
//module text_8(
//   input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;

//   //top
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob1_pixel));

//   //bottom
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in +10), .vcount_in(vcount_in),
//             .pixel_out(blob2_pixel));

//   //middle
//   blob #(.WIDTH(9), .HEIGHT(2))
//     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
//             .pixel_out(blob3_pixel));

//   //left
//   blob #(.WIDTH(3), .HEIGHT(13))
//     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob4_pixel));

//   //right
//   blob #(.WIDTH(3), .HEIGHT(13))
//     blob5 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob5_pixel));

//   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel;

//endmodule

////////////////////////////////////////////////////////////////////////
////
//// text: generate a 9
////
////
////////////////////////////////////////////////////////////////////////
//module text_9(
//   input [10:0] x_in,hcount_in,
//   input [9:0] y_in,vcount_in,
//   output logic [11:0] pixel_out
//   );

//   logic [11:0] blob1_pixel, blob2_pixel, blob3_pixel, blob4_pixel, blob5_pixel;

//   //top
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob1 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob1_pixel));

//   //bottom
//   blob #(.WIDTH(9), .HEIGHT(3))
//     blob2 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in +10), .vcount_in(vcount_in),
//             .pixel_out(blob2_pixel));

//   //middle
//   blob #(.WIDTH(9), .HEIGHT(1))
//     blob3 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in + 5), .vcount_in(vcount_in),
//             .pixel_out(blob3_pixel));

//   //left
//   blob #(.WIDTH(3), .HEIGHT(6))
//     blob4 (.x_in(x_in), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob4_pixel));

//   //right
//   blob #(.WIDTH(3), .HEIGHT(13))
//     blob5 (.x_in(x_in+6), .hcount_in(hcount_in), .y_in(y_in), .vcount_in(vcount_in),
//             .pixel_out(blob5_pixel));

//   assign pixel_out = blob1_pixel | blob2_pixel | blob3_pixel | blob4_pixel | blob5_pixel;

//endmodule


//////////////////////////////////////////////////////////////////////////////////
// Engineer:   g.p.hom
//
// Create Date:    18:18:59 04/21/2013
// Module Name:    display_8hex
// Description:  Display 8 hex numbers on 7 segment display
//
//////////////////////////////////////////////////////////////////////////////////

//module display_8hex(
//    input clk_in,                 // system clock
//    input [31:0] data_in,         // 8 hex numbers, msb first
//    output reg [6:0] seg_out,     // seven segment display output
//    output reg [7:0] strobe_out   // digit strobe
//    );

//    localparam bits = 13;

//    reg [bits:0] counter = 0;  // clear on power up

//    wire [6:0] segments[15:0]; // 16 7 bit memorys
//    assign segments[0]  = 7'b100_0000;  // inverted logic
//    assign segments[1]  = 7'b111_1001;  // gfedcba
//    assign segments[2]  = 7'b010_0100;
//    assign segments[3]  = 7'b011_0000;
//    assign segments[4]  = 7'b001_1001;
//    assign segments[5]  = 7'b001_0010;
//    assign segments[6]  = 7'b000_0010;
//    assign segments[7]  = 7'b111_1000;
//    assign segments[8]  = 7'b000_0000;
//    assign segments[9]  = 7'b001_1000;
//    assign segments[10] = 7'b000_1000;
//    assign segments[11] = 7'b000_0011;
//    assign segments[12] = 7'b010_0111;
//    assign segments[13] = 7'b010_0001;
//    assign segments[14] = 7'b000_0110;
//    assign segments[15] = 7'b000_1110;

//    always_ff @(posedge clk_in) begin
//      // Here I am using a counter and select 3 bits which provides
//      // a reasonable refresh rate starting the left most digit
//      // and moving left.
//      counter <= counter + 1;
//      case (counter[bits:bits-2])
//          3'b000: begin  // use the MSB 4 bits
//                  seg_out <= segments[data_in[31:28]];
//                  strobe_out <= 8'b0111_1111 ;
//                 end

//          3'b001: begin
//                  seg_out <= segments[data_in[27:24]];
//                  strobe_out <= 8'b1011_1111 ;
//                 end

//          3'b010: begin
//                   seg_out <= segments[data_in[23:20]];
//                   strobe_out <= 8'b1101_1111 ;
//                  end
//          3'b011: begin
//                  seg_out <= segments[data_in[19:16]];
//                  strobe_out <= 8'b1110_1111;
//                 end
//          3'b100: begin
//                  seg_out <= segments[data_in[15:12]];
//                  strobe_out <= 8'b1111_0111;
//                 end

//          3'b101: begin
//                  seg_out <= segments[data_in[11:8]];
//                  strobe_out <= 8'b1111_1011;
//                 end

//          3'b110: begin
//                   seg_out <= segments[data_in[7:4]];
//                   strobe_out <= 8'b1111_1101;
//                  end
//          3'b111: begin
//                  seg_out <= segments[data_in[3:0]];
//                  strobe_out <= 8'b1111_1110;
//                 end

//       endcase
//      end

//endmodule
