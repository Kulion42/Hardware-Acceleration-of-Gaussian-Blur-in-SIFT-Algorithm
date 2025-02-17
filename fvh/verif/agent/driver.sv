`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 10:34:50 AM
// Design Name: 
// Module Name: driver
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


`ifndef DRIVER_SV
`define DRIVER_SV

class gaussian_blur_driver extends uvm_driver#(gaussian_blur_seq_item);

    `uvm_component_utils(gaussian_blur_driver)
    
    virtual interface gaussian_blur_if vif;
    
    function new(string name = "driver", uvm_component parent = null);
        super.new(name, parent);
        if (!uvm_config_db#(virtual gaussian_blur_if)::get(this, "", "gaussian_blur_if", vif))
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"})        
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
    endfunction : connect_phase
        
    task main_phase(uvm_phase phase);
   
      forever begin
		@(posedge vif.clk);	 
		if (!vif.rst)
		begin
		seq_item_port.get_next_item(req);  //uzme jedan seq item 
		`uvm_info(get_type_name(), $sformatf("Driver sending...\n%s", req.sprint()), UVM_HIGH)

        //seq_item_port.item_done();
        
        if (req.bram_axi_ctrl == 0) begin
            //BRAM           
            vif.main_bram_a_en_i = req.main_bram_a_en_i;
            vif.main_bram_a_we_i = req.main_bram_a_we_i;
            vif.main_bram_a_addr_i = req.main_bram_a_addr_i;
            vif.main_bram_a_wdata_i = req.main_bram_a_wdata_i;
            
            $display("Data sent to bram");
        end
        else begin
            //REGISTERS IN AXI CTRL
            vif.s00_axi_awaddr = req.s00_axi_awaddr;
            vif.s00_axi_wdata = req.s00_axi_wdata;
            vif.s00_axi_wstrb = 4'b1111;
            vif.s00_axi_awvalid = 1'b1;
            vif.s00_axi_wvalid = 1'b1;
            vif.s00_axi_bready = 1'b1;
            
            @(posedge vif.clk iff vif.s00_axi_awready);
            @(posedge vif.clk iff !vif.s00_axi_awready);
            #20
            vif.s00_axi_awvalid = 1'b0;
            vif.s00_axi_awaddr = 1'b0;
            vif.s00_axi_wdata = 1'b0;
            vif.s00_axi_wvalid = 1'b0;
            vif.s00_axi_wstrb = 4'b0000;
            
            @(posedge vif.clk iff !vif.s00_axi_bvalid);
            #20
            vif.s00_axi_bready = 1'b0;
            $display("Data sent to AXI Lite registers");
            
            //Waiting for ready
            if(req.s00_axi_awaddr == AXI_BASE + START_REG_OFFSET && req.s00_axi_wdata == 1)
                    begin
                        $display("\n Entering final detection...\n");
                        vif.s00_axi_arprot = 3'b000;
                        vif.s00_axi_araddr = AXI_BASE + READY_REG_OFFSET;
                        vif.s00_axi_arvalid = 1'b1;
                        vif.s00_axi_rready  = 1'b1; 

                        @(posedge vif.clk iff vif.s00_axi_arready == 0);
                        @(posedge vif.clk iff vif.s00_axi_arready == 1);
            

                        vif.s00_axi_araddr = 5'd0;
                        vif.s00_axi_arvalid = 1'b0;
                        vif.s00_axi_rready = 1'b0;

                        wait(vif.s00_axi_rdata == 0)

                            $display("\nSystem on the go!\n");
                            vif.s00_axi_awaddr = AXI_BASE + START_REG_OFFSET;
                            vif.s00_axi_wdata = 32'd0;
                            vif.s00_axi_wstrb = 4'b1111;
                            vif.s00_axi_awvalid = 1'b1;
                            vif.s00_axi_wvalid = 1'b1;
                            vif.s00_axi_bready = 1'b1;
                    
                            @(posedge vif.clk iff vif.s00_axi_awready);
                            @(posedge vif.clk iff !vif.s00_axi_awready);
                            #20
                            
                            vif.s00_axi_awvalid = 1'b0;
                            vif.s00_axi_awaddr = 1'b0;
                            vif.s00_axi_wdata = 1'b0;
                            vif.s00_axi_wvalid = 1'b0;
                            vif.s00_axi_wstrb = 4'b0000;
                    
                            @(posedge vif.clk iff !vif.s00_axi_bvalid); 
                            #20
                            vif.s00_axi_bready = 1'b0;
                            $display("\nStart signal taken down! \n");
                            //////////////////////////////////////////////////////
                            $display("\nWaiting for a finishing ready...\n");
                            #20
                            vif.s00_axi_arprot = 3'b000;
                            vif.s00_axi_araddr = AXI_BASE + READY_REG_OFFSET;
                            vif.s00_axi_arvalid = 1'b1;
                            vif.s00_axi_rready  = 1'b1;  

                            @(posedge vif.clk iff vif.s00_axi_arready == 0);
                            @(posedge vif.clk iff vif.s00_axi_arready == 1);
            
                            wait(vif.s00_axi_rdata == 1)
                            vif.s00_axi_araddr = 5'd0;
                            vif.s00_axi_arvalid = 1'b0;

                            

                            $display("\nDUT finished! \n");

                    end   


                    if(req.s00_axi_awaddr == AXI_BASE + RESET_REG_OFFSET && req.s00_axi_wdata == 1)
                    begin

                        $display("\n Waiting for a ready on the initialization... \n");
                        vif.s00_axi_arprot = 3'b000;
                        vif.s00_axi_araddr = AXI_BASE + READY_REG_OFFSET;
                        vif.s00_axi_arvalid = 1'b1;
                        vif.s00_axi_rready  = 1'b1; 

                        @(posedge vif.clk iff vif.s00_axi_arready == 0);
                        @(posedge vif.clk iff vif.s00_axi_arready == 1);
            

                        vif.s00_axi_araddr = 5'd0;
                        vif.s00_axi_arvalid = 1'b0;
                        
                        wait(vif.s00_axi_rdata == 1)
                            $display("\nReady detected!\n");
                            vif.s00_axi_awaddr = AXI_BASE + RESET_REG_OFFSET;
                            vif.s00_axi_wdata = 32'd1;
                            vif.s00_axi_wstrb = 4'b1111;
                            vif.s00_axi_awvalid = 1'b1;
                            vif.s00_axi_wvalid = 1'b1;
                            vif.s00_axi_bready = 1'b1;
                    
                            @(posedge vif.clk iff vif.s00_axi_awready);
                            @(posedge vif.clk iff !vif.s00_axi_awready);
                            #20
                            
                            vif.s00_axi_awvalid = 1'b0;
                            vif.s00_axi_awaddr = 1'b0;
                            vif.s00_axi_wdata = 1'b0;
                            vif.s00_axi_wvalid = 1'b0;
                            vif.s00_axi_wstrb = 4'b0000;
                    
                            @(posedge vif.clk iff !vif.s00_axi_bvalid); 
                            #20
                            vif.s00_axi_bready = 1'b0;
                            $display("\nReset signal taken down! \n");

                        vif.s00_axi_rready = 1'b0;

                    end
                    $display("\nAxi Lite transaction completed! \n");
                end    
            seq_item_port.item_done();
		end
      end
   endtask : main_phase
endclass : gaussian_blur_driver

`endif
