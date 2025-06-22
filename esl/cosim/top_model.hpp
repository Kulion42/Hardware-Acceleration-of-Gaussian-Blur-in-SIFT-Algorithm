#ifndef TOP_MODEL_HPP_
#define TOP_MODEL_HPP_

#include <systemc>

class top_model : public sc_core::sc_foreign_module{
public:
    top_model(sc_core::sc_module_name name) :
        sc_core::sc_foreign_module(name),
		clk("clk"),
		reset("reset"),
		start("start"), 
		
		img_height("img_height"),
        img_width("img_width"),
        img_offset_up("img_offset_up"),
        img_offset_down("img_offset_down"),
        img_per_octave("img_per_octave"),
        
        main_bram_a_cpu_en("main_bram_a_cpu_en"),
        main_bram_a_cpu_we("main_bram_a_cpu_we"),
        main_bram_a_cpu_addr("main_bram_a_cpu_addr"),
        main_bram_a_cpu_rdata("main_bram_a_cpu_rdata"),
        main_bram_a_cpu_wdata("main_bram_a_cpu_wdata"),
        
        ready("ready")
        
        {
        
        }          
        
        sc_core::sc_in<bool> clk ;
		sc_core::sc_in< sc_dt::sc_logic > reset ;
		sc_core::sc_in< sc_dt::sc_logic > start ; 
		
		sc_core::sc_in< sc_dt::sc_lv<16> > img_height ;
        sc_core::sc_in< sc_dt::sc_lv<16> > img_width ;
        sc_core::sc_in< sc_dt::sc_lv<16> > img_offset_up ;
        sc_core::sc_in< sc_dt::sc_lv<16> > img_offset_down ;
        sc_core::sc_in< sc_dt::sc_lv<16> > img_per_octave ;
        
        sc_core::sc_in< sc_dt::sc_logic > main_bram_a_cpu_en ;
        sc_core::sc_in< sc_dt::sc_lv<4> > main_bram_a_cpu_we ;
        sc_core::sc_in< sc_dt::sc_lv<15> > main_bram_a_cpu_addr ;
        sc_core::sc_out< sc_dt::sc_lv<32> > main_bram_a_cpu_rdata ;
        sc_core::sc_in< sc_dt::sc_lv<32> > main_bram_a_cpu_wdata ;       
              
        sc_core::sc_out< sc_dt::sc_logic > ready ;
        
        const char* hdl_name() const { return "top_model"; }
                
};

#endif
