#ifndef SOFT_HPP_ 
#define SOFT_HPP_

#define _USE_MATH_DEFINES

#include <cmath>
#include <iostream>
#include <vector>
#include <algorithm>
#include <array>
#include <tuple>
#include <cassert>
#include <string>
#include <systemc>
#include <fstream>

#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>

#include "addr.hpp"
#include "functions.hpp"
#include "image.hpp"
#include "sc_types.hpp"


using namespace std;

class Cpu : public sc_core::sc_module
{
  public:
		Cpu(sc_core::sc_module_name name);
		~Cpu();
		tlm_utils::simple_initiator_socket<Cpu> interconnect_socket;
        tlm_utils::simple_initiator_socket<Cpu> bram_socket;
  protected:
  
		static char **input_arguments;
		static int argc;
		
		
		void soft();


		//const verovatno treba obrisati ovde, a dodati ih pri pozivu
		std::vector<Image> image_partitions(const Image& img, int num_of_parts= N_IP);
		
        std::vector<Image> combine_partitions(std::vector< std::vector<Image> > img_vec, int num_of_parts= N_IP, int imgs_per_octave = N_SPO+3, int num_octaves = N_OCT, 
                                                     int scales_per_octave=N_SPO);
                                                     
        std::vector<Image> generate_gaussian_pyramid_vector(const Image& img, int img_num, float sigma_min=SIGMA_MIN, int num_of_parts=N_IP,
                                             int num_octaves=N_OCT, int scales_per_octave=N_SPO);
		ScaleSpacePyramid generate_dog_pyramid(const ScaleSpacePyramid& img_pyramid);

		vector<Keypoint> find_keypoints(const ScaleSpacePyramid& dog_pyramid,
                                     float contrast_thresh=C_DOG, float edge_thresh=C_EDGE);

		ScaleSpacePyramid generate_gradient_pyramid(const ScaleSpacePyramid& pyramid);

		vector<float> find_keypoint_orientations(Keypoint& kp, const ScaleSpacePyramid& grad_pyramid,
                                              float lambda_ori=LAMBDA_ORI, float lambda_desc=LAMBDA_DESC);

		void compute_keypoint_descriptor(Keypoint& kp, float theta, const ScaleSpacePyramid& grad_pyramid,
                                 float lambda_desc=LAMBDA_DESC);


		Image draw_keypoints(const Image& img, const std::vector<Keypoint>& kps);
	    
	    int read_hard(sc_dt::sc_uint<64> addr);
	    void write_hard(sc_dt::sc_uint<64> addr, sc_int<8> val);
	    
        data_t read_mem(sc_dt::sc_uint<64> addr);
	    void write_mem(sc_dt::sc_uint<64> addr, data_t val);
 }   
    
