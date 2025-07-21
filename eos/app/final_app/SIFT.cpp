#include "SIFT.hpp"

#include "app_functions.hpp"

std::vector<Keypoint> find_keypoints_and_descriptors(const Image& img, int num_of_parts,
                                                     int num_octaves, int scales_per_octave, 
                                                     float contrast_thresh, float edge_thresh, 
                                                     float lambda_ori, float lambda_desc)
{

    assert(img.channels == 1 || img.channels == 3);

    const Image& input = img.channels == 1 ? img : rgb_to_grayscale(img);

    int imgs_per_octave = scales_per_octave + 3;

    const Image& resized_input = input.resize(input.width*2, input.height*2, Interpolation::BILINEAR);

    const std::vector<Image> resized_part = image_partitions(resized_input);
    std::vector<std::vector<Image>> gaussian_pyramid_vector(num_of_parts, std::vector<Image>(num_octaves * imgs_per_octave));

    // Instance of ScaleSpacePyramid
    ScaleSpacePyramid gaussian_pyramid = {
        num_octaves,
        imgs_per_octave,
        std::vector<Image>(num_octaves * imgs_per_octave)
    }; 

    for (int i = 0; i < num_of_parts; i++){
        std::vector<Image> tmp = generate_gaussian_pyramid_vector(resized_part[i], i); 
        for (int j = 0; j < num_octaves * imgs_per_octave; j++){
            gaussian_pyramid_vector[i][j] = tmp[j];  
        } 
    }
    
    gaussian_pyramid.images = combine_partitions(gaussian_pyramid_vector);  
    
    ScaleSpacePyramid dog_pyramid = generate_dog_pyramid(gaussian_pyramid);
    std::vector<Keypoint> tmp_kps = find_keypoints(dog_pyramid, contrast_thresh, edge_thresh);
    ScaleSpacePyramid grad_pyramid = generate_gradient_pyramid(gaussian_pyramid);
    
    std::vector<Keypoint> kps;

    for (Keypoint& kp_tmp : tmp_kps) {
        std::vector<float> orientations = find_keypoint_orientations(kp_tmp, grad_pyramid,
                                                                     lambda_ori, lambda_desc);
        for (float theta : orientations) {
            Keypoint kp = kp_tmp;
            compute_keypoint_descriptor(kp, theta, grad_pyramid, lambda_desc);
            kps.push_back(kp);
        }
    }

    return kps;
}

