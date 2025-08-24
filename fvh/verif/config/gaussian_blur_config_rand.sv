
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
    int ref_out_data_arr[$];
    int offsets_arr[6] = {5, 6, 7, 8, 9, 10};

    `uvm_object_utils_begin(gaussian_blur_config_rand)
        `uvm_field_enum(uvm_active_passive_enum,is_active,UVM_DEFAULT)
    `uvm_object_utils_end

    covergroup img_cover_offsets();
        option.per_instance = 1;
        ofset_up_cover: coverpoint rand_offset_up{
            bins off0 = {0};
            bins off5 = {5};
            bins off6 = {6};
            bins off7 = {7};
            bins off8 = {8};
            bins off9 = {9};
            bins off10 = {10};
        }
        ofset_down_cover: coverpoint rand_offset_down{
            bins off0 = {0};
            bins off5 = {5};
            bins off6 = {6};
            bins off7 = {7};
            bins off8 = {8};
            bins off9 = {9};
            bins off10 = {10};
        }

        ofset_comb_cover: cross ofset_up_cover, ofset_down_cover{
            bins up_0_down_0 = binsof(ofset_up_cover) intersect {0} && binsof(ofset_down_cover) intersect {0};
            bins up_0_down_5 = binsof(ofset_up_cover) intersect {0} && binsof(ofset_down_cover) intersect {5};
            bins up_0_down_6 = binsof(ofset_up_cover) intersect {0} && binsof(ofset_down_cover) intersect {6};
            bins up_0_down_7 = binsof(ofset_up_cover) intersect {0} && binsof(ofset_down_cover) intersect {7};
            bins up_0_down_8 = binsof(ofset_up_cover) intersect {0} && binsof(ofset_down_cover) intersect {8};
            bins up_0_down_9 = binsof(ofset_up_cover) intersect {0} && binsof(ofset_down_cover) intersect {9};
            bins up_0_down_10 = binsof(ofset_up_cover) intersect {0} && binsof(ofset_down_cover) intersect {10};

            bins up_5_down_0 = binsof(ofset_up_cover) intersect {5} && binsof(ofset_down_cover) intersect {0};
            bins up_6_down_0 = binsof(ofset_up_cover) intersect {6} && binsof(ofset_down_cover) intersect {0};
            bins up_7_down_0 = binsof(ofset_up_cover) intersect {7} && binsof(ofset_down_cover) intersect {0};
            bins up_8_down_0 = binsof(ofset_up_cover) intersect {8} && binsof(ofset_down_cover) intersect {0};
            bins up_9_down_0 = binsof(ofset_up_cover) intersect {9} && binsof(ofset_down_cover) intersect {0};
            bins up_10_down_0 = binsof(ofset_up_cover) intersect {10} && binsof(ofset_down_cover) intersect {0};

            bins up_5_down_5 = binsof(ofset_up_cover) intersect {5} && binsof(ofset_down_cover) intersect {5};
            bins up_6_down_6 = binsof(ofset_up_cover) intersect {6} && binsof(ofset_down_cover) intersect {6};
            bins up_7_down_7 = binsof(ofset_up_cover) intersect {7} && binsof(ofset_down_cover) intersect {7};
            bins up_8_down_8 = binsof(ofset_up_cover) intersect {8} && binsof(ofset_down_cover) intersect {8};
            bins up_9_down_9 = binsof(ofset_up_cover) intersect {9} && binsof(ofset_down_cover) intersect {9};
            bins up_10_down_10 = binsof(ofset_up_cover) intersect {10} && binsof(ofset_down_cover) intersect {10};

            illegal_bins ibup5  = binsof(ofset_up_cover) intersect {5} && binsof(ofset_down_cover) intersect {6, 7, 8, 9, 10};
            illegal_bins ibup6  = binsof(ofset_up_cover) intersect {6} && binsof(ofset_down_cover) intersect {5, 7, 8, 9, 10};
            illegal_bins ibup7  = binsof(ofset_up_cover) intersect {7} && binsof(ofset_down_cover) intersect {5, 6, 8, 9, 10};
            illegal_bins ibup8  = binsof(ofset_up_cover) intersect {8} && binsof(ofset_down_cover) intersect {5, 6, 7, 9, 10};
            illegal_bins ibup9  = binsof(ofset_up_cover) intersect {9} && binsof(ofset_down_cover) intersect {5, 6, 7, 8, 10};
            illegal_bins ibup10  = binsof(ofset_up_cover) intersect {10} && binsof(ofset_down_cover) intersect {5, 6, 7, 8, 9};

            illegal_bins ibdown5  = binsof(ofset_up_cover) intersect {6, 7, 8, 9, 10} && binsof(ofset_down_cover) intersect {5};
            illegal_bins ibdown6  = binsof(ofset_up_cover) intersect {5, 7, 8, 9, 10} && binsof(ofset_down_cover) intersect {6};
            illegal_bins ibdown7  = binsof(ofset_up_cover) intersect {5, 6, 8, 9, 10} && binsof(ofset_down_cover) intersect {7};
            illegal_bins ibdown8  = binsof(ofset_up_cover) intersect {5, 6, 7, 9, 10} && binsof(ofset_down_cover) intersect {8};
            illegal_bins ibdown9  = binsof(ofset_up_cover) intersect {5, 6, 7, 8, 10} && binsof(ofset_down_cover) intersect {9};
            illegal_bins ibdown10  = binsof(ofset_up_cover) intersect {5, 6, 7, 8, 9} && binsof(ofset_down_cover) intersect {10};

        }
    endgroup   

   	covergroup img_cover_ipo();   
        option.per_instance = 1;
        ipo_num_cover : coverpoint rand_img_per_octave {
            bins ipo0 = {0};
            bins ipo1 = {1};
            bins ipo2 = {2}; 
            bins ipo3 = {3};
            bins ipo4 = {4};
            bins ipo5 = {5};
        }
    endgroup

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
    constraint rand_off_or_0_constr2 {(off_or_0 == 1) -> rand_img_per_octave == 0;}
    //constraint rand_off_or_0_constr3 {(rand_img_per_octave != 0) -> (off_or_0 == 0);} 
    //constraint rand_off_or_0_constr4 {(rand_img_per_octave == 0) -> (off_or_0 == 1);} 
    constraint rand_off_or_1_constr1 {off_or_1 >= 0; off_or_1 < 2;}
    constraint rand_off_or_1_constr2 {(off_or_1 == 1) -> rand_img_per_octave == 0;} 
    //constraint rand_off_or_1_constr3 {(rand_img_per_octave != 0) -> (off_or_1 == 0);} 
    //constraint rand_off_or_1_constr4 {(rand_img_per_octave == 0) -> (off_or_1 == 1);} 

     function new(string name = "gaussian_blur_config_rand");
        super.new(name);
        img_cover_offsets = new();
        img_cover_ipo = new();
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
        img_cover_offsets.sample();
        img_cover_ipo.sample();
        
    endfunction : random_configuration           
    //------------------------------------------------------------------------------------
        
endclass : gaussian_blur_config_rand       
