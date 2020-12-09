`timescale 1ns / 1ps

module param_selector_tb;

// continuously changing/adding parameter names after testing of the module skeleton, may no longer be up to date

    logic clk;
    logic rst;
    logic down;
    logic up;
    logic next;
    logic set;
    logic [15:0] sw;
    
    logic [2:0] MUSICAL_SCALE_factor;
    logic [15:0] sampling_rate;
    logic [1:0] mode;
    logic [11:0] color;
    logic live;
    logic [3:0] button_state;
    logic [2:0] selector_val;
    
    

    param_selector uut (.clk_65mhz(clk), .rst(rst), 
                        .down(down), .up(up),
                        .next(next), .set(set),
                        .sw(sw), .MUSICAL_SCALE_factor(MUSICAL_SCALE_factor),
                        .sampling_rate(sampling_rate), .mode(mode), 
                        .live(live), .button_state(button_state), .color(color), .selector_val(selector_val));
    
    
    
    always #5 clk = ~clk;
    
    
    initial begin
        clk = 0;
        down = 0;
        up = 0;
        next = 0;
        set = 0;
        sw = 16'hF00;

        rst = 0;
        #10;
        rst = 1;
        #20
        rst = 0;
        #200;
        
        
        for (int i = 0; i < 5; i = i+1) begin //  flip through all the states
            up = 1;
            #20;
            up = 0;
            #100;
        end
        for (int i = 0; i < 5; i = i+1) begin //  flip through all the states backwards
            down = 1;
            #10;
            down = 0;
            #100;
        end
        
        //in MAGNITUDE_SCALE mode
        next = 1;
        #20;
        next = 0;
        #50;
        next = 1;
        #20;
        next = 0;
        #100;
        
        up = 1; // in show live mode
        #10;
        up = 0;
        #100;
        
        next = 1; // switch live on and off
        #10;
        next = 0;
        #50;
        next = 1;
        #10;
        next=0;
        #100;
        
        
        up = 1; // in show color pick mode
        #10;
        up = 0;
        #100;
        
        
        sw = 16'haeae;
        #10;
        set = 1;
        #10;
        set=0;
        #100;
        
        
        up = 1; // in sample rate mode
        #10;
        up = 0;
        #100;
        
        next = 1;
        #10;
        next = 0;
        #50;
        next = 1;
        #10;
        next = 0;
        #100;
        
        
        up = 1; // in oversample factor mode
        #10;
        up = 0;
        #100;
        
        next = 1;
        #10;
        next = 0;
        #50;
        next = 1;
        #10;
        next = 0;
        #100;
        
        sw = 16'h0000;
        set = 1;
        #20;
        set = 0;
        #100; // making sure colors wont switch unless in correct mode.
        
        rst = 1;
        #10;
        rst = 0;
        #100; // check everything goes back to deefaults
        
        
        
        
         
    end
    
endmodule