std::vector<Image> generate_gaussian_pyramid_vector(const Image& img, int img_num, float sigma_min, int num_of_parts,
                                             int num_octaves, int scales_per_octave)
{
    assert(img.channels == 1);
  
    int offset_up, offset_down;
    
    if (img_num == 0){
        offset_up = 0;
        offset_down = OFFSET_UP_DOWN;
    }
    else if (img_num == num_of_parts -1){
        offset_up = OFFSET_UP_DOWN;
        offset_down = 0;
    }
    else{
        offset_up = OFFSET_UP_DOWN;
        offset_down = OFFSET_UP_DOWN;
    }
    
    write_hard(RESET_REG_OFFSET, 1);
    while (true) 
    {
        std::optional<uint16_t> ready = read_hard(READY_REG_OFFSET);
        if (ready && ready.value()) break;
    }


    write_hard(IMG_WIDTH_REG_OFFSET, img.width);
    write_hard(IMG_HEIGHT_REG_OFFSET, img.height);

    // DEBUG PART
    // Image start_image(img.width, img.height, 1);
    // write_bram(img);
    // read_bram(start_image);
    // start_image.save("start_image.jpg");

    write_hard(IMG_OFFSET_UP_REG_OFFSET, offset_up); 
    write_hard(IMG_OFFSET_DOWN_REG_OFFSET, offset_down);
    write_hard(IMG_OCTAVE_NUM_REG_OFFSET, 0);

    write_bram(img);
	
	write_hard(START_REG_OFFSET, 1);	
    while (true) 
    {
    std::optional<uint16_t> ready = read_hard(READY_REG_OFFSET);
    if (ready && ready.value()) break;
    }

    Image base_img(img.width, img.height-offset_up-offset_down, 1);

    read_bram(base_img);

    // DEBUG PART
    // base_img.save("base_image.jpg");

    offset_up = 0;
    offset_down = 0;
    
    int imgs_per_octave = scales_per_octave + 3;
     
    std::vector<Image> pyramid_images(num_octaves*imgs_per_octave); 
        
    for(int i = 0; i < num_octaves; i++) 
    { 
         
      pyramid_images[i*imgs_per_octave] = (base_img);
        
      for(int j = 1; j < imgs_per_octave; j++)
      {  
          const Image& prev_img = pyramid_images[i*imgs_per_octave + (j-1)];
          Image tmp (prev_img.width, prev_img.height, prev_img.channels);
          
            write_hard(RESET_REG_OFFSET, 1);
            while (true) 
            {
                std::optional<uint16_t> ready = read_hard(READY_REG_OFFSET);
                if (ready && ready.value()) break;
            }

            write_hard(IMG_WIDTH_REG_OFFSET, prev_img.width);
            write_hard(IMG_HEIGHT_REG_OFFSET, prev_img.height);
            write_hard(IMG_OFFSET_UP_REG_OFFSET, offset_up); 
            write_hard(IMG_OFFSET_DOWN_REG_OFFSET, offset_down);
            write_hard(IMG_OCTAVE_NUM_REG_OFFSET, j);

                
            write_hard(START_REG_OFFSET, 1);
            // std::cout << "Waiting for IP to finish." << std::endl;	
            while (true) 
            {
            std::optional<uint16_t> ready = read_hard(READY_REG_OFFSET);
            if (ready && ready.value()) break;
            }
	        
	        read_bram(tmp);
        
            pyramid_images[i*imgs_per_octave + j] = tmp;
        }
      
        const Image& next_base_img = pyramid_images[i*imgs_per_octave + (imgs_per_octave - 3)];
        base_img = next_base_img.resize(next_base_img.width/2, next_base_img.height/2, Interpolation::NEAREST);

        write_bram(base_img);
    }

    return pyramid_images;
}

ScaleSpacePyramid generate_dog_pyramid(const ScaleSpacePyramid& img_pyramid)
{
    ScaleSpacePyramid dog_pyramid = {
        img_pyramid.num_octaves,
        img_pyramid.imgs_per_octave - 1,
        std::vector<Image>(img_pyramid.num_octaves*(img_pyramid.imgs_per_octave-1))
    };
    for (int i = 0; i < dog_pyramid.num_octaves; i++) {
    
        //dog_pyramid.octaves[i].reserve(dog_pyramid.imgs_per_octave);
        for (int j = 1; j < img_pyramid.imgs_per_octave; j++) {
            Image diff = img_pyramid.images[i*img_pyramid.imgs_per_octave + j];
            for (int pix_idx = 0; pix_idx < diff.size; pix_idx++) {
                diff.data[pix_idx] -= img_pyramid.images[i*img_pyramid.imgs_per_octave + (j - 1)].data[pix_idx];
                
            }
            dog_pyramid.images[i*dog_pyramid.imgs_per_octave + (j-1)] = diff;
        }
    }

    return dog_pyramid;
}

vector<Keypoint> find_keypoints(const ScaleSpacePyramid& dog_pyramid, float contrast_thresh,
                                     float edge_thresh)
{
    std::vector<Keypoint> keypoints;
    for (int i = 0; i < dog_pyramid.num_octaves; i++) {
        
        //const std::vector<Image>& octave = dog_pyramid.images[i];
        //Treba kopirati celu oktavu iz 1D niza, npr 0-5 element, 6-11 itd.
        
        //const std::vector<Image>& octave; Imam problem sa ovim
        
        auto start_iterator = dog_pyramid.images.begin() + i*dog_pyramid.imgs_per_octave;
        auto end_iterator = start_iterator + 5; //exclusive je... ne ide 4 nego 5
        
        const std::vector<Image>& octave = std::vector<Image>(start_iterator, end_iterator);
        
        for (int j = 1; j < dog_pyramid.imgs_per_octave-1; j++) {
              
            const Image& img = octave[j];
            for (int x = 1; x < img.width-1; x++) {
                for (int y = 1; y < img.height-1; y++) {
                    if (std::abs(img.get_pixel(x, y, 0)) < 0.8*contrast_thresh) {
                        continue;
                    }
                    if (point_is_extremum(octave, j, x, y)) {
                        Keypoint kp = {x, y, i, j, -1, -1, -1, -1};
                        bool kp_is_valid = refine_or_discard_keypoint(kp, octave, contrast_thresh,
                                                                      edge_thresh);
                        if (kp_is_valid) {
                            keypoints.push_back(kp);
                        }
                    }
                }
            }
        }
    }
    return keypoints;
}

