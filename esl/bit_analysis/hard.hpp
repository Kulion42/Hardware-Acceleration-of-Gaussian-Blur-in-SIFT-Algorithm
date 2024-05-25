#ifndef HARD_H
#define HARD_H

#include <vector>
#include <array>
#include <cstdint>
#include "image.hpp"
#include "sc_types.hpp"

using namespace std;
using namespace sc_dt;

    //output structure
    struct ScaleSpacePyramid {
        uint8_t num_octaves;
        uint8_t imgs_per_octave;
        
        std::vector<Image> images; 
    };

    //constants
    const k_t SIGMA_MIN = 0.8;
    const k_t MIN_PIX_DIST = 0.5;
    const uint8_t N_OCT = 8; //Broj oktava
    const uint8_t N_SPO = 3;
   
    
    ScaleSpacePyramid generate_gaussian_pyramid(const Image& img, k_t sigma_min=SIGMA_MIN,
                                             uint8_t num_octaves=N_OCT, uint8_t scales_per_octave=N_SPO);
                                             
    Image resize(const Image& orig, uint16_t new_w, uint16_t new_h, Interpolation method = BILINEAR);

    Image gaussian_blur(const Image& img, sigma_prev_total_t sigma);

#endif
