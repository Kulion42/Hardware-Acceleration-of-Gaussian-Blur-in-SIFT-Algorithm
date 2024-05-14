#include "function.hpp"


using namespace std;
using namespace sc_dt;


ScaleSpacePyramid generate_gaussian_pyramid(const Image& img, sigma_base_diff_t sigma_min,
                                            uint8_t num_octaves, uint8_t scales_per_octave)
{

    // assume initial sigma is 1.0 (after resizing) and smooth
    // the image with sigma_diff to reach requried base_sigma
   sigma_base_diff_t base_sigma;
   base_sigma = sigma_min / MIN_PIX_DIST;
   Image base_img = resize(img, img.width*2, img.height*2, Interpolation::BILINEAR);
  

    
    sigma_base_diff_t sigma_diff;
    sigma_diff = std::sqrt(base_sigma*base_sigma - 1.0f);
    
    
    base_img = gaussian_blur(base_img, sigma_diff);


    uint8_t imgs_per_octave = scales_per_octave + 3;

    // determine sigma values for bluring
    k_t k;
    k = std::pow(2, 1.0/scales_per_octave);
    std::vector<sigma_prev_total_t> sigma_vals {base_sigma};
    for (uint8_t i = 1; i < imgs_per_octave; i++) {
   	sigma_prev_total_t sigma_prev, sigma_total;
        sigma_prev = base_sigma * std::pow(k, i-1);
        sigma_total = k * sigma_prev;
        sigma_vals.push_back(std::sqrt(sigma_total*sigma_total - sigma_prev*sigma_prev));
		//cout << sigma_vals[i] <<endl;
		
    }
    // create a scale space pyramid of gaussian images
    // images in each octave are half the size of images in the previous one
    ScaleSpacePyramid pyramid = {
        num_octaves,
        imgs_per_octave,
        std::vector<Image>(num_octaves*imgs_per_octave) //zamenio sam da bude 1D
    };
    for (uint8_t i = 0; i < num_octaves; i++) {
      //pyramid.octaves[i].reserve(imgs_per_octave);
      pyramid.images[i*imgs_per_octave] = (base_img); //obrisao std::move(base_img)
      
      for(uint8_t j = 1; j < imgs_per_octave; j++){  
          
          const Image& prev_img = pyramid.images[i*imgs_per_octave + (j-1)];
        pyramid.images[i*imgs_per_octave + j] = (gaussian_blur(prev_img, sigma_vals[j])); //std::move(base_img)
          
  
          /*
          for (int k = 1; k < sigma_vals.size(); k++) {
              const Image& prev_img = pyramid.octaves[i].back();
              pyramid.octaves[i].push_back(gaussian_blur(prev_img, sigma_vals[j]));
          }
          
          */
                 
      }
          
          // prepare base image for next octave
          const Image& next_base_img = pyramid.images[i*imgs_per_octave + (imgs_per_octave - 3)];
          base_img = resize(next_base_img, next_base_img.width/2, next_base_img.height/2, Interpolation::NEAREST);
         

  
    }
    
    return pyramid;
}


Image gaussian_blur(const Image& img, sigma_prev_total_t sigma)
{
    assert(img.channels == 1);

    int8_t size = std::ceil(6 * sigma);
  
    if (size % 2 == 0)
        size++;
       
    int8_t center = size / 2;
    
    Image kernel(size, 1, 1);
    sigma_prev_total_t sum = 0;
        for (int8_t k = -size/2; k <= size/2; k++) {
        k_t val = std::exp(-(k*k) / (2*sigma*sigma));
        
        kernel.set_pixel(center+k, 0, 0, val);
        sum += val;
    }
 //  cout << endl;
    for (uint8_t k = 0; k < size; k++)
        kernel.data[k] /= sum;

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
        }
    }
    // convolve horizontal
    for (uint16_t x = 0; x < img.width; x++) {
        for (uint16_t y = 0; y < img.height; y++) {
            num_t sum = 0;
            for (uint8_t k = 0; k < size; k++) {
                int8_t dx = -center + k;
                sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                 //cout << sum << endl;
            }
            filtered.set_pixel(x, y, 0, sum);
        }
    }
    return filtered;
}

Image resize(const Image& orig, uint16_t new_w, uint16_t new_h, Interpolation method) 
{
    Image resized(new_w, new_h, orig.channels);
    k_t value = 0;
 
    for (uint16_t x = 0; x < new_w; x++) {
        for (uint16_t y = 0; y < new_h; y++) {
            for (uint8_t c = 0; c < resized.channels; c++) {
            	floor_ceil_t old_x, old_y;
                 old_x = map_coordinate(orig.width, new_w, x);
                // cout << old_x <<endl;
		         
                 old_y = map_coordinate(orig.height, new_h, y);
              //  cout << old_y <<endl;
                
                if (method == Interpolation::BILINEAR)
                    value = bilinear_interpolate(orig, old_x, old_y, c);
                else if (method == Interpolation::NEAREST)
                    value = nn_interpolate(orig, old_x, old_y, c);     
                
                   // cout << value << endl;
                resized.set_pixel(x, y, c, value);
            }
        }
    }
    return resized;
}
k_t bilinear_interpolate(const Image& img,  floor_ceil_t x, floor_ceil_t y, uint8_t c)
{
    k_t p1, p2, p3, p4, q1, q2;
    //float p1, p2, p3, p4, q1, q2;
    floor_ceil_t x_floor = std::floor(x), y_floor = std::floor(y);
    floor_ceil_t x_ceil = x_floor + 1, y_ceil = y_floor + 1;
    p1 = img.get_pixel(x_floor, y_floor, c);
    p2 = img.get_pixel(x_ceil, y_floor, c);
    p3 = img.get_pixel(x_floor, y_ceil, c);
    p4 = img.get_pixel(x_ceil, y_ceil, c);
    q1 = (y_ceil-y)*p1 + (y-y_floor)*p3;
    q2 = (y_ceil-y)*p2 + (y-y_floor)*p4;
    return (x_ceil-x)*q1 + (x-x_floor)*q2;
}

k_t nn_interpolate(const Image& img, floor_ceil_t x, floor_ceil_t y, uint8_t c)
{
    return img.get_pixel(std::round(x), std::round(y), c);
}

floor_ceil_t map_coordinate(floor_ceil_t new_max, floor_ceil_t current_max, floor_ceil_t coord)
{
    floor_ceil_t a = new_max / current_max;
    floor_ceil_t b = -0.5 + a*0.5;
   
    return a*coord + b;
}
