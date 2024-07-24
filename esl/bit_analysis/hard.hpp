#ifndef HARD_H
#define HARD_H

#include <vector>
#include <array>
#include <cstdint>
#include "image.hpp"
#include "sc_types.hpp"

using namespace std;
using namespace sc_dt;

    
    Image gaussian_blur(const Image& img, sigma_prev_total_t sigma);

#endif
