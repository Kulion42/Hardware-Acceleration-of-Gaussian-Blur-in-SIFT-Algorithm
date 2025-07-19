#ifndef IMAGE_H
#define IMAGE_H
#include <string>
#include "sc_types.hpp"

enum Interpolation {BILINEAR, NEAREST};

struct Image {
    explicit Image(std::string file_path);
    Image(int w, int h, int c);
    Image();
    ~Image();
    Image(const Image& other);
    Image& operator=(const Image& other);
    Image(Image&& other);
    Image& operator=(Image&& other);
    int width;
    int height;
    int channels;
    int size;
    float *data;
    bool save(std::string file_path);
    void set_pixel(int x, int y, int c, float val);
    float get_pixel(int x, int y, int c) const;
    void clamp();
    Image resize(int new_w, int new_h, Interpolation method = BILINEAR) const;
    
};

float bilinear_interpolate(const Image& img,  float x, float y, int c);
float nn_interpolate(const Image& img, float x, float y, int c);

Image rgb_to_grayscale(const Image& img);
Image grayscale_to_rgb(const Image& img);

void draw_point(Image& img, int x, int y, int size=3);

float map_coordinate(float new_max, float current_max, float coord);


#endif
