#ifndef SIFT_HPP_ 
#define SIFT_HPP_

#define _USE_MATH_DEFINES

#include <cmath>
#include <iostream>
#include <vector>
#include <algorithm>
#include <array>
#include <tuple>
#include <memory>
#include <cassert>
#include <string>
#include <fstream>
#include <bitset>

#include "image.hpp"

using namespace std;

struct ScaleSpacePyramid {
        int num_octaves;
        int imgs_per_octave;
        
        std::vector<Image> images; 
    };
    
struct Keypoint {
    // discrete coordinates
    int i;
    int j;
    int octave;
    int scale; //index of gaussian image inside the octave

    // continuous coordinates (interpolated)
    float x;
    float y;
    float sigma;
    float extremum_val; //value of interpolated DoG extremum
    
    std::array<uint8_t, 128> descriptor;
};

//*******************************************
// SIFT algorithm parameters, used by default
//*******************************************

//digital scale space configuration and keypoint detection
const int MAX_REFINEMENT_ITERS = 5;
const float SIGMA_MIN = 0.8;
const float MIN_PIX_DIST = 0.5;
const float SIGMA_IN = 0.5;
const int N_OCT = 4; //Broj oktava
const int N_SPO = 3;
const int N_IP = 4;
const float C_DOG = 0.015;
const float C_EDGE = 10;

const int OFFSET_UP_DOWN = 6;

// computation of the SIFT descriptor
const int N_BINS = 36;
const float LAMBDA_ORI = 1.5;
const int N_HIST = 4;
const int N_ORI = 8;
const float LAMBDA_DESC = 6;

std::vector<Image> image_partitions(const Image& img, int num_of_parts= N_IP);

std::vector<Image> combine_partitions(std::vector<std::vector<Image>> img_vec, int num_of_parts= N_IP, int num_octaves = N_OCT, 
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

std::vector<Keypoint> find_keypoints_and_descriptors(const Image& img, int num_of_parts= N_IP,
                            int num_octaves=N_OCT, 
                            int scales_per_octave=N_SPO, 
                            float contrast_thresh=C_DOG,
                            float edge_thresh=C_EDGE,
                            float lambda_ori=LAMBDA_ORI,
                            float lambda_desc=LAMBDA_DESC);


Image draw_keypoints(const Image& img, const std::vector<Keypoint>& kps);

void hists_to_vec(float histograms[N_HIST][N_HIST][N_ORI], std::array<uint8_t, 128>& feature_vec);

void update_histograms(float hist[N_HIST][N_HIST][N_ORI], float x, float y,
                float contrib, float theta_mn, float lambda_desc);
                
void smooth_histogram(float hist[N_BINS]);

bool point_is_extremum(const std::vector<Image>& octave, int scale, int x, int y);

std::tuple<float, float, float> fit_quadratic(Keypoint& kp, const std::vector<Image>& octave, int scale);

bool point_is_on_edge(const Keypoint& kp, const std::vector<Image>& octave, float edge_thresh=C_EDGE);

void find_input_img_coords(Keypoint& kp, float offset_s, float offset_x, float offset_y, float sigma_min=SIGMA_MIN,
                            float min_pix_dist=MIN_PIX_DIST, int n_spo=N_SPO);
                            
bool refine_or_discard_keypoint(Keypoint& kp, const std::vector<Image>& octave,
                        float contrast_thresh, float edge_thresh);
                             
#endif     
