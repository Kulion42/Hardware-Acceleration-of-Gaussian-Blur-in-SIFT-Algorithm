#ifndef HARD_H
#define HARD_H

#include <vector>
#include <array>
#include <cstdint>
#include "image.hpp"
#include "sc_types.hpp"


struct ScaleSpacePyramid {
    uint8_t num_octaves;
    uint8_t imgs_per_octave;
    
    std::vector<Image> images; 
};

const k_t SIGMA_MIN = 0.8;
const k_t MIN_PIX_DIST = 0.5;
const uint8_t N_OCT = 8; //Broj oktava
const uint8_t N_SPO = 3;

ScaleSpacePyramid generate_gaussian_pyramid(const Image& img, sigma_base_diff_t sigma_min=SIGMA_MIN,
                                         uint8_t num_octaves=N_OCT, uint8_t scales_per_octave=N_SPO);
                                         
Image resize(const Image& orig, uint16_t new_w, uint16_t new_h, Interpolation method = BILINEAR);

Image gaussian_blur(const Image& img, sigma_base_diff_t sigma);

floor_ceil_t map_coordinate(floor_ceil_t new_max, floor_ceil_t current_max, floor_ceil_t coord);

k_t bilinear_interpolate(const Image& img,  floor_ceil_t x, floor_ceil_t y, uint8_t c);

k_t nn_interpolate(const Image& img, floor_ceil_t x, floor_ceil_t y, uint8_t c);

#endif
