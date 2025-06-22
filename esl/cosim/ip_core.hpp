#ifndef HARD_H
#define HARD_H

#include <vector>
#include <array>
#include <cstdint>
#include <sysc/datatypes/fx/sc_fixed.h>
#include <tlm>

#include "addr.hpp"
#include "functions.hpp"
#include "sc_types.hpp"
#include "top_model.hpp"

using namespace std;
using namespace tlm;

class Ip_Core: public sc_core::sc_module , public tlm::tlm_fw_transport_if<>
{
public:
    Ip_Core(sc_core::sc_module_name name);
	~Ip_Core();
	
	tlm::tlm_target_socket<> interconnect_socket;
	sc_core::sc_time offset_hard;

	void b_transport(pl_t&, sc_core::sc_time&);	

	tlm::tlm_sync_enum nb_transport_fw(pl_t&, ph_t&, sc_core::sc_time &);
	bool get_direct_mem_ptr(pl_t&, tlm::tlm_dmi&);
	unsigned int transport_dbg(pl_t &);
	
protected:
    
    top_model top;
    
    sc_core::sc_clock clk ;
    sc_core::sc_signal< sc_dt::sc_logic > reset ;
    sc_core::sc_signal< sc_dt::sc_logic > start ; 
    
    sc_core::sc_signal< sc_dt::sc_lv<16> > img_height ;
    sc_core::sc_signal< sc_dt::sc_lv<16> > img_width ;
    sc_core::sc_signal< sc_dt::sc_lv<16> > img_offset_up ;
    sc_core::sc_signal< sc_dt::sc_lv<16> > img_offset_down ;
    sc_core::sc_signal< sc_dt::sc_lv<16> > img_per_octave ;
        
    sc_core::sc_signal< sc_dt::sc_logic > main_bram_a_cpu_en ;
    sc_core::sc_signal< sc_dt::sc_lv<4> > main_bram_a_cpu_we ;
    sc_core::sc_signal< sc_dt::sc_lv<15> > main_bram_a_cpu_addr ;
    sc_core::sc_signal< sc_dt::sc_lv<32> > main_bram_a_cpu_rdata ;
    sc_core::sc_signal< sc_dt::sc_lv<32> > main_bram_a_cpu_wdata ;
        
    sc_core::sc_signal< sc_dt::sc_logic > ready ;    
      
};  

#ifndef SC_MAIN
SC_MODULE_EXPORT(Ip_Core)
#endif    

#endif
