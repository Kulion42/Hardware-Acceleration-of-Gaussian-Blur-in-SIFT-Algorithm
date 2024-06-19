#ifndef IP_CORE_H
#define IP_CORE_H

#include <vector>
#include <array>
#include <cstdint>
#include <sysc/datatypes/fx/sc_fixed.h>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <tlm_utils/simple_initiator_socket.h>
#include "functions.hpp"
#include "image.hpp"
#include "sc_types.hpp"

using namespace std;
using namespace sc_dt;

//constants
    const k_t SIGMA_MIN = 0.8;
    const k_t MIN_PIX_DIST = 0.5;
    const sc_uint<8> N_OCT = 8; //Broj oktava
    const sc_uint<8> N_SPO = 3;
    
class Ip_core:
    public : sc_core(sc_module)
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
    sc_int<8> img_channels;
    sc_uint<1> reset;
    sc_uint<1> start;
    
    //output signal
    sc_uint<1> ready;
    
    //output structure
    struct ScaleSpacePyramid {
        sc_uint<8> num_octaves;
        sc_uint<8> imgs_per_octave;
        
        std::vector<Image> images; 
    };
    
    /*variables used
    num_t p1, p2, p3, p4, q1, q2, sum_1;
    k_t value, val;
    sigma_prev_total_t sum_2;
    sc_int<8> size, center, d_coord;
    */
    
    void b_transport(pl_t&, sc_core::sc_time&);	
	ScaleSpacePyramid generate_gaussian_pyramid(const Image& img, sc_time offset);
	char read_mem(sc_dt::sc_uint<64> addr);
	void write_mem(sc_dt::sc_uint<64> addr, data_t val);
    
    }
    
#endif