ScaleSpacePyramid generate_gradient_pyramid(const ScaleSpacePyramid& pyramid)
{
    ScaleSpacePyramid grad_pyramid = {
        pyramid.num_octaves,
        pyramid.imgs_per_octave,
        std::vector<Image>(pyramid.num_octaves*pyramid.imgs_per_octave)
    };
    for (int i = 0; i < pyramid.num_octaves; i++) {
    
        //grad_pyramid.octaves[i].reserve(grad_pyramid.imgs_per_octave);
        
        int width = pyramid.images[i*pyramid.imgs_per_octave].width;
        int height = pyramid.images[i*pyramid.imgs_per_octave].height;
        for (int j = 0; j < pyramid.imgs_per_octave; j++) {
            Image grad(width, height, 2);
            float gx, gy;
            for (int x = 1; x < grad.width-1; x++) {
                for (int y = 1; y < grad.height-1; y++) {
                    gx = (pyramid.images[i*pyramid.imgs_per_octave + j].get_pixel(x+1, y, 0)
                         -pyramid.images[i*pyramid.imgs_per_octave + j].get_pixel(x-1, y, 0)) * 0.5;
                    grad.set_pixel(x, y, 0, gx);
                    gy = (pyramid.images[i*pyramid.imgs_per_octave + j].get_pixel(x, y+1, 0)
                         -pyramid.images[i*pyramid.imgs_per_octave + j].get_pixel(x, y-1, 0)) * 0.5;
                    grad.set_pixel(x, y, 1, gy);
                }
            }
            grad_pyramid.images[i*pyramid.imgs_per_octave + j] = grad;
        }
    }
    return grad_pyramid;
}

vector<float> find_keypoint_orientations(Keypoint& kp, 
                                              const ScaleSpacePyramid& grad_pyramid,
                                              float lambda_ori, float lambda_desc)
{
    float pix_dist = MIN_PIX_DIST * std::pow(2, kp.octave);
    const Image& img_grad = grad_pyramid.images[kp.octave*grad_pyramid.imgs_per_octave + kp.scale]; //Menjao na 1D, ovo nisam siguran kako

    // discard kp if too close to image borders 
    float min_dist_from_border = std::min({kp.x, kp.y, pix_dist*img_grad.width-kp.x,
                                           pix_dist*img_grad.height-kp.y});
    if (min_dist_from_border <= std::sqrt(2)*lambda_desc*kp.sigma) {
        return {};
    }

    float hist[N_BINS] = {};
    int bin;
    float gx, gy, grad_norm, weight, theta;
    float patch_sigma = lambda_ori * kp.sigma;
    float patch_radius = 3 * patch_sigma;
    int x_start = std::round((kp.x - patch_radius)/pix_dist);
    int x_end = std::round((kp.x + patch_radius)/pix_dist);
    int y_start = std::round((kp.y - patch_radius)/pix_dist);
    int y_end = std::round((kp.y + patch_radius)/pix_dist);

    // accumulate gradients in orientation histogram
    for (int x = x_start; x <= x_end; x++) {
        for (int y = y_start; y <= y_end; y++) {
            gx = img_grad.get_pixel(x, y, 0);
            gy = img_grad.get_pixel(x, y, 1);
            grad_norm = std::sqrt(gx*gx + gy*gy);
            weight = std::exp(-(std::pow(x*pix_dist-kp.x, 2)+std::pow(y*pix_dist-kp.y, 2))
                              /(2*patch_sigma*patch_sigma));
            theta = std::fmod(std::atan2(gy, gx)+2*M_PI, 2*M_PI);
            bin = (int)std::round(N_BINS/(2*M_PI)*theta) % N_BINS;
            hist[bin] += weight * grad_norm;
        }
    }

    smooth_histogram(hist);

    // extract reference orientations
    float ori_thresh = 0.8, ori_max = 0;
    std::vector<float> orientations;
    for (int j = 0; j < N_BINS; j++) {
        if (hist[j] > ori_max) {
            ori_max = hist[j];
        }
    }
    for (int j = 0; j < N_BINS; j++) {
        if (hist[j] >= ori_thresh * ori_max) {
            float prev = hist[(j-1+N_BINS)%N_BINS], next = hist[(j+1)%N_BINS];
            if (prev > hist[j] || next > hist[j])
                continue;
            float theta = 2*M_PI*(j+1)/N_BINS + M_PI/N_BINS*(prev-next)/(prev-2*hist[j]+next);
            orientations.push_back(theta);
        }
    }
    return orientations;
}

