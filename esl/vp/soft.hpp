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

class Cpu : public sc_core::sc_module
{
  public:
	  Soft(sc_core::sc_module_name name);
    ~Soft();
    tlm_utils::simple_initiator_socket<Soft> interconnect_socket;
  
  protected:
    
    
    
    float bilinear_interpolate(const Image& img, float x, float y, int c);
    float nn_interpolate(const Image& img, float x, float y, int c);

    Image rgb_to_grayscale(const Image& img);
    Image grayscale_to_rgb(const Image& img);

    Image gaussian_blur(const Image& img, float sigma);

    void draw_point(Image& img, int x, int y, int size=3);
    
    ScaleSpacePyramid generate_gaussian_pyramid(const Image& img, float sigma_min=SIGMA_MIN,
                                            int num_octaves=N_OCT, int scales_per_octave=N_SPO);

    ScaleSpacePyramid generate_dog_pyramid(const ScaleSpacePyramid& img_pyramid);

    std::vector<Keypoint> find_keypoints(const ScaleSpacePyramid& dog_pyramid,
                                     float contrast_thresh=C_DOG, float edge_thresh=C_EDGE);

    ScaleSpacePyramid generate_gradient_pyramid(const ScaleSpacePyramid& pyramid);

    std::vector<float> find_keypoint_orientations(Keypoint& kp, const ScaleSpacePyramid& grad_pyramid,
                                              float lambda_ori=LAMBDA_ORI, float lambda_desc=LAMBDA_DESC);

    void compute_keypoint_descriptor(Keypoint& kp, float theta, const ScaleSpacePyramid& grad_pyramid,
                                 float lambda_desc=LAMBDA_DESC);

    std::vector<Keypoint> find_keypoints_and_descriptors(const Image& img, float sigma_min=SIGMA_MIN,
                                                     int num_octaves=N_OCT, 
                                                     int scales_per_octave=N_SPO, 
                                                     float contrast_thresh=C_DOG,
                                                     float edge_thresh=C_EDGE,
                                                     float lambda_ori=LAMBDA_ORI,
                                                     float lambda_desc=LAMBDA_DESC);

    Image draw_keypoints(const Image& img, const std::vector<Keypoint>& kps);
    
    
