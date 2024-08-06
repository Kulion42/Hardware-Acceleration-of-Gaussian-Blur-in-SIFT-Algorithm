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
#include "image.hpp"
#include "sc_types.hpp"

using namespace std;
using namespace sc_dt;

class Hard :
    public :    sc_core(sc_module)

{
public:
    Ip_core(sc_core::sc_module_name);
	~Ip_core();
	
	tlm_utils::simple_target_socket<Ip_core> interconnect_socket;
	tlm_utils::simple_initiator_socket<Ip_core> bram_socket;
protected:
    pl_t pl;
    sc_time offset;
    
    //input parameters
    sc_int<16> img_width;
    sc_int<16> img_height;
    sc_int<8> img_offset_up;
    sc_int<8> img_offset_down;
    sigma_prev_total_t sigma;
    sc_uint<1> reset;
    sc_uint<1> start;
    
    //output signal
    sc_uint<1> ready;

    //variables used
    num_t sum, val;
    sc_int<8> size, center, k;
    sc_int<8> dx, dy; 
    sc_int<16> x, y;
    
    void b_transport(pl_t&, sc_core::sc_time&);	
	void gaussian_blur(sc_time offset);
	char read_mem(sc_dt::sc_uint<64> addr);
	void write_mem(sc_dt::sc_uint<64> addr, data_t val);
    
}   
    


#endif