void compute_keypoint_descriptor(Keypoint& kp, float theta,
                                 const ScaleSpacePyramid& grad_pyramid,
                                 float lambda_desc)
{
    float pix_dist = MIN_PIX_DIST * std::pow(2, kp.octave);
    const Image& img_grad = grad_pyramid.images[kp.octave * grad_pyramid.imgs_per_octave + kp.scale]; //Ovo nisam siguran
    float histograms[N_HIST][N_HIST][N_ORI] = {0};

    //find start and end coords for loops over image patch
    float half_size = std::sqrt(2)*lambda_desc*kp.sigma*(N_HIST+1.)/N_HIST;
    int x_start = std::round((kp.x-half_size) / pix_dist);
    int x_end = std::round((kp.x+half_size) / pix_dist);
    int y_start = std::round((kp.y-half_size) / pix_dist);
    int y_end = std::round((kp.y+half_size) / pix_dist);

    float cos_t = std::cos(theta), sin_t = std::sin(theta);
    float patch_sigma = lambda_desc * kp.sigma;
    //accumulate samples into histograms
    for (int m = x_start; m <= x_end; m++) {
        for (int n = y_start; n <= y_end; n++) {
            // find normalized coords w.r.t. kp position and reference orientation
            float x = ((m*pix_dist - kp.x)*cos_t
                      +(n*pix_dist - kp.y)*sin_t) / kp.sigma;
            float y = (-(m*pix_dist - kp.x)*sin_t
                       +(n*pix_dist - kp.y)*cos_t) / kp.sigma;

            // verify (x, y) is inside the description patch
            if (std::max(std::abs(x), std::abs(y)) > lambda_desc*(N_HIST+1.)/N_HIST)
                continue;

            float gx = img_grad.get_pixel(m, n, 0), gy = img_grad.get_pixel(m, n, 1);
            float theta_mn = std::fmod(std::atan2(gy, gx)-theta+4*M_PI, 2*M_PI);
            float grad_norm = std::sqrt(gx*gx + gy*gy);
            float weight = std::exp(-(std::pow(m*pix_dist-kp.x, 2)+std::pow(n*pix_dist-kp.y, 2))
                                    /(2*patch_sigma*patch_sigma));
            float contribution = weight * grad_norm;

            update_histograms(histograms, x, y, contribution, theta_mn, lambda_desc);
        }
    }

    // build feature vector (descriptor) from histograms
    hists_to_vec(histograms, kp.descriptor);
}

Image draw_keypoints(const Image& img, const std::vector<Keypoint>& kps)
{
    Image res(img);
    if (img.channels == 1) {
        res = grayscale_to_rgb(res);
    }
    for (auto& kp : kps) {
        draw_point(res, kp.x, kp.y, 5);
    }
    return res;
}

//--------------------------------------------------------------------



void hists_to_vec(float histograms[N_HIST][N_HIST][N_ORI], std::array<uint8_t, 128>& feature_vec)
{
    int size = N_HIST*N_HIST*N_ORI;
    float *hist = reinterpret_cast<float *>(histograms);

    float norm = 0;
    for (int i = 0; i < size; i++) {
        norm += hist[i] * hist[i];
    }
    norm = std::sqrt(norm);
    float norm2 = 0;
    for (int i = 0; i < size; i++) {
        hist[i] = std::min(hist[i], 0.2f*norm);
        norm2 += hist[i] * hist[i];
    }
    norm2 = std::sqrt(norm2);
    for (int i = 0; i < size; i++) {
        float val = std::floor(512*hist[i]/norm2);
        feature_vec[i] = std::min((int)val, 255);
    }
}

