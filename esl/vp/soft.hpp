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

#include "types.hpp"

using namespace std;

class Soft : public sc_core::sc_module
{
  public:
		Soft(sc_core::sc_module_name name);
		~Soft();
		tlm_utils::simple_initiator_socket<Soft> interconnect_socket;
  
  protected:
  
		static char **input_arguments;
		static int argc;
		
		
		void soft();


		//const verovatno treba obrisati ovde, a dodati ih pri pozivu
		
		ScaleSpacePyramid generate_dog_pyramid(const ScaleSpacePyramid& img_pyramid);

		vector<Keypoint> find_keypoints(const ScaleSpacePyramid& dog_pyramid,
                                     float contrast_thresh=C_DOG, float edge_thresh=C_EDGE);

		ScaleSpacePyramid generate_gradient_pyramid(const ScaleSpacePyramid& pyramid);

		vector<float> find_keypoint_orientations(Keypoint& kp, const ScaleSpacePyramid& grad_pyramid,
                                              float lambda_ori=LAMBDA_ORI, float lambda_desc=LAMBDA_DESC);

		void compute_keypoint_descriptor(Keypoint& kp, float theta, const ScaleSpacePyramid& grad_pyramid,
                                 float lambda_desc=LAMBDA_DESC);

		//vector<Keypoint> find_keypoints_and_descriptors(const Image& img, k_t sigma_min=SIGMA_MIN,
		//  			    						   int num_octaves=N_OCT, 
        //                                             int scales_per_octave=N_SPO, 
        //                                             float contrast_thresh=C_DOG,
        //                                             float edge_thresh=C_EDGE,
        //                                             float lambda_ori=LAMBDA_ORI,
        //                                             float lambda_desc=LAMBDA_DESC);


		Image draw_keypoints(const Image& img, const std::vector<Keypoint>& kps);
	
    
    
    
