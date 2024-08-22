#include "hard.hpp"


using namespace std;
using namespace sc_dt;


Image gaussian_blur(const Image& img, sigma_t sigma, uint16_t offset_up , uint16_t offset_down, uint16_t j)
{
    assert(img.channels == 1);
     FILE *fp; 
    char numstr[21];
    std::string blur_x= "convolutions/convolute_x_";
    std::string blur_y = "convolutions/convolute_y_";
    std::string res;
    int size = std::ceil(6 * sigma);
  
    if (size % 2 == 0)
        size++;
    
    int center = size / 2;
    //  cout << " Startin gaussian_blur" << endl;  
   // cout << center << endl;
    Image kernel(size, 1, 1);
    sigma_t sum = 0;
        for (int k = -size/2; k <= size/2; k++) {
        num_t val = std::exp(-(k*k) / (2*sigma*sigma));
       // cout << val << endl;
        kernel.set_pixel(center+k, 0, 0, val);
        sum += val;
    }
 //  cout << endl;
    for (int k = 0; k < size; k++){
        kernel.data[k] /= sum;
      // cout << kernel.data[k] << endl;
        }
      int test = 0;
      int test1 = 0; 
    Image tmp(img.width, img.height-(offset_up + offset_down), 1);
    Image filtered(img.width, img.height-(offset_up + offset_down), 1);
    
    sprintf(numstr, "%d", j);
    res = blur_y + numstr +".txt";
    fp = fopen(res.c_str(), "w+");
    
    //cout << tmp.height << " " << img.height << endl;
    // convolve vertical
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = offset_up; y < img.height - offset_down; y++) {
       //cout << img.height - offset_down << y << endl;
            num_t sum = 0;
            for (int k = 0; k < size; k++) {
                int dy = -center + k;
                
               // fprintf(fp, "\t%d\n\n", y+dy);
               //cout << y <<" " << dy << " " << tmp.height << endl;
               fprintf(fp, "%2.14lf\n" , (double)img.get_pixel(x, y+dy, 0));
                sum += img.get_pixel(x, y+dy, 0) * kernel.data[k];
               
            }
            tmp.set_pixel(x, y-offset_up, 0, sum);
        }
    }
    fclose(fp);
    sprintf(numstr, "%d", j);
    res = blur_x + numstr +".txt";
    fp = fopen(res.c_str(), "w+");
       // cout << test << endl;
    // convolve horizontal
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = 0; y < tmp.height; y++) {
            num_t sum = 0;
            for (uint8_t k = 0; k < size; k++) {
                int8_t dx = -center + k;
               // fprintf(fp, "%2.14lf\n" , (double)tmp.get_pixel(x+dx, y, 0));
                sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                fprintf(fp, "%2.14lf\n", (double)kernel.data[k]) ;
            }

            fprintf(fp, "%2.14lf\n\n" , (double)sum);
           // cout << sum << endl;
            filtered.set_pixel(x, y, 0, sum);
        }
    }
    fclose(fp);
   
    //cout << "Izlazi hard" << endl;
    return filtered;
}


