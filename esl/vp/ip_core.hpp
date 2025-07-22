#ifndef IP_CORE_H
#define IP_CORE_H

#include <vector>
#include <array>
#include <cstdint>
#include <bitset>
#include <sysc/datatypes/fx/sc_fixed.h>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <tlm_utils/simple_initiator_socket.h>

#include "addr.hpp"
#include "functions.hpp"
#include "sc_types.hpp"
#include "constants_and_structs.hpp"

using namespace std;
using namespace sc_dt;

class Ip_Core: public sc_core::sc_module
{
public:
    Ip_Core(sc_core::sc_module_name name);
	~Ip_Core();
	
	tlm_utils::simple_target_socket<Ip_Core> interconnect_socket;
	tlm_utils::simple_initiator_socket<Ip_Core> main_bram_socket;
	tlm_utils::simple_initiator_socket<Ip_Core> tmp_bram_socket;
	tlm_utils::simple_initiator_socket<Ip_Core> kernel_rom_socket;	
	
protected:

    //input parameters
    sc_int<16> img_width;
    sc_int<16> img_height;
    sc_int<16> img_offset_up;
    sc_int<16> img_offset_down;
    sc_int<16> img_per_octave;
    sc_uint<1> reset;
    sc_uint<1> start;
    
    //output signal
    sc_uint<1> ready;
    
    sc_core::sc_time offset;
    sc_int<16> addr_off;
    vector <sigma_t> sigma_vals;
    
    void b_transport(pl_t&, sc_core::sc_time&);	
	void gaussian_blur(sc_core::sc_time&);
	void read_mem(sc_dt::sc_uint<64> addr, data_t *pix);
	void write_mem(sc_dt::sc_uint<64> addr, data_t *pix1);
	void read_rom(sc_dt::sc_uint<64> addr, data_t *val);

    
}  ; 
    
#endif
