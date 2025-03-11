`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/06/2025 02:50:59 PM
// Design Name: 
// Module Name: gaussian_blur_config
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

parameter NUM_OF_IMGS_PER_OCTAVE = 6;
parameter MAX_WIDTH = 300;
parameter MAX_HEIGHT = 200;

import uvm_pkg::*;
`include "uvm_macros.svh"

class gaussian_blur_config_ref extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    rand int rand_width;
    rand int rand_height;
    rand int rand_offset_up;
    rand int rand_offset_down;
    rand int rand_img_per_octave;
    
    //--------------------------------------------------------------------------------------------------------------------
    
    int img_in_data_arr[$];
    
    `uvm_object_utils_begin(gaussian_blur_config_ref)
        `uvm_field_enum(uvm_active_passive_enum,is_active,UVM_DEFAULT)
    `uvm_object_utils_end
   	
    constraint rand_width_constr1 {rand_width >= 64; rand_width < MAX_WIDTH;};   
    constraint rand_width_constr2 {rand_width % 2 == 0;};       
    constraint rand_height_constr {rand_height >= 32; rand_height < MAX_HEIGHT;};
    constraint rand_width_height_constr {rand_width >= rand_height;};
    constraint rand_offset_up_constr {rand_offset_up inside {0, 10};};  
    constraint rand_offset_down_constr {rand_offset_down inside {0, 10};};  
    constraint rand_offset_up_constr1 {(rand_img_per_octave != 0) -> (rand_offset_up == 0);};  
    constraint rand_offset_down_constr1 {(rand_img_per_octave != 0) -> (rand_offset_down == 0);};
    constraint rand_constr_ipo1 {rand_img_per_octave >= 0 ; rand_img_per_octave < NUM_OF_IMGS_PER_OCTAVE;}; 
    constraint rand_constr_ipo2 {rand_img_per_octave dist {0:/ 15, [1:5]:/ 35 };}
    
     function new(string name = "gaussian_blur_config_ref");
        super.new(name);
     endfunction
        
    function void random_configuration;        
        //COLLECT COVERAGE
             
        $display("Image width : %0d", rand_width);
        $display("Image height : %0d", rand_height);
        $display("Image offset up : %0d", rand_offset_up);
        $display("Image offset down: %0d", rand_offset_down);
        $display("Image number image per octave: %0d", rand_img_per_octave);  
        
    endfunction : random_configuration           
    //------------------------------------------------------------------------------------
        
endclass : gaussian_blur_config_ref       
