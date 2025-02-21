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

parameter NUMBER_OF_IMAGES = 3;
parameter NUMBER_OF_OCTAVES = 1;
parameter NUMBER_OF_IMGS_PER_OCTAVE = 1;
parameter NUMBER_OF_IMAGE_PARTS = 5;

import uvm_pkg::*;
`include "uvm_macros.svh"

class gaussian_blur_config extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    rand int rand_img;
    rand int rand_oct;
    rand int rand_ipo;
    rand int rand_part;
    
    int i = 0;
    int j = 0;
    int k = 0;
    int l = 0;
    string num1, num2, num3;
    
    int img_width;
    int img_height;
    int img_offset_up;
    int img_offset_down;
    int num_img_per_oct;
    
    int read_bram = 0;
    int tmp;
    int tmp1;
    int tmp2;
    
    //FILES
    string img_dimensions_file[NUMBER_OF_IMAGES * NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE * NUMBER_OF_IMAGE_PARTS];
    string main_bram_gv_file[NUMBER_OF_IMAGES * NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE * NUMBER_OF_IMAGE_PARTS];
    string main_bram_load_file[NUMBER_OF_IMAGES * NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE * NUMBER_OF_IMAGE_PARTS];
    string main_bram_read_file[NUMBER_OF_IMAGES * NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE * NUMBER_OF_IMAGE_PARTS];
    //string tmp_bram_read_file[NUMBER_OF_IMAGES * NUM_OF_OCTAVES * NUMBER_OF_SCALES_PER_OCTAVE * NUMBER_OF_IMAGE_PARTS];
    //--------------------------------------------------------------------------------------------------------------------
    
    int fd;
    
    int main_bram_gv_arr[$];
    int main_bram_rdata_arr[$];
    int main_bram_wdata_arr[$];    
    //int tmp_bram_rdata[$];
    
    `uvm_object_utils_begin(gaussian_blur_config)
        `uvm_field_enum(uvm_active_passive_enum,is_active,UVM_DEFAULT)
    `uvm_object_utils_end
    
    covergroup img_cover_img();
        option.per_instance = 1;
        img_num_cover : coverpoint rand_img {
            bins img0 = {0};
            bins img1 = {1};
            bins img2 = {2}; 
        }
    endgroup
    
    covergroup img_cover_ipart();
        option.per_instance = 1;
        part_num_cover : coverpoint rand_part {
            bins part0 = {0};
            bins part1 = {1};
            bins part2 = {2}; 
            bins part3 = {3};
            bins part4 = {4};
        }
    endgroup
    
    covergroup img_cover_oct();   
        option.per_instance = 1;
        oct_num_cover : coverpoint rand_oct {
            bins oct0 = {0};
            bins oct1 = {1};
            bins oct2 = {2}; 
            bins oct3 = {3};
        }
    endgroup    
        
    covergroup img_cover_ipo();  
        option.per_instance = 1;
        ipo_num_cover : coverpoint rand_ipo {
            bins ipo0 = {0};
            bins ipo1 = {1};
            bins ipo2 = {2}; 
            bins ipo3 = {3};
            bins ipo4 = {4};
            bins ipo5 = {5};
       }   
    endgroup
    
     constraint rand_constr_img {rand_img >= 0 ; rand_img < NUMBER_OF_IMAGES;}; 
     constraint rand_constr_oct {rand_oct >= 0 ; rand_oct < NUMBER_OF_OCTAVES;}; 
     constraint rand_constr_ipo1 {rand_ipo >= 0 ; rand_ipo < NUMBER_OF_IMGS_PER_OCTAVE;}; 
     constraint rand_constr_ipo2 {(rand_ipo == 0)-> (rand_oct == 0);};
     constraint rand_constr_ipart {rand_part >= 0 ; rand_part < NUMBER_OF_IMAGE_PARTS;}; 
        
     
     function new(string name = "gaussian_blur_config");
        super.new(name);
        img_cover_img = new(); 
        img_cover_ipart = new();
        img_cover_oct = new();
        img_cover_ipo = new(); 
                   
        for (i = 0; i < NUMBER_OF_IMAGES; i++)
        begin
            for (j = 0; j < NUMBER_OF_IMAGE_PARTS; j++)
            begin
                num1.itoa(i);
                num2.itoa(j);
                num3.itoa(0);
                img_dimensions_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE)] = {"../../../../../img_dimensions/dim_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"};
                main_bram_load_file[(i*NUMBER_OF_IMAGE_PARTS + j) * NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE] = {"../../../../../image_files/img_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"};
                main_bram_gv_file[(i*NUMBER_OF_IMAGE_PARTS + j) * NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE] = {"../../../../../golden_vectors/gv_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"};
                main_bram_read_file[(i*NUMBER_OF_IMAGE_PARTS + j) * NUMBER_OF_OCTAVES * NUMBER_OF_IMGS_PER_OCTAVE] = {"../../../../../result_files/res_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"};
                
                for (k = 0; k < NUMBER_OF_OCTAVES; k++)
                begin
                    for (l = 1; l < NUMBER_OF_IMGS_PER_OCTAVE; l++)
                    begin
                        num3.itoa(k * NUMBER_OF_IMGS_PER_OCTAVE + l);
                        img_dimensions_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k) * NUMBER_OF_IMGS_PER_OCTAVE + l] = {"../../../../../img_dimensions/dim_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"};
                        main_bram_load_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k) * NUMBER_OF_IMGS_PER_OCTAVE + l] = {"../../../../../image_files/img_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"};
                        main_bram_gv_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k) * NUMBER_OF_IMGS_PER_OCTAVE + l] = {"../../../../../golden_vectors/gv_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"}; 
                        main_bram_read_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k) * NUMBER_OF_IMGS_PER_OCTAVE + l] = {"../../../../../result_files/res_file_img_", num1, "_ipart_", num2, "_", num3, ".txt"};                    
                    end
                    
                end
            end 
        end           
        
     endfunction
     
     function random_configuration;
        $display("Random image num : %d", rand_img);
        $display("Random image part num : %d", rand_part);
        $display("Random octave num : %d", rand_oct);
        $display("Random scale per octave num : %d", rand_ipo);
        
        //COLLECT COVERAGE
        img_cover_img.sample();
        img_cover_ipart.sample();
        img_cover_oct.sample();
        img_cover_ipo.sample();
        
        //IMAGE DIMENSIONS LOADING
        fd = $fopen(img_dimensions_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct) * NUMBER_OF_IMGS_PER_OCTAVE + rand_ipo], "r");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened img_dimensons_file"),UVM_HIGH)
             
             $fscanf(fd, "%d\n", img_width);
             $display("Image width : %d", img_width);
             $fscanf(fd, "%d\n", img_height);
             $display("Image height : %d", img_height);
             $fscanf(fd, "%d\n", img_offset_up);
             $display("Image offset up : %d", img_offset_up);
             $fscanf(fd, "%d\n", img_offset_down);
             $display("Image offset down: %d", img_offset_down);
             num_img_per_oct = rand_ipo;             
             $display("Image number image per octave: %d", num_img_per_oct);       
        end
        else
            `uvm_info(get_name(), $sformatf("Error opening img_dimensons_file"),UVM_HIGH)        
        $fclose(fd);
        //------------------------------------------------------------------------------------
        
        // GOLDEN VECTORS LOADING
        fd = $fopen(main_bram_gv_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct) * NUMBER_OF_IMGS_PER_OCTAVE + rand_ipo], "r");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_gv_file"),UVM_HIGH)
            
            while(!$feof(fd)) begin
                $fscanf(fd, "%d\t%d\n", tmp1, tmp2);
                tmp =  (tmp1 << 16) | tmp2;
                main_bram_gv_arr.push_back(tmp);
            end
        end
        else
            `uvm_info(get_name(), $sformatf("Error opening main_bram_gv_file"),UVM_HIGH)        
        $fclose(fd);    
        //----------------------------------------------------------------------------------------
       
        //LOADING IMAGE IN BRAM
        fd = $fopen(main_bram_load_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct) * NUMBER_OF_IMGS_PER_OCTAVE + rand_ipo], "r");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_load_file"),UVM_HIGH)
            
            while(!$feof(fd)) begin
                $fscanf(fd, "%d\t%d\n", tmp1, tmp2);
                tmp =  (tmp1 << 16) | tmp2;
                //$display("Tmp value = %d", tmp);
                main_bram_wdata_arr.push_back(tmp);
            end
        end
        else
            `uvm_info(get_name(), $sformatf("Error opening main_bram_load_file"),UVM_HIGH)        
        $fclose(fd);
        //------------------------------------------------------------------------------------------
        
        //MAIN BRAM READING
        
        fd = $fopen(main_bram_read_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct) * NUMBER_OF_IMGS_PER_OCTAVE + rand_ipo], "w+");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_read_file"),UVM_HIGH)
            
           /* while(!$feof(fd)) begin
                $fscanf(fd, "%d\t%d\n", tmp1, tmp2);
                tmp = {tmp1, tmp2};
                main_bram_rdata_arr.push_back(tmp);
            end */
            while ((main_bram_rdata_arr.size == img_width * img_height/2 || read_bram == 1) && main_bram_rdata_arr.size() > 0) begin
                tmp = main_bram_rdata_arr.pop_front();
                tmp1 = (tmp >> 16) & 16'hffff;
                tmp2 = tmp & 16'hffff;
                $fdisplay(fd, "%d\t%d\n", tmp1, tmp2);
                read_bram = 1;
           end 
        end
        else
            `uvm_info(get_name(), $sformatf("Error opening main_bram_read_file"),UVM_HIGH)        
        $fclose(fd);
        
       /* fd = $fopen(main_bram_read_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct) * NUMBER_OF_IMGS_PER_OCTAVE + rand_ipo], "r");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_read_file"),UVM_HIGH)
            
            while(!$feof(fd)) begin
                $fscanf(fd, "%d\t%d\n", tmp1, tmp2);
                tmp = {tmp1, tmp2};
                main_bram_rdata_arr.push_back(tmp);
            end
        end
        else
            `uvm_info(get_name(), $sformatf("Error opening main_bram_read_file"),UVM_HIGH)        
        $fclose(fd);
        */
      //$display("Queues size -> main_bram_wdata_arr=%d, main_bram_gv_arr=%d", main_bram_wdata_arr.size(), main_bram_gv_arr.size());    
     endfunction : random_configuration
     
        
endclass : gaussian_blur_config