void update_histograms(float hist[N_HIST][N_HIST][N_ORI], float x, float y,
                       float contrib, float theta_mn, float lambda_desc)
{
    float x_i, y_j;
    for (int i = 1; i <= N_HIST; i++) {
        x_i = (i-(1+(float)N_HIST)/2) * 2*lambda_desc/N_HIST;
        if (std::abs(x_i-x) > 2*lambda_desc/N_HIST)
            continue;
        for (int j = 1; j <= N_HIST; j++) {
            y_j = (j-(1+(float)N_HIST)/2) * 2*lambda_desc/N_HIST;
            if (std::abs(y_j-y) > 2*lambda_desc/N_HIST)
                continue;
            
            float hist_weight = (1 - N_HIST*0.5/lambda_desc*std::abs(x_i-x))
                               *(1 - N_HIST*0.5/lambda_desc*std::abs(y_j-y));

            for (int k = 1; k <= N_ORI; k++) {
                float theta_k = 2*M_PI*(k-1)/N_ORI;
                float theta_diff = std::fmod(theta_k-theta_mn+2*M_PI, 2*M_PI);
                if (std::abs(theta_diff) >= 2*M_PI/N_ORI)
                    continue;
                float bin_weight = 1 - N_ORI*0.5/M_PI*std::abs(theta_diff);
                hist[i-1][j-1][k-1] += hist_weight*bin_weight*contrib;
            }
        }
    }
}


void smooth_histogram(float hist[N_BINS])
{
    float tmp_hist[N_BINS];
    for (int i = 0; i < 6; i++) {
        for (int j = 0; j < N_BINS; j++) {
            int prev_idx = (j-1+N_BINS)%N_BINS;
            int next_idx = (j+1)%N_BINS;
            tmp_hist[j] = (hist[prev_idx] + hist[j] + hist[next_idx]) / 3;
        }
        for (int j = 0; j < N_BINS; j++) {
            hist[j] = tmp_hist[j];
        }
    }
}

bool point_is_extremum(const std::vector<Image>& octave, int scale, int x, int y)
{
    const Image& img = octave[scale];
    const Image& prev = octave[scale-1];
    const Image& next = octave[scale+1];

    bool is_min = true, is_max = true;
    float val = img.get_pixel(x, y, 0), neighbor;

    for (int dx : {-1,0,1}) {
        for (int dy : {-1,0,1}) {
            neighbor = prev.get_pixel(x+dx, y+dy, 0);
            if (neighbor > val) is_max = false;
            if (neighbor < val) is_min = false;

            neighbor = next.get_pixel(x+dx, y+dy, 0);
            if (neighbor > val) is_max = false;
            if (neighbor < val) is_min = false;

            neighbor = img.get_pixel(x+dx, y+dy, 0);
            if (neighbor > val) is_max = false;
            if (neighbor < val) is_min = false;

            if (!is_min && !is_max) return false;
        }
    }
    return true;
}

