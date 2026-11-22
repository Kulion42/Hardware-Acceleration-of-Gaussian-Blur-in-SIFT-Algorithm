
parameter NUMBER_OF_IMAGES = 11;
parameter NUMBER_OF_IMAGE_PARTS = 4;
parameter NUMBER_OF_OCTAVES = 5;
parameter NUMBER_OF_IMAGES_PER_OCTAVE = 6;

parameter MAX_WIDTH = 300;
parameter MAX_HEIGHT = 200;
parameter MIN_WIDTH = 64;
parameter MIN_HEIGHT = 32;

parameter MIN_PIX = 100;
parameter MAX_PIX = 32767;  

import uvm_pkg::*;
`include "uvm_macros.svh"

class gaussian_blur_config extends uvm_object;
    `uvm_object_utils(gaussian_blur_config)      

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    int img_width;
    int img_height;
    int img_offset_up;
    int img_offset_down;
    int num_img_per_oct;

    bit checks_enable = 1;
    int pixel_tol    = 1;

    int main_bram_wdata_arr[$];
    int ref_in_data_arr[$];  
    int ref_out_data_arr[$]; 

    string result_dir     = "../../../../../result_files";
    string log_file;
    string tag;                                      

    function new(string name = "gaussian_blur_config");
        super.new(name);
    endfunction

    virtual function void random_configuration();
        `uvm_fatal("CFG", "use gaussian_blur_config_file or gaussian_blur_config_rand")
    endfunction

endclass : gaussian_blur_config

class gaussian_blur_config_file extends gaussian_blur_config;
    `uvm_object_utils(gaussian_blur_config_file) 

    rand int rand_img;
    rand int rand_oct;
    rand int rand_part;
    rand int rand_ipo;

    int i = 0;
    int j = 0;
    int k = 0;
    string num1, num2, num3;
    
    int tmp;
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

    int pix_up, pix_down;
    
    covergroup img_data_cover();
        option.per_instance = 1;
        img_up_pix_value : coverpoint pix_up{
            bins group_up_1 = {[1:4096]};
            bins group_up_2 = {[4097:6144]};
            bins group_up_3 = {[6145:8192]};
            bins group_up_4 = {[8193:10240]};
            bins group_up_5 = {[10241:12288]};
            bins group_up_6 = {[12289:14336]};
            bins group_up_7 = {[14337:15360]};
            bins group_up_8 = {[15361:16384]};
            bins group_up_9 = {[16385:20480]};
            bins group_up_10 = {[20481:24576]};
            bins group_up_11 = {[24577:28672]};
            bins group_up_12 = {[28673:32767]};
            illegal_bins illegal_vals_up = {[32768:65536]};
        }
        
        img_down_pix_value : coverpoint pix_down{
            bins group_down_1 = {[1:4096]};
            bins group_down_2 = {[4097:6144]};
            bins group_down_3 = {[6145:8192]};
            bins group_down_4 = {[8193:10240]};
            bins group_down_5 = {[10241:12288]};
            bins group_down_6 = {[12289:14336]};
            bins group_down_7 = {[14337:15360]};
            bins group_down_8 = {[15361:16384]};
            bins group_down_9 = {[16385:20480]};
            bins group_down_10 = {[20481:24576]};
            bins group_down_11 = {[24577:28672]};
            bins group_down_12 = {[28673:32767]};
            illegal_bins illegal_vals_down = {[32768:65536]};
        }
    endgroup
    
    covergroup data_parity_cover();
        option.per_instance = 1;
        pix_up_parity : coverpoint pix_up%2{
            bins pix_up_odd = {1};
            bins pix_up_even = {0};
        }
        
        pix_down_parity : coverpoint pix_down%2{
            bins pix_down_odd = {1};
            bins pix_down_even = {0};
        }
    endgroup

    constraint rand_constr_img {rand_img >= 0 ; rand_img < NUMBER_OF_IMAGES;}
    constraint rand_constr_oct1 {rand_oct >=0 ; rand_oct < NUMBER_OF_OCTAVES;} 
    constraint rand_constr_oct2 {rand_oct dist {0:/ 20, [1:4]:/ 30} ; } 
    constraint rand_constr_ipart {rand_part >= 0 ; rand_part < NUMBER_OF_IMAGE_PARTS;}
    constraint rand_constr_ipo1 {rand_ipo >= 0 ; rand_ipo < NUMBER_OF_IMAGES_PER_OCTAVE;} 
    constraint rand_constr_ipo2 {(rand_oct == 0) -> (rand_ipo == 0);}
    constraint rand_constr_ipo3 {(rand_oct != 0) -> (rand_ipo != 0);}

    function new(string name = "gaussian_blur_config_file");
        super.new(name);
        img_cover_img = new(); 
        img_cover_ipart = new();
        img_cover_oct = new();   
        img_cover_ipo = new(); 
        img_data_cover = new();
        data_parity_cover = new();

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
    int str ;
    virtual function void random_configuration();
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
                $fscanf(fd, "%0d\t%0d", pix_up, pix_down);
                ref_in_data_arr.push_back(pix_up);
                ref_in_data_arr.push_back(pix_down);   
                if (pix_up == 0 || pix_down == 0) begin
                    num_of_zeros++;
                end 
                if (num_of_zeros > 2) begin
                    `uvm_fatal(get_name(), $sformatf("Error: Too many zeros in image part!Image %s, part %0d, octave %0d, scale per octave %s", image_names[rand_img], rand_part, rand_oct, ipo_str[rand_ipo]))
                end            
                tmp =  (pix_up << 16) | pix_down;
                
                main_bram_wdata_arr.push_back(tmp);
                img_data_cover.sample();
                data_parity_cover.sample();
            end
        end
        else
            `uvm_fatal(get_name(), $sformatf("Error opening main_bram_load_file"))        
        $fclose(fd);
        //------------------------------------------------------------------------------------------
        str = (rand_ipo == 0) ? 0 : 1;
        tag = $sformatf("img_%s_ipart_%0d_oct_%0d_ipo%s.txt", image_names[rand_img], rand_part,
                        (rand_ipo == 0) ? rand_oct : rand_oct - 1, ipo_str[str]);
        log_file = "../../../../../regression_file_log.txt"; 

     endfunction : random_configuration
     
        
