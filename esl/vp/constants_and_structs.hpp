#ifndef CONSTANTS_AND_STRUCTS_HPP
#define CONSTANTS_AND_STRUCTS_HPP

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
const int N_OCT = 4; //Broj oktava
const int N_SPO = 3;
const int N_IP = 4;
const float C_DOG = 0.015;
const float C_EDGE = 10;
// image partition offset 
const int OFFSET_UP_DOWN = 5;

// computation of the SIFT descriptor
const int N_BINS = 36;
const float LAMBDA_ORI = 1.5;
const int N_HIST = 4;
const int N_ORI = 8;
const float LAMBDA_DESC = 6;


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
