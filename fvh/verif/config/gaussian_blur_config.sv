
parameter NUMBER_OF_IMAGES = 11;
parameter NUMBER_OF_IMAGE_PARTS = 4;
parameter NUMBER_OF_OCTAVES = 5;
parameter NUMBER_OF_IMAGES_PER_OCTAVE = 6;

import uvm_pkg::*;
`include "uvm_macros.svh"

class gaussian_blur_config extends uvm_object;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    rand int rand_img;
    rand int rand_oct;
    rand int rand_part;
    rand int rand_ipo;

    int i = 0;
    int j = 0;
    int k = 0;
    string num1, num2, num3;
    
    int img_width;
    int img_height;
    int img_offset_up;
    int img_offset_down;
    int num_img_per_oct;
    
    int tmp;
    int tmp1;
    int tmp2;
    int num_of_zeros = 0;
    
    //FILES
    string ipo_str[2] = {"_0", "_1-5"};
    string image_names[NUMBER_OF_IMAGES] = {"bird", "eagle", "mountain1", "mountain2", "mushroom", "palma", "parrot", "sandals", "seashore", "shark", "squirrel"};
    string img_dimensions_file[NUMBER_OF_IMAGES * NUMBER_OF_IMAGE_PARTS * NUMBER_OF_OCTAVES ];
    //string main_bram_gv_file[NUMBER_OF_IMAGES * NUMBER_OF_IMAGE_PARTS * NUMBER_OF_OCTAVES ];
    string main_bram_load_file[NUMBER_OF_IMAGES * NUMBER_OF_IMAGE_PARTS * NUMBER_OF_OCTAVES ];
    string main_bram_read_file[NUMBER_OF_IMAGES * NUMBER_OF_IMAGE_PARTS * NUMBER_OF_OCTAVES ];
    //--------------------------------------------------------------------------------------------------------------------
    
    int fd;
    
    //int main_bram_gv_arr[$];
    int main_bram_wdata_arr[$];
    int ref_in_data_arr[$];  
    int ref_out_data_arr[$];  
    
    `uvm_object_utils_begin(gaussian_blur_config)
        `uvm_field_enum(uvm_active_passive_enum,is_active,UVM_DEFAULT)
    `uvm_object_utils_end
    
    covergroup img_cover_img();
        option.per_instance = 1;
        img_num_cover : coverpoint rand_img {
            bins img0 = {0};
            bins img1 = {1};
            bins img2 = {2}; 
            bins img3 = {3}; 
            bins img4 = {4}; 
            bins img5 = {5}; 
            bins img6 = {6}; 
            bins img7 = {7}; 
            bins img8 = {8}; 
            bins img9 = {9};
            bins img10 = {10};  
        }
    endgroup
    
    covergroup img_cover_ipart();
        option.per_instance = 1;
        part_num_cover : coverpoint rand_part {
            bins part0 = {0};
            bins part1 = {1};
            bins part2 = {2}; 
            bins part3 = {3};
        }
    endgroup
    
    covergroup img_cover_oct();   
        option.per_instance = 1;
        oct_num_cover : coverpoint rand_oct {
            bins oct0 = {0};
            bins oct1 = {1};
            bins oct2 = {2}; 
            bins oct3 = {3};
            bins oct4 = {4};
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

     constraint rand_constr_img {rand_img >= 0 ; rand_img < NUMBER_OF_IMAGES;}
     constraint rand_constr_oct1 {rand_oct >=0 ; rand_oct < NUMBER_OF_OCTAVES;} 
     constraint rand_constr_oct2 {rand_oct dist {0:/ 20, [1:4]:/ 30} ; } 
     constraint rand_constr_ipart {rand_part >= 0 ; rand_part < NUMBER_OF_IMAGE_PARTS;}
     constraint rand_constr_ipo1 {rand_ipo >= 0 ; rand_ipo < NUMBER_OF_IMAGES_PER_OCTAVE;} 
     constraint rand_constr_ipo2 {(rand_oct == 0) -> (rand_ipo == 0);}
     constraint rand_constr_ipo3 {(rand_oct != 0) -> (rand_ipo != 0);}

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
                num1 = ipo_str[0];
                num2.itoa(j);
                num3.itoa(0);
                img_dimensions_file[(i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES ] = {"../../../../../img_dimensions/dim_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"};
                main_bram_load_file[(i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES ] = {"../../../../../image_files/data_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"};
                //main_bram_gv_file[(i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES ] = {"../../../../../golden_vectors/gv_file_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"};
                main_bram_read_file[(i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES ] = {"../../../../../result_files/res_file_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"};
                
                for (k = 0; k < NUMBER_OF_OCTAVES - 1; k++)
                begin
                    num1 = ipo_str[1];
                    num3.itoa(k);
                    img_dimensions_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k + 1) ] = {"../../../../../img_dimensions/dim_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"};
                    main_bram_load_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k + 1) ] = {"../../../../../image_files/data_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"};
                    //main_bram_gv_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k + 1) ] = {"../../../../../golden_vectors/gv_file_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"}; 
                    main_bram_read_file[((i*NUMBER_OF_IMAGE_PARTS + j) *NUMBER_OF_OCTAVES + k + 1) ] = {"../../../../../result_files/res_file_img_", image_names[i], "_ipart_", num2, "_oct_", num3, "_ipo", num1, ".txt"};                    
                    
                end
            end 
        end           
        
     endfunction
     
     function random_configuration;
        $display("Random image : %s", image_names[rand_img]);
        $display("Random image part num : %0d", rand_part);
        $display("Random octave num : %0d", rand_oct);
        $display("Random scale per octave num : %0d", rand_ipo);
        
        //COLLECT COVERAGE
        img_cover_img.sample();
        img_cover_ipart.sample();
        img_cover_oct.sample();
        img_cover_ipo.sample();

        //IMAGE DIMENSIONS LOADING4
        fd = $fopen(img_dimensions_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct)], "r");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened img_dimensons_file"),UVM_HIGH)
             
             $fscanf(fd, "%0d", img_width);
             if (img_width <= 0) begin
                 `uvm_fatal(get_name(), $sformatf("Error: Image width is not valid!"))
             end
             $display("Image width : %0d", img_width);
             $fscanf(fd, "%d\n", img_height);
                if (img_height <= 0) begin
                    `uvm_fatal(get_name(), $sformatf("Error: Image height is not valid!"));
                end
             $display("Image height : %0d", img_height);
             $fscanf(fd, "%d\n", img_offset_up);

             $display("Image offset up : %0d", img_offset_up);
             $fscanf(fd, "%d\n", img_offset_down);
             $display("Image offset down: %0d", img_offset_down);
             num_img_per_oct = rand_ipo;             
             $display("Image number image per octave: %0d", num_img_per_oct);       
        end
        else
            `uvm_fatal(get_name(), $sformatf("Error opening img_dimensons_file"))        
        $fclose(fd);
        //------------------------------------------------------------------------------------
       
        //LOADING IMAGE IN BRAM
        fd = $fopen(main_bram_load_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct)], "r");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_load_file"),UVM_HIGH)
            
            while(!$feof(fd)) begin
                $fscanf(fd, "%0d\t%0d", tmp1, tmp2);
                ref_in_data_arr.push_back(tmp1);
                ref_in_data_arr.push_back(tmp2);   
                if (tmp1 == 0 || tmp2 == 0) begin
                    num_of_zeros++;
                end 
                if (num_of_zeros > 2) begin
                    `uvm_fatal(get_name(), $sformatf("Error: Too many zeros in image part!Image %s, part %0d, octave %0d, scale per octave %s", image_names[rand_img], rand_part, rand_oct, ipo_str[rand_ipo]))
                end            
                tmp =  (tmp1 << 16) | tmp2;
                
                main_bram_wdata_arr.push_back(tmp);
            end
        end
        else
            `uvm_fatal(get_name(), $sformatf("Error opening main_bram_load_file"))        
        $fclose(fd);
        //------------------------------------------------------------------------------------------

         /*
        // GOLDEN VECTORS LOADING
        fd = $fopen(main_bram_gv_file[((rand_img*NUMBER_OF_IMAGE_PARTS + rand_part) *NUMBER_OF_OCTAVES + rand_oct)], "r");
        
        if (fd) begin
            `uvm_info(get_name(), $sformatf("Successfully opened main_bram_gv_file"),UVM_HIGH)
            
            while(!$feof(fd)) begin
                $fscanf(fd, "%0d\t%0d", tmp1, tmp2);
                main_bram_gv_arr.push_back(tmp1);
                main_bram_gv_arr.push_back(tmp2);
            end
        end
        else
            `uvm_info(get_name(), $sformatf("Error opening main_bram_gv_file"),UVM_HIGH)        
        $fclose(fd);    
        //----------------------------------------------------------------------------------------
       */
       
     endfunction : random_configuration
     
        
endclass : gaussian_blur_config