endclass : gaussian_blur_config_file


class gaussian_blur_config_rand extends gaussian_blur_config;
    `uvm_object_utils(gaussian_blur_config_rand) 

    rand int rand_width;
    rand int rand_height;
    rand int rand_offset_up;
    rand int rand_offset_down;
    rand int rand_img_per_octave;
    rand int offset_p;
    rand int off_or_0;
    rand int off_or_1;
    //--------------------------------------------------------------------------------------------------------------------
    
    int offsets_arr[6] = {5, 6, 7, 8, 9, 10};
    int pix_up, pix_down;


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

        covergroup img_data_cover();
        option.per_instance = 1;
        img_up_pix_value : coverpoint pix_up{
            bins group_up_1  = {[0:4096]};
            bins group_up_2  = {[4097:6144]};
            bins group_up_3  = {[6145:8192]};
            bins group_up_4  = {[8193:10240]};
            bins group_up_5  = {[10241:12288]};
            bins group_up_6  = {[12289:14336]};
            bins group_up_7  = {[14337:15360]};
            bins group_up_8  = {[15361:16384]};
            bins group_up_9  = {[16385:20480]};
            bins group_up_10 = {[20481:24576]};
            bins group_up_11 = {[24577:28672]};
            bins group_up_12 = {[28673:32767]};
            illegal_bins illegal_vals_up = {[32768:65536]};
        }
        
        img_down_pix_value : coverpoint pix_down{
            bins group_down_1 = {[0:4096]};
            bins group_down_2 = {[4097:6144]};
            bins group_down_3 = {[6145:8192]};
            bins group_down_4 = {[8193:10240]};
            bins group_down_5 = {[10241:12288]};
            bins group_down_6 = {[12289:14336]};
            bins group_down_7 = {[14337:15360]};
            bins group_down_8 = {[15361:16384]};
            bins group_down_9   = {[16385:20480]};
            bins group_down_10  = {[20481:24576]};
            bins group_down_11  = {[24577:28672]};
            bins group_down_12  = {[28673:32767]};
            illegal_bins illegal_vals_down= {[32768:65536]};
        }
    endgroup
    
    covergroup data_parity_cover();
        option.per_instance = 1;
        pix_up_parity : coverpoint pix_up%2{
            bins pix_up_odd = {1};
            bins pix_up_even = {0};
        }
        
        pix_down_parity : coverpoint pix_down%2{
            bins pix_down_odd = {1};
            bins pix_down_even = {0};
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
    constraint rand_constr_ipo1 {rand_img_per_octave >= 0 ; rand_img_per_octave < NUMBER_OF_IMAGES_PER_OCTAVE;}
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
        img_data_cover = new();
        data_parity_cover = new();
    endfunction
        
    virtual function void random_configuration();        
        //COLLECT COVERAGE
             
        $display("Image width : %0d", rand_width);
        img_width = rand_width;
        $display("Image height : %0d", rand_height);
        img_height = rand_height;
        $display("Image number image per octave: %0d", rand_img_per_octave);  
        num_img_per_oct = rand_img_per_octave;

        rand_offset_up   = off_or_0 ? offsets_arr[offset_p] : 0;
        rand_offset_down = off_or_1 ? offsets_arr[offset_p] : 0;
        $display("Image offset up : %0d", rand_offset_up);
        $display("Image offset down: %0d", rand_offset_down);
        img_offset_up = rand_offset_up;
        img_offset_down = rand_offset_down;

        for (int i = 0; i < img_width*img_height/2; i++) begin
            pix_up   = $urandom_range(MIN_PIX, MAX_PIX);
            pix_down = $urandom_range(MIN_PIX, MAX_PIX);
            ref_in_data_arr.push_back(pix_up);
            ref_in_data_arr.push_back(pix_down);
            main_bram_wdata_arr.push_back((pix_up << 16) | pix_down);
            img_data_cover.sample();
            data_parity_cover.sample();
        end
        tag = $sformatf("img_width_%0d_height_%0d_offset_up_%0d_offset_down_%0d",
                  img_width, img_height, img_offset_up, img_offset_down);
        log_file = "../../../../../regression_rand_log.txt"; 

        img_cover_offsets.sample();
        img_cover_ipo.sample();
        
    endfunction : random_configuration           
    //------------------------------------------------------------------------------------
        
endclass : gaussian_blur_config_rand       
