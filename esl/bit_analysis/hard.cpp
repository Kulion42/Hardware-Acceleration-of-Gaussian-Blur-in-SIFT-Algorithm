#include "hard.hpp"


using namespace std;
using namespace sc_dt;


Image gaussian_blur(const Image& img, sigma_t sigma, uint16_t offset_up , uint16_t offset_down, uint16_t j)
{
    assert(img.channels == 1);
   
    int size = std::ceil(6 * sigma);
  
    if (size % 2 == 0)
        size++;
    
    int center = size / 2;
    //  cout << " Startin gaussian_blur" << endl;  

    Image kernel(size, 1, 1);
    sigma_t sum = 0;
        for (int k = -size/2; k <= size/2; k++) {
        num_t val = std::exp(-(k*k) / (2*sigma*sigma));
        kernel.set_pixel(center+k, 0, 0, val);
        sum += val;
    }
    
    for (int k = 0; k < size; k++){
        kernel.data[k] /= sum;
      // cout << kernel.data[k] << endl;
        }
 
    Image tmp(img.width, img.height-(offset_up + offset_down), 1);
    Image filtered(img.width, img.height-(offset_up + offset_down), 1);
    
    // convolve vertical
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = offset_up; y < img.height - offset_down; y++) {
       //cout << img.height - offset_down << y << endl;
            num_t sum = 0;
            for (int k = 0; k < size; k++) {
                int dy = -center + k;
                
                sum += img.get_pixel(x, y+dy, 0) * kernel.data[k];
               
            }
            tmp.set_pixel(x, y-offset_up, 0, sum);
        }
    }

    // convolve horizontal
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = 0; y < tmp.height; y++) {
            num_t sum = 0;
            for (uint8_t k = 0; k < size; k++) {
                int8_t dx = -center + k;

                sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
            }

            filtered.set_pixel(x, y, 0, sum);
        }
    }
   
    //cout << "Izlazi hard" << endl;
    return filtered;
}