std::tuple<float, float, float> fit_quadratic(Keypoint& kp,
                                              const std::vector<Image>& octave,
                                              int scale)
{
    const Image& img = octave[scale];
    const Image& prev = octave[scale-1];
    const Image& next = octave[scale+1];

    float g1, g2, g3;
    float h11, h12, h13, h22, h23, h33;
    int x = kp.i, y = kp.j;

    // gradient 
    g1 = (next.get_pixel(x, y, 0) - prev.get_pixel(x, y, 0)) * 0.5;
    g2 = (img.get_pixel(x+1, y, 0) - img.get_pixel(x-1, y, 0)) * 0.5;
    g3 = (img.get_pixel(x, y+1, 0) - img.get_pixel(x, y-1, 0)) * 0.5;

    // hessian
    h11 = next.get_pixel(x, y, 0) + prev.get_pixel(x, y, 0) - 2*img.get_pixel(x, y, 0);
    h22 = img.get_pixel(x+1, y, 0) + img.get_pixel(x-1, y, 0) - 2*img.get_pixel(x, y, 0);
    h33 = img.get_pixel(x, y+1, 0) + img.get_pixel(x, y-1, 0) - 2*img.get_pixel(x, y, 0);
    h12 = (next.get_pixel(x+1, y, 0) - next.get_pixel(x-1, y, 0)
          -prev.get_pixel(x+1, y, 0) + prev.get_pixel(x-1, y, 0)) * 0.25;
    h13 = (next.get_pixel(x, y+1, 0) - next.get_pixel(x, y-1, 0)
          -prev.get_pixel(x, y+1, 0) + prev.get_pixel(x, y-1, 0)) * 0.25;
    h23 = (img.get_pixel(x+1, y+1, 0) - img.get_pixel(x+1, y-1, 0)
          -img.get_pixel(x-1, y+1, 0) + img.get_pixel(x-1, y-1, 0)) * 0.25;
    
    // invert hessian
    float hinv11, hinv12, hinv13, hinv22, hinv23, hinv33;
    float det = h11*h22*h33 - h11*h23*h23 - h12*h12*h33 + 2*h12*h13*h23 - h13*h13*h22;
    hinv11 = (h22*h33 - h23*h23) / det;
    hinv12 = (h13*h23 - h12*h33) / det;
    hinv13 = (h12*h23 - h13*h22) / det;
    hinv22 = (h11*h33 - h13*h13) / det;
    hinv23 = (h12*h13 - h11*h23) / det;
    hinv33 = (h11*h22 - h12*h12) / det;

    // find offsets of the interpolated extremum from the discrete extremum
    float offset_s = -hinv11*g1 - hinv12*g2 - hinv13*g3;
    float offset_x = -hinv12*g1 - hinv22*g2 - hinv23*g3;
    float offset_y = -hinv13*g1 - hinv23*g3 - hinv33*g3;

    float interpolated_extrema_val = img.get_pixel(x, y, 0)
                                   + 0.5*(g1*offset_s + g2*offset_x + g3*offset_y);
    kp.extremum_val = interpolated_extrema_val;
    return {offset_s, offset_x, offset_y};
}

bool point_is_on_edge(const Keypoint& kp, const std::vector<Image>& octave, float edge_thresh)
{
    const Image& img = octave[kp.scale];
    float h11, h12, h22;
    int x = kp.i, y = kp.j;
    h11 = img.get_pixel(x+1, y, 0) + img.get_pixel(x-1, y, 0) - 2*img.get_pixel(x, y, 0);
    h22 = img.get_pixel(x, y+1, 0) + img.get_pixel(x, y-1, 0) - 2*img.get_pixel(x, y, 0);
    h12 = (img.get_pixel(x+1, y+1, 0) - img.get_pixel(x+1, y-1, 0)
          -img.get_pixel(x-1, y+1, 0) + img.get_pixel(x-1, y-1, 0)) * 0.25;

    float det_hessian = h11*h22 - h12*h12;
    float tr_hessian = h11 + h22;
    float edgeness = tr_hessian*tr_hessian / det_hessian;

    if (edgeness > std::pow(edge_thresh+1, 2)/edge_thresh)
        return true;
    else
        return false;
}

void find_input_img_coords(Keypoint& kp, float offset_s, float offset_x, float offset_y,
                                   float sigma_min,
                                   float min_pix_dist, int n_spo)
{
    kp.sigma = std::pow(2, kp.octave) * sigma_min * std::pow(2, (offset_s+kp.scale)/n_spo);
    kp.x = min_pix_dist * std::pow(2, kp.octave) * (offset_x+kp.i);
    kp.y = min_pix_dist * std::pow(2, kp.octave) * (offset_y+kp.j);
}

