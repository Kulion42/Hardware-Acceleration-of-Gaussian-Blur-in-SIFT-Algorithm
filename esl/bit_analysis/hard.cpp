#include "hard.hpp"


using namespace std;
using namespace sc_dt;

floor_ceil_t map_coordinate(float new_max, float current_max, float coord)
{
    float a = new_max / current_max;
    float b = -0.5 + a*0.5;
   
    return a*coord + b;
}


ScaleSpacePyramid generate_gaussian_pyramid(const Image& img, k_t sigma_min,
                                            uint8_t num_octaves, uint8_t scales_per_octave)
{

    // assume initial sigma is 1.0 (after resizing) and smooth
    // the image with sigma_diff to reach requried base_sigma
   sigma_base_diff_t base_sigma;//constant
   base_sigma = sigma_min / MIN_PIX_DIST;//constant
   Image base_img = resize(img, img.width*2, img.height*2, Interpolation::BILINEAR);//ide u bram 0
  

    
    sigma_base_diff_t sigma_diff;
    sigma_diff = std::sqrt(base_sigma*base_sigma - 1.0f);//constant
    
    
    base_img = gaussian_blur(base_img, sigma_diff);//ide u bram 0 prima iz bram 0


    uint8_t imgs_per_octave = scales_per_octave + 3;//constant

    // determine sigma values for bluring
    k_t k;//reg 1
    k = std::pow(2, 1.0/scales_per_octave);
    std::vector<sigma_prev_total_t> sigma_vals {base_sigma};//reg bank of 5
    for (uint8_t i = 1; i < imgs_per_octave; i++) {
   	sigma_prev_total_t sigma_prev, sigma_total;
        sigma_prev = base_sigma * std::pow(k, i-1);//reg 2
        sigma_total = k * sigma_prev;//reg 3
        sigma_vals.push_back(std::sqrt(sigma_total*sigma_total - sigma_prev*sigma_prev));
		//cout << sigma_vals[i] <<endl;
		
    }
    // create a scale space pyramid of gaussian images
    // images in each octave are half the size of images in the previous one
    ScaleSpacePyramid pyramid = {
        num_octaves,
        imgs_per_octave,
        std::vector<Image>(num_octaves*imgs_per_octave) //ide u bram glavno
    };
    for (uint8_t i = 0; i < num_octaves; i++) {
      //pyramid.octaves[i].reserve(imgs_per_octave);
      pyramid.images[i*imgs_per_octave] = (base_img); //prima iz bram 0 ide u bram glavno
      
      for(uint8_t j = 1; j < imgs_per_octave; j++){  
          
          const Image& prev_img = pyramid.images[i*imgs_per_octave + (j-1)];//ide u bram 2
        pyramid.images[i*imgs_per_octave + j] = (gaussian_blur(prev_img, sigma_vals[j])); //prima iz bram 2 ide u bram glavno
          
                 
      }
          
          // prepare base image for next octave
          const Image& next_base_img = pyramid.images[i*imgs_per_octave + (imgs_per_octave - 3)];//ide u bram 1
          base_img = resize(next_base_img, next_base_img.width/2, next_base_img.height/2, Interpolation::NEAREST);//prima iz bram 1 ide u bram 0
         

  
    }
    
    return pyramid;
}


Image gaussian_blur(const Image& img, sigma_prev_total_t sigma)
{
    assert(img.channels == 1);

    int size = std::ceil(6 * sigma);//reg 4
  
    if (size % 2 == 0)
        size++;
    
    int center = size / 2;//moze preko reg 4
   // cout << center << endl;
    Image kernel(size, 1, 1);//bram 2
    sigma_prev_total_t sum = 0;//reg 5
        for (int k = -size/2; k <= size/2; k++) {
        k_t val = std::exp(-(k*k) / (2*sigma*sigma));//reg 6
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
    Image tmp(img.width, img.height, 1);//bram 3
    Image filtered(img.width, img.height, 1);//bram 4

    // convolve vertical
    for (uint16_t x = 0; x < img.width; x++) {//reg 21, 22 i 23
        for (uint16_t y = 0; y < img.height; y++) {
            num_t sum = 0;//reg 6
            for (uint8_t k = 0; k < size; k++) {
                int8_t dy = -center + k;//reg 7
                
                sum += img.get_pixel(x, y+dy, 0) * kernel.data[k];
               
            }
            tmp.set_pixel(x, y, 0, sum);
           // cout << tmp.get_pixel(x, y, 0)<<endl;
        }
    }
    // convolve horizontal
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = 0; y < img.height; y++) {
            num_t sum = 0;//reg 8
            for (uint8_t k = 0; k < size; k++) {
                int8_t dx = -center + k;//reg 9
                
                sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                 
            }
           // cout << sum << endl;
            filtered.set_pixel(x, y, 0, sum);
        }
    }
    return filtered;//ide u bram 0 i 2
}

Image resize(const Image& orig, uint16_t new_w, uint16_t new_h, Interpolation method) 
{
    Image resized(new_w, new_h, orig.channels);//bram 5
    k_t value = 0;//reg 10
 
    for (uint16_t x = 0; x < new_w; x++) {//reg 21, 22 i 23
        for (uint16_t y = 0; y < new_h; y++) {
            for (uint8_t c = 0; c < resized.channels; c++) {
            	floor_ceil_t old_x, old_y;//regs 11, 12
                 old_x = map_coordinate(orig.width, new_w, x);
                //cout << old_x << endl;
                 old_y = map_coordinate(orig.height, new_h, y);
              //cout << old_y <<endl;
                
                if (method == Interpolation::BILINEAR)
                    value = bilinear_interpolate(orig, old_x, old_y, c);
                else if (method == Interpolation::NEAREST)
                    value = nn_interpolate(orig, old_x, old_y, c);     
                
                    //cout << value << endl;
                resized.set_pixel(x, y, c, value);
            }
        }
    }
   
    return resized;//ide u bram 0
}
k_t bilinear_interpolate(const Image& img,  floor_ceil_t x, floor_ceil_t y, uint8_t c)
{
    num_t p1, p2, p3, p4, q1, q2;//regs 13, 14, 15, 16, 17, 18
    //float p1, p2, p3, p4, q1, q2;
    floor_ceil_t x_floor = std::floor(x), y_floor = std::floor(y);//19, 20
    floor_ceil_t x_ceil = x_floor + 1, y_ceil = y_floor + 1;//moze preko 19 i 20
   ;
    p1 = img.get_pixel(x_floor, y_floor, c);
    p2 = img.get_pixel(x_ceil, y_floor, c);
    p3 = img.get_pixel(x_floor, y_ceil, c);
    p4 = img.get_pixel(x_ceil, y_ceil, c);
   //  cout << p1 << "  " << p2 << "  "<< p3 << "  " << p4 << endl;
    q1 = (y_ceil-y)*p1 + (y-y_floor)*p3;
    q2 = (y_ceil-y)*p2 + (y-y_floor)*p4;
    return (x_ceil-x)*q1 + (x-x_floor)*q2;//ide u reg 10
}

k_t nn_interpolate(const Image& img, floor_ceil_t x, floor_ceil_t y, uint8_t c)
{   
   // cout << img.get_pixel(std::round(x), std::round(y), c) <<endl;
    return img.get_pixel(std::round(x), std::round(y), c);//ide u reg 10
}

