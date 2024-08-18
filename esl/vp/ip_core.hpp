#ifndef HARD_H
#define HARD_H

#include <vector>
#include <array>
#include <cstdint>
#include <sysc/datatypes/fx/sc_fixed.h>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <tlm_utils/simple_initiator_socket.h>

#include "addr.hpp"
#include "functions.hpp"
#include "sc_types.hpp"

using namespace std;
using namespace sc_dt;

class Ip_Core: public sc_core::sc_module
{
public:
    Ip_Core(sc_core::sc_module_name name);
	~Ip_Core();
	
	tlm_utils::simple_target_socket<Ip_Core> interconnect_socket;
	tlm_utils::simple_initiator_socket<Ip_Core> mem_socket;
	
protected:
    pl_t pl;
    sc_core::sc_time offset;
    
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

    //variables used
    sigma_t sigma;
    sum_t sum, val;
    sc_int<16> size, center, k;
    sc_int<16> dx, dy; 
    sc_int<16> x, y;
    sc_int<16> c_x = 0, c_y = 0;
    
    void b_transport(pl_t&, sc_core::sc_time&);	
	void gaussian_blur(sc_core::sc_time &offset);
	data_t read_mem(sc_dt::sc_uint<64> addr);
	void write_mem(sc_dt::sc_uint<64> addr, data_t val);
	sigma_t read_rom(sc_dt::sc_uint<64> addr);
    
}  ; 
    


#endif
