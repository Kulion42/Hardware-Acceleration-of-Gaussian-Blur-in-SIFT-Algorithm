
parameter NUM_OF_IMGS_PER_OCTAVE = 6;
parameter MAX_WIDTH = 300;
parameter MAX_HEIGHT = 200;
parameter MIN_WIDTH = 64;
parameter MIN_HEIGHT = 32;

import uvm_pkg::*;
`include "uvm_macros.svh"

class gaussian_blur_config_rand extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    rand int rand_width;
    rand int rand_height;
    rand int rand_img_per_octave;
    int rand_offset_up;
    int rand_offset_down;
    rand int offset_p;
    rand int off_or_0;
    rand int off_or_1;
    //--------------------------------------------------------------------------------------------------------------------
    
    int img_in_data_arr[$];
    int offsets_arr[6] = {5, 6, 7, 8, 9, 10};

    `uvm_object_utils_begin(gaussian_blur_config_rand)
        `uvm_field_enum(uvm_active_passive_enum,is_active,UVM_DEFAULT)
    `uvm_object_utils_end
   	
    constraint rand_width_constr1 {rand_width >= MIN_WIDTH; rand_width < MAX_WIDTH;} 
    constraint rand_width_constr2 {rand_width % 2 == 0;}       
    constraint rand_height_constr1 {rand_height >= MIN_HEIGHT; rand_height < MAX_HEIGHT;}
    constraint rand_height_constr2 {(rand_img_per_octave == 0) -> (rand_height < MAX_HEIGHT - 10);}
    constraint rand_height_constr3 {(rand_img_per_octave == 0) -> (rand_height > MIN_HEIGHT + 10);}
    constraint rand_width_height_constr {rand_width >= rand_height;}
    constraint rand_offset_constr1 {offset_p >= 0; offset_p < 6;}
    constraint rand_offset_constr2 {offset_p dist {0:= 10, [1:5]:= 5};}  
    constraint rand_constr_ipo1 {rand_img_per_octave >= 0 ; rand_img_per_octave < NUM_OF_IMGS_PER_OCTAVE;}
    constraint rand_constr_ipo2 {rand_img_per_octave dist {0:= 15, [1:5]:/ 35 };}
    constraint rand_off_or_0_constr1 {off_or_0 >= 0; off_or_0 < 2;} 
    constraint rand_off_or_0_constr2 {(rand_img_per_octave != 0) -> (off_or_0 == 0);} 
    //constraint rand_off_or_0_constr3 {(rand_img_per_octave == 0) -> (off_or_0 == 1);} 
    constraint rand_off_or_1_constr1 {off_or_1 >= 0; off_or_1 < 2;} 
    constraint rand_off_or_1_constr2 {(rand_img_per_octave != 0) -> (off_or_1 == 0);} 
    //constraint rand_off_or_1_constr3 {(rand_img_per_octave == 0) -> (off_or_1 == 1);} 

     function new(string name = "gaussian_blur_config_rand");
        super.new(name);
     endfunction
        
    function void random_configuration;        
        //COLLECT COVERAGE
             
        $display("Image width : %0d", rand_width);
        $display("Image height : %0d", rand_height);
        rand_offset_up = off_or_0 ? offsets_arr[offset_p] : 0;
        $display("Image offset up : %0d", rand_offset_up);
        rand_offset_down = off_or_1 ? offsets_arr[offset_p] : 0;
        $display("Image offset down: %0d", rand_offset_down);
        $display("Image number image per octave: %0d", rand_img_per_octave);  
        
    endfunction : random_configuration           
    //------------------------------------------------------------------------------------
        
endclass : gaussian_blur_config_rand       
