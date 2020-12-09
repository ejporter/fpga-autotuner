`timescale 1ns / 1ps

module tuning(
                input clk,
                input rst,
                input [2:0] scale_choice,
                input [15:0] fundamental_index,
                
                output logic [23:0] fcw
    );
    
    logic [23:0] rom_memory_c [1023:0];
    logic [23:0] rom_memory_f [1023:0];
    logic [23:0] rom_memory_cm [1023:0];
    
    initial begin
        $readmemh("c_major_lut.mem", rom_memory_c);
        $readmemh("f_major_lut.mem", rom_memory_f);
        $readmemh("c_minor_lut.mem", rom_memory_cm);
    end

    always_comb begin
      case(scale_choice)
        3'b110       :       fcw = rom_memory_c[fundamental_index];
        3'b010       :       fcw = rom_memory_f[fundamental_index];
        3'b100       :       fcw = rom_memory_cm[fundamental_index];
        default      :       fcw = rom_memory_c[fundamental_index];
      endcase
    end
endmodule
