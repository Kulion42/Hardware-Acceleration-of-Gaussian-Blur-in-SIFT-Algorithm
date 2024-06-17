#ifndef TYPES_H
#define TYPES_H

#define SC_INCLUDE_FX

#include <systemc>
#include <vector>
#include <array>
#include <cstdint>

#include "image.hpp"


//*******************************************
// SIFT algorithm parameters, used by default
//*******************************************

// digital scale space configuration and keypoint detection
const int MAX_REFINEMENT_ITERS = 5;
const float SIGMA_MIN = 0.8;
const float MIN_PIX_DIST = 0.5;
const float SIGMA_IN = 0.5;
const int N_OCT = 8; //Broj oktava
const int N_SPO = 3;
const float C_DOG = 0.015;
const float C_EDGE = 10;

// computation of the SIFT descriptor
const int N_BINS = 36;
const float LAMBDA_ORI = 1.5;
const int N_HIST = 4;
const int N_ORI = 8;
const float LAMBDA_DESC = 6;

//----------------SC TYPES-----------------------
typedef sc_dt::sc_ufixed_fast<16, 0> num_t;
typedef sc_dt::sc_fixed_fast<16, 10> floor_ceil_t;
typedef sc_dt::sc_ufixed_fast<16, 2> sigma_base_diff_t;
typedef sc_dt::sc_ufixed_fast<16, 3> sigma_prev_total_t;
typedef sc_dt::sc_ufixed_fast<16, 1> k_t;
typedef sc_dt::sc_fixed_fast<16, 2> data_t;
//-----------------------------------------------


struct ScaleSpacePyramid {
    int num_octaves;
    int imgs_per_octave;
    
    //ovo je potrebno prebaciti u 1D
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



#endif
