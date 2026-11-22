
`ifndef GAUSSIAN_BLUR_BASE_SEQ_SV
`define GAUSSIAN_BLUR_BASE_SEQ_SV

   parameter AXI_BASE = 5'b00000;  
   parameter IMG_WIDTH_REG_OFFSET = 5'b00000; 
   parameter IMG_HEIGHT_REG_OFFSET = 5'b00100;
   parameter IMG_OFFSET_UP_REG_OFFSET = 5'b01000; 
   parameter IMG_OFFSET_DOWN_REG_OFFSET = 5'b01100;
   parameter NUM_IMG_OCT_REG_OFFSET = 5'b10000;
   parameter START_REG_OFFSET = 5'b11000;
   parameter RESET_REG_OFFSET = 5'b10100;
   parameter READY_REG_OFFSET = 5'b11100;

class gaussian_blur_base_seq extends uvm_sequence#(gaussian_blur_seq_item);

   `uvm_object_utils(gaussian_blur_base_seq)
   `uvm_declare_p_sequencer(gaussian_blur_sequencer)
   gaussian_blur_seq_item req_item;

   function new(string name = "gaussian_blur_base_seq");
      super.new(name);
   endfunction

   // objections are raised in pre_body
   virtual task pre_body();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.raise_objection(this, {"Running sequence '", get_full_name(), "'"});
   endtask : pre_body

   // objections are dropped in post_body
   virtual task post_body();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.drop_objection(this, {"Completed sequence '", get_full_name(), "'"});
   endtask : post_body

endclass : gaussian_blur_base_seq

class gaussian_blur_seq extends gaussian_blur_base_seq;

   `uvm_object_utils(gaussian_blur_seq)
   `uvm_declare_p_sequencer(gaussian_blur_sequencer)

   function new(string name = "gaussian_blur_seq");
      super.new(name);
   endfunction

  virtual task body();
      req_item = gaussian_blur_seq_item::type_id::create("req_item");
      if (req_item == null) begin
         `uvm_fatal("REQ_ITEM_NULL", "Req_item is null!")
      end
      $display("\nStarting AXI initialization...\n");
      program_regs(RESET_REG_OFFSET, 32'd1);
      $display("\nAXI initialization finished!\n");
      $display("\nLoading image part begins...\n");
      load_image_part();
      $display("\nImage part loaded!\n");
      $display("\nSetting image parameters...\n\n");
      program_regs(IMG_WIDTH_REG_OFFSET, p_sequencer.cfg.img_width);
      program_regs(IMG_HEIGHT_REG_OFFSET, p_sequencer.cfg.img_height);
      program_regs(IMG_OFFSET_UP_REG_OFFSET, p_sequencer.cfg.img_offset_up);
      program_regs(IMG_OFFSET_DOWN_REG_OFFSET, p_sequencer.cfg.img_offset_down);
      program_regs(NUM_IMG_OCT_REG_OFFSET, p_sequencer.cfg.num_img_per_oct);
      $display("\nImage parameters set!\n");
      $display("\nStarting gaussian blur...\n");
      program_regs(START_REG_OFFSET, 32'd1);
      $display("\nGaussian blur started!\n");
      $display("\nReading results from bram\n");
      read_back();
      $display("\nFinished reading results from bram\n");
   endtask : body

   virtual task program_regs(logic [4:0] addr, logic [31:0] data);
      `uvm_do_with(req_item, {
         req_item.bram_axi_ctrl == 1; 
         req_item.s00_axi_awaddr == AXI_BASE+addr; 
         req_item.s00_axi_wdata == data;
      });
      //`uvm_fatal("AXI_WRITE_FAILED", $sformatf("AXI write for register %0h failed with data %0h", addr, data));
   endtask : program_regs

   virtual task load_image_part();
      for (int i = 0 ; i < p_sequencer.cfg.img_width*p_sequencer.cfg.img_height/2 ; i++)
         begin
            `uvm_do_with(req_item,{   
               req_item.bram_axi_ctrl == 0;    
               req_item.main_bram_a_en_i == 1'b1;    
               req_item.main_bram_a_we_i == 4'b1111;    
               req_item.main_bram_a_addr_i == i*4; 
               req_item.main_bram_a_wdata_i == p_sequencer.cfg.main_bram_wdata_arr[i];
            });                    
         end
         `uvm_do_with(req_item,{   
            req_item.bram_axi_ctrl == 0;    
            req_item.main_bram_a_en_i == 1'b0;    
            req_item.main_bram_a_we_i == 4'b0000;    
            req_item.main_bram_a_addr_i == 17'd0; 
            req_item.main_bram_a_wdata_i == 32'd0;
         });  
      //`uvm_fatal("LOAD_IMAGE_PART_NOT_IMPLEMENTED", "load_image_part() must be implemented in derived classes");
   endtask : load_image_part

   virtual task read_back();
      for (int i = 0 ; i < p_sequencer.cfg.img_width*(p_sequencer.cfg.img_height - p_sequencer.cfg.img_offset_up - p_sequencer.cfg.img_offset_down)/2 + 1 ; i++)
         begin
            `uvm_do_with(req_item,{   
               req_item.bram_axi_ctrl == 0;    
               req_item.main_bram_a_en_i == 1'b1;    
               req_item.main_bram_a_we_i == 4'b0000;    
               req_item.main_bram_a_addr_i == i*4; 
            });                    
         end
         `uvm_do_with(req_item,{   
            req_item.bram_axi_ctrl == 0;    
            req_item.main_bram_a_en_i == 1'b0;    
            req_item.main_bram_a_we_i == 4'b0000;    
            req_item.main_bram_a_addr_i == 17'd0; 
            req_item.main_bram_a_wdata_i == 32'd0;
         });  
      //`uvm_fatal("READ_BACK_NOT_IMPLEMENTED", "read_back() must be implemented in derived classes");
   endtask : read_back

endclass : gaussian_blur_seq

`endif

