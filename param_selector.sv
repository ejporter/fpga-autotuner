module param_selector(
        input logic clk_65mhz,
        input logic rst,
        input logic up,
        input logic down,
        input logic next,
        input logic set,
        input logic [15:0] sw,
        
        
        output logic [1:0] scale_choice,
        output logic [2:0] scale_color,
        output logic [1:0] mag_scale,
        output logic color,
        output logic live,
        output logic [3:0] button_state,
        output logic [2:0] selector_val
    );
    
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
    
    // SELECTOR VALS
    parameter MAGNITUDE_SCALE = 3'b000;          // parameter (selector) values for each thing that
    parameter SHOW_LIVE = 3'b001;                // can be picked & changed
    parameter COLOR_PICK = 3'b010;
    parameter SCALE_COLOR = 3'b011;
    parameter MUSICAL_SCALE = 3'b100;
    

    always_ff @(posedge clk_65mhz) begin
        if (rst) begin
            button_state <= WAITING;        // default: waiting for a button press
            scale_choice <= 2'b000;         // default : C major
            scale_color <= 3'b0;            // default: scale the color scheme by 0
            scale <= 2'b00;                 // deafult: scale the magnitude sizes by 0
            color <= 1'b0;                  // default: magnitude graph color mapped to mag values
            live <= 1'b0;                   // default: only show first half of the FFT values
            selector_val <= 3'b000;         // default to MAGNITUDE_SCALE mode

        end else begin
            case (button_state) 
                WAITING: begin      // check for button presses, change state accordingly
                    if (up) button_state <= UP_PRESSED;
                    else if (down) button_state <= DOWN_PRESSED;
                    else if (next) button_state <= NEXT_PRESSED;
                    else if (set) button_state <= SET_PRESSED;
                end
                
                // wait for button to be released
                UP_PRESSED: if (!up) button_state <= UP_FUNCTION;
                DOWN_PRESSED: if (!down) button_state <= DOWN_FUNCTION;
                NEXT_PRESSED: if (!next) button_state <= NEXT_FUNCTION;
                SET_PRESSED: if (!set) button_state <= SET_FUNCTION;
                SCROLL_PRESSED: if (!next) button_state <= SCROLL_FUNCTION;
                
                // perform functions of each button
                UP_FUNCTION: begin         // shift the value being selected by 1
                    case (selector_val)
                        MAGNITUDE_SCALE: selector_val <= SHOW_LIVE;
                        SHOW_LIVE: selector_val <= COLOR_PICK;
                        COLOR_PICK: selector_val <= MUSICAL_SCALE;
                        SCALE_COLOR: selector_val <= MAGNITUDE_SCALE;
                        MUSICAL_SCALE : selector_val <= SCALE_COLOR;
                        default : selector_val <= MAGNITUDE_SCALE;     
                    endcase 
                    button_state <= WAITING;    // reset button to waiting state
                end
                
                DOWN_FUNCTION: begin      // shift the value being selected by 1 (opp direction)
                    case (selector_val)
                        MAGNITUDE_SCALE: selector_val <= SCALE_COLOR;
                        SHOW_LIVE: selector_val <= MAGNITUDE_SCALE;
                        COLOR_PICK: selector_val <= SHOW_LIVE;
                        SCALE_COLOR: selector_val <= MUSICAL_SCALE;
                        MUSICAL_SCALE : selector_val <= COLOR_PICK;
                        default : selector_val <= MAGNITUDE_SCALE;     
                    endcase 
                    button_state <= WAITING;    // reset button to waiting state
                end
                
                NEXT_FUNCTION: begin                      
                    // inside next function, just waits for set button or another scroll
                    if (set) button_state <= SET_PRESSED;              // set button is pressed
                    else if (next) button_state <= SCROLL_PRESSED;     // scroll button gets pressed
                end
                
                SCROLL_FUNCTION: begin
                    case (selector_val) // scrolls through different things depending on which param you're changing
                        MAGNITUDE_SCALE: begin   // shifts through the values on the magnitude scale
                            case (scale) 
                                2'b00 : scale <= 2'b01;
                                2'b01 : scale <= 2'b10;
                                2'b10 : scale <= 2'b11;
                                2'b11 : scale <= 2'b00;
                                default : scale <= 2'b00;                       
                            endcase
                        end
                        SHOW_LIVE : live <= !live;      // switches the display mode (half or full)
                        COLOR_PICK : color <= !color;   // switch between color modes (constant or mags)
                        SCALE_COLOR: begin   
                            case (scale_color) // shifts through the values on the color scale
                                3'b000 : scale_color <= 3'b001;
                                3'b001 : scale_color <= 3'b010;
                                3'b010 : scale_color <= 3'b011;
                                3'b011 : scale_color <= 3'b100;
                                3'b100 : scale_color <= 3'b000;
                                default : scale_color <= 3'b000;                       
                            endcase 
                        end
                        MUSICAL_SCALE : begin  
                            case (scale_choice) // shifts through the different musical scales 
                                 2'b00 : scale_choice <= 2'b01;     // c major
                                 2'b01 : scale_choice <= 3'b10;     // f major
                                 2'b10 : scale_choice <= 2'b00;     // c minor
                                default : scale_choice <= 2'b00;
                            endcase
                        end
                    endcase
                    button_state <= NEXT_FUNCTION;      // wait for a set or another button press
                    end
                        
            SET_FUNCTION: button_state <= WAITING;      // reset back to waiting state
                
            endcase    
        end
    end
endmodule
