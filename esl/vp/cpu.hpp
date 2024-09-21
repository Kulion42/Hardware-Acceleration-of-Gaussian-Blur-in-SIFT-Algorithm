#ifndef CPU_HPP_ 
#define CPU_HPP_

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
#include <systemc>
#include <fstream>
#include <bitset>

#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>

#include "image.hpp"
#include "constants_and_structs.hpp"
#include "addr.hpp"
#include "functions.hpp"
#include "sc_types.hpp"


using namespace std;

class Cpu : public sc_core::sc_module
{
  public:
		Cpu(sc_core::sc_module_name name, char** strings, int arg_count);
		~Cpu();
		tlm_utils::simple_initiator_socket<Cpu> interconnect_socket;
		
  protected:
  
		static char **input_arguments;
		static int argc;
		
		sc_core::sc_time offset_soft;
		int enable = 1;
		void soft();


		//const verovatno treba obrisati ovde, a dodati ih pri pozivu
		std::vector<Image> image_partitions(const Image& img, int num_of_parts= N_IP);
		
        std::vector<Image> combine_partitions(std::vector< std::vector<Image> > img_vec, int num_of_parts= N_IP, int num_octaves = N_OCT, 
                                                     int scales_per_octave=N_SPO);
                                                     
        std::vector<Image> generate_gaussian_pyramid_vector(const Image& img, int img_num, int& enable, float sigma_min=SIGMA_MIN, int num_of_parts=N_IP,
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
	    void write_hard(sc_dt::sc_uint<64> addr, sc_dt::sc_int<16> val);
	    
        void read_mem(sc_dt::sc_uint<64> addr, data_t& pix1, data_t& pix2);
	    void write_mem(sc_dt::sc_uint<64> addr, data_t pix1, data_t pix2);
   

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
                                
                                
       } ;
       
#endif     