bool refine_or_discard_keypoint(Keypoint& kp, const std::vector<Image>& octave,
                                float contrast_thresh, float edge_thresh)
{
    int k = 0;
    bool kp_is_valid = false; 
    while (k++ < MAX_REFINEMENT_ITERS) {
        auto [offset_s, offset_x, offset_y] = fit_quadratic(kp, octave, kp.scale);

        float max_offset = std::max({std::abs(offset_s),
                                     std::abs(offset_x),
                                     std::abs(offset_y)});
        // find nearest discrete coordinates
        kp.scale += std::round(offset_s);
        kp.i += std::round(offset_x);
        kp.j += std::round(offset_y);
        if (kp.scale >= octave.size()-1 || kp.scale < 1)
            break;

        bool valid_contrast = std::abs(kp.extremum_val) > contrast_thresh;
        if (max_offset < 0.6 && valid_contrast && !point_is_on_edge(kp, octave, edge_thresh)) {
            find_input_img_coords(kp, offset_s, offset_x, offset_y);
            kp_is_valid = true;
            break;
        }
    }
    return kp_is_valid;
}

std::vector<Image> image_partitions(const Image& img, int num_of_parts)
{
    std::vector<Image> img_part(num_of_parts);
    
    std::string resize = "resized_part_";
    char numstr[21];
    std::string res;
        
        Image first_part(img.width, (img.height/num_of_parts) + OFFSET_UP_DOWN , 1);
            for (int x = 0; x < img.width; x++) {
                for (int y = 0; y < (img.height/num_of_parts) + OFFSET_UP_DOWN; y++) {
                    float val = img.get_pixel(x, y, 0);
                    first_part.set_pixel(x, y, 0,  val);                                    
                }
            }    
            img_part[0] = (first_part); 
            
           /*sprintf(numstr, "%d", 1);
            res = resize + numstr + ".jpg";
            first_part.save(res) ;*/
               
            for (int i = 1; i < num_of_parts -1; i++) {
                Image partitions(img.width, (img.height/num_of_parts) + 2 * OFFSET_UP_DOWN , 1);
                for (int x = 0; x < img.width; x++) {
                    for (int y = i*(img.height/num_of_parts) -OFFSET_UP_DOWN; y < (i+1)*(img.height/num_of_parts) + OFFSET_UP_DOWN; y++) {
                        float val = img.get_pixel(x, y, 0);
                        partitions.set_pixel(x, y - i*(img.height/num_of_parts) +OFFSET_UP_DOWN, 0,  val);                                    
                    }
                }    
                img_part[i] = (partitions);
                
                /*sprintf(numstr, "%d", i+1);
                res = resize + numstr + ".jpg";
                partitions.save(res) ; */ 
            }

        Image last_part(img.width, (img.height/num_of_parts) +OFFSET_UP_DOWN, 1);
        for (int x = 0; x < img.width; x++) {
        
                 for (int y = (num_of_parts -1)*(img.height/num_of_parts) - OFFSET_UP_DOWN; y < img.height; y++) {
                        float val = img.get_pixel(x, y, 0);
                        last_part.set_pixel(x, y - (num_of_parts -1)*(img.height/num_of_parts) + OFFSET_UP_DOWN, 0, val);                                    
                }
        }   
        img_part[num_of_parts - 1]= (last_part);
           /*  
            sprintf(numstr, "%d", num_of_parts);
            res = resize + numstr + ".jpg";
            last_part.save(res) ; */    
    return img_part;
}


std::vector<Image> combine_partitions(std::vector< std::vector <Image> > img_vec, int num_of_parts, int num_octaves, 
                                                     int scales_per_octave)
{   
    
    int imgs_per_octave = scales_per_octave + 3;
     std::vector<Image> comb_part(num_octaves * imgs_per_octave);
         
        for (int j = 0 ; j < num_octaves * imgs_per_octave; j++){
        
            int fixed_width = img_vec[1][j].width;
            int fixed_height = img_vec[1][j].height;
            
            Image combined(fixed_width, num_of_parts * fixed_height, 1); 
            
            for (int i = 0; i < num_of_parts ; i++){ 

                for (int x = 0; x < img_vec[i][j].width; x++){
                  
                    for (int y= 0; y < img_vec[i][j].height; y++){  

                        float val = img_vec[i][j].get_pixel(x, y, 0);
                        combined.set_pixel(x, i*img_vec[1][j].height + y , 0, val);  
                    }
                       
                } 
            }
          comb_part[j]= (combined);
         /* sprintf(numstr, "%d", j);
          res = resize + numstr + ".jpg";
          combined.save(res) ; */
      } 
     
     return comb_part; 
}
