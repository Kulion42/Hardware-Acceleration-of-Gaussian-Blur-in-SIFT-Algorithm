#include "hard.hpp"


using namespace std;
using namespace sc_dt;


Image gaussian_blur(const Image& img, sigma_prev_total_t sigma)
{
    assert(img.channels == 1);

    int size = std::ceil(6 * sigma);
  
    if (size % 2 == 0)
        size++;
    
    int center = size / 2;
   // cout << center << endl;
    Image kernel(size, 1, 1);
    sigma_prev_total_t sum = 0;
        for (int k = -size/2; k <= size/2; k++) {
        k_t val = std::exp(-(k*k) / (2*sigma*sigma));
        //cout << val << endl;
        kernel.set_pixel(center+k, 0, 0, val);
        sum += val;
    }
   // cout << kernel.size << endl;
 //  cout << endl;
    for (uint8_t k = 0; k < size; k++){
        kernel.data[k] /= sum;
      //  cout << kernel.data[k] << endl;
        }
    Image tmp(img.width, img.height, 1);
    Image filtered(img.width, img.height, 1);

    // convolve vertical
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = 0; y < img.height; y++) {
            num_t sum = 0;
            for (uint8_t k = 0; k < size; k++) {
                int8_t dy = -center + k;
                
                sum += img.get_pixel(x, y+dy, 0) * kernel.data[k];
               
            }
            tmp.set_pixel(x, y, 0, sum);
           // cout << tmp.get_pixel(x, y, 0)<<endl;
        }
    }
    // convolve horizontal
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = 0; y < img.height; y++) {
            num_t sum = 0;
            for (uint8_t k = 0; k < size; k++) {
                int8_t dx = -center + k;
                
                sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                 
            }
           // cout << sum << endl;
            filtered.set_pixel(x, y, 0, sum);
        }
    }
    return filtered;
}


