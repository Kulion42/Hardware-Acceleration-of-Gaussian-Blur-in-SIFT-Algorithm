#include "cpu.hpp"

char **Cpu::input_arguments = nullptr;
int Cpu::argc = 0;


SC_HAS_PROCESS(Cpu);

Cpu::Cpu(sc_core::sc_module_name name, char** strings, int arg_count) : sc_module(name), offset(sc_core::SC_ZERO_TIME)
{
	SC_THREAD(soft);
	SC_REPORT_INFO("Cpu ", "Constructed.");
	
	//prosledjivanje ulaznih parametara
	input_arguments = strings;
	argc = arg_count;
}

Cpu::~Cpu()
{
    SC_REPORT_INFO("Cpu ", "Destroyed.");
}

void Cpu::soft()
{	
	long long offset_value_new = 0;
    long long offset_value_old = 0;
    long long offset_value = 0;
    FILE *fp_frame;
    double fps = 0.0;
    char frame_file[] = "frame_file.txt";
    double fps_avg = 0.0;
    long long offset_avg = 0;


	if (argc != 2) {
        std::cerr << "Usage: ./find_keypoints input.jpg (or .png)\n";
        exit(21);
    }
	
	//smesta pocetnu sliku
	Image img(input_arguments[1]);
	
	//smesta grayscale sliku
	Image grayscale_img(img.width, img.height, img.channels);
    
    /*if(img.height > 256 || img.width > 256)
    {
      std::cerr << "Image can't be bigger than 256x256 pixels.\n";
      exit(21);
    } 
    */
    if(img.channels == 1)
    {
		grayscale_img = img;
	}
	else
	{
		grayscale_img = rgb_to_grayscale(img);
	}
	
	FILE *fp;
	const Image& input = img.channels == 1 ? img : rgb_to_grayscale(img);
    const Image& resized_input = input.resize(input.width*2, input.height*2, Interpolation::BILINEAR);
    int num_octaves = N_OCT;
    int scales_per_octave = N_SPO;
    int imgs_per_octave = scales_per_octave + 3;
    int num_of_parts = N_IP;
    
    const std::vector<Image> resized_part = image_partitions(resized_input /*num_of_parts,*/);

    std::vector< std::vector<Image> >gaussian_pyramid_vector(num_of_parts, std::vector<Image>(num_octaves * imgs_per_octave));
       
    ScaleSpacePyramid gaussian_pyramid = {
        num_octaves,
        imgs_per_octave,
        std::vector<Image>(num_octaves * imgs_per_octave )
        
    }; 

    char res[30];
     strcpy(res, input_arguments[1]);
    char res_cut[20];
    for (int i = 0; i < 20; i++)
        res_cut[i]=res[i + 10];
    std::string output = res_cut;

    fp_frame = fopen(frame_file, "a+");
    if (fp_frame == NULL) {
        std::cerr << "Error opening regression log file.\n";
        exit(1);
    }
    fprintf(fp_frame, "*****************************\n\n");
    fprintf(fp_frame, "Image name: %s\n", output.c_str());
    fprintf(fp_frame, "Image dimensions: %dx%d\n", input.width, input.height);
    for (int i = 0; i < num_of_parts; i++){
       // fprintf(fp_frame, "\n");
        //fprintf(fp_frame, "Image part: %d\n", i);
        //fprintf(fp_frame, "Image dimensions: %dx%d\n", resized_part[i].width, resized_part[i].height);

        std::vector<Image> tmp = generate_gaussian_pyramid_vector(resized_part[i], i); 
            offset_value_new = offset.to_default_time_units();
		    offset_value = offset_value_new - offset_value_old;
	    	offset_value_old = offset_value_new;
	    	fps = 1000000000.0 / offset_value;
        //fprintf(fp_frame, "Time used in Gaussian pyramid generation for this part: %lld us\n", offset_value/1000);
        //fprintf(fp_frame, "fps = %ld\n", (long int)std::floor(fps));
        fps_avg += fps;
        offset_avg += offset_value;
        //fprintf(fp_frame, "\n");
        for (int j = 0; j < num_octaves * imgs_per_octave; j++){
            gaussian_pyramid_vector[i][j] = tmp[j];  
        } 
    }
    fprintf(fp_frame, "Average fps for all parts: %ld\n", (long int)std::floor(fps_avg/num_of_parts));
    fprintf(fp_frame, "Average time for all parts: %lld us\n", offset_avg/(num_of_parts *1000));
    fps_avg = 0.0;
    offset_avg = 0;
    //fprintf(fp_frame, "*****************************\n\n");
    fclose(fp_frame);
    gaussian_pyramid.images = combine_partitions(gaussian_pyramid_vector /*num_of_parts,*/ ) ;  
    	
	ScaleSpacePyramid dog_pyramid = generate_dog_pyramid(gaussian_pyramid);
    std::vector<Keypoint> tmp_kps = find_keypoints(dog_pyramid);
    ScaleSpacePyramid grad_pyramid = generate_gradient_pyramid(gaussian_pyramid);
    
    std::vector<Keypoint> kps;
    
	for (Keypoint& kp_tmp : tmp_kps) 
	{
		std::vector<float> orientations = find_keypoint_orientations(kp_tmp, grad_pyramid);
		for (float theta : orientations) 
		{
            Keypoint kp = kp_tmp;
            compute_keypoint_descriptor(kp, theta, grad_pyramid);
            kps.push_back(kp);
        }
    }

    Image result = draw_keypoints(grayscale_img, kps);

    result.save(output.c_str());
    fp = fopen("log_file.txt", "a+");
    fprintf(fp, "Found %lu keypoints. Ouptup image save as %s\n", kps.size(), output.c_str());
    fclose(fp);

    std::cout << "Found " << kps.size() << " keypoints. Output image is saved as "<< output << "\n";
    
    offset_system += offset;
    
    std::cout << "Time used in whole system is " << offset_system << endl;
        
}

std::vector<Image> Cpu::generate_gaussian_pyramid_vector(const Image& img, int img_num, float sigma_min, int num_of_parts,
                                             int num_octaves, int scales_per_octave)
{
    assert(img.channels == 1);

    float base_sigma = sigma_min / MIN_PIX_DIST;
  
    float sigma_diff = std::sqrt(base_sigma*base_sigma - 1.0f);
  
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
    
    //cout << "IP core register initialization" << endl;
    write_hard(ADDR_RESET, 1);
    while(!read_hard(ADDR_READY));
    write_hard(ADDR_RESET, 0);
    
    write_hard(ADDR_IMG_WIDTH, img.width); 
	write_hard(ADDR_IMG_HEIGHT, img.height);

	write_hard(ADDR_NUM_IMG_OCT, 0); 
	write_hard(ADDR_IMG_OFFSET_UP, offset_up); 
	write_hard(ADDR_IMG_OFFSET_DOWN, offset_down);
	//cout << "IP core registers initialized" << endl;
	//cout << endl;
	//------------------------------------------------
	//cout << "First bram initialzation" << endl;


    for ( int x = 0; x < img.width; x+=2) {    
        for (int y = 0; y < img.height; y++) {
          data_t pix1, pix2, pix3, pix4; 
          pix1= img.get_pixel(x, y, 0);
          if(x +1 < img.width)
          pix2 = img.get_pixel(x+1, y, 0);
          //cout << pix1 << " "<<pix2 << endl;
          write_mem(VP_ADDR_MAIN_BRAM_L  + 2 *(y*img.width + x), pix1, pix2);
        }
    }    
	//cout << "Bram initialized" << endl;
	
	//------------------------------------------------
	//cout << endl;
    write_hard(ADDR_RESET, 1);
    while(!read_hard(ADDR_READY));
    write_hard(ADDR_RESET, 0);
	write_hard(ADDR_START, 1);
	//cout << "IP core activated " << endl;
	//cout << endl;

    write_hard(ADDR_START, 0);
	while(!read_hard(ADDR_READY));
    Image base_img(img.width, img.height-offset_up-offset_down, 1) ; //= gaussian_blur(img, sigma_diff, offset_up, offset_down);

    offset_up = 0;
    offset_down = 0;
    
    int imgs_per_octave = scales_per_octave + 3;
    
    //------------------------------------------------
	// cout << "Saving bram state" << endl;

        for ( int x = 0; x < base_img.width; x+=2) {    
            for (int y = 0; y < base_img.height; y++) {
                  data_t pix1, pix2, pix3, pix4;
                  read_mem(VP_ADDR_MAIN_BRAM_L  + 2 * (y*base_img.width + x), pix1, pix2);                  
                    base_img.set_pixel(x, y, 0, pix1);
                  if(x + 1 < base_img.width)
                    base_img.set_pixel(x+1, y, 0, pix2);
            }
         }
         
   //  cout << "Bram state saved" << endl;
     //cout << endl;
     
 
	//------------------------------------------------ 
    std::vector<Image> pyramid_images(num_octaves*imgs_per_octave); 
        
    for (int i = 0; i < num_octaves; i++) { 
         
      pyramid_images[i*imgs_per_octave] = (base_img);
        
      for(int j = 1; j < imgs_per_octave; j++){  
          
          const Image& prev_img = pyramid_images[i*imgs_per_octave + (j-1)];
          Image tmp (prev_img.width, prev_img.height, prev_img.channels);
          
    //-----------------------------------------------
            write_hard(ADDR_RESET, 1);
            while(!read_hard(ADDR_READY));
            write_hard(ADDR_RESET, 0);
            write_hard(ADDR_IMG_WIDTH, prev_img.width); 
	        write_hard(ADDR_IMG_HEIGHT, prev_img.height);
	        write_hard(ADDR_IMG_OFFSET_UP, offset_up); 
	        write_hard(ADDR_IMG_OFFSET_DOWN, offset_down);     
            write_hard(ADDR_NUM_IMG_OCT, j); 
            
            write_hard(ADDR_START, 1);
	        //cout << "IP core activated " <<  i*(imgs_per_octave-1) + j << endl;
	        //cout << endl;
            write_hard(ADDR_START, 0);
		        
	        while(!read_hard(ADDR_READY));
	        
	//------------------------------------------------
	       // cout << "Saving bram state " << endl;
            for ( int x = 0; x < prev_img.width; x+=2) {
                for (int y = 0; y < prev_img.height; y++) {
                  data_t pix1, pix2, pix3, pix4;
                  read_mem(VP_ADDR_MAIN_BRAM_L  + 2 * (y*prev_img.width + x), pix1, pix2);                  
                  tmp.set_pixel(x, y, 0, pix1);
                  if (x +1 < prev_img.width)
                  tmp.set_pixel(x+1, y, 0, pix2);
                }
            }
             // cout << "Bram state saved" << endl;
	//------------------------------------------------ 
        
       pyramid_images[i*imgs_per_octave + j] = tmp ; //(gaussian_blur(prev_img, sigma_vals[j], offset_up, offset_down)) ;
      }
      
          const Image& next_base_img = pyramid_images[i*imgs_per_octave + (imgs_per_octave - 3)];
          base_img = next_base_img.resize(next_base_img.width/2, next_base_img.height/2, Interpolation::NEAREST);
          
          //  cout << "Next bram initialization" << endl;

          for (int y = 0; y < base_img.height; y++) {
            for ( int x = 0; x < base_img.width; x+=2) {    
                  data_t pix1, pix2; 
                  pix1= base_img.get_pixel(x, y, 0);
                  if(x +1 < base_img.width)
                  pix2 = base_img.get_pixel(x+1, y, 0);
                  
                  write_mem(VP_ADDR_MAIN_BRAM_L  + 2 *(y*base_img.width + x), pix1, pix2);
            }
        }
        //-------------------------------------------------  
    }
    //while(1);
    cout << "Image part "<< img_num << " finished!"<< endl;
    return pyramid_images;
}

ScaleSpacePyramid Cpu::generate_dog_pyramid(const ScaleSpacePyramid& img_pyramid)
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

vector<Keypoint> Cpu::find_keypoints(const ScaleSpacePyramid& dog_pyramid, float contrast_thresh,
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

ScaleSpacePyramid Cpu::generate_gradient_pyramid(const ScaleSpacePyramid& pyramid)
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

vector<float> Cpu::find_keypoint_orientations(Keypoint& kp, 
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

void Cpu::compute_keypoint_descriptor(Keypoint& kp, float theta,
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

Image Cpu::draw_keypoints(const Image& img, const std::vector<Keypoint>& kps)
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



void Cpu::hists_to_vec(float histograms[N_HIST][N_HIST][N_ORI], std::array<uint8_t, 128>& feature_vec)
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

void Cpu::update_histograms(float hist[N_HIST][N_HIST][N_ORI], float x, float y,
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


void Cpu::smooth_histogram(float hist[N_BINS])
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

bool Cpu::point_is_extremum(const std::vector<Image>& octave, int scale, int x, int y)
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

std::tuple<float, float, float> Cpu::fit_quadratic(Keypoint& kp,
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

bool Cpu::point_is_on_edge(const Keypoint& kp, const std::vector<Image>& octave, float edge_thresh)
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

void Cpu::find_input_img_coords(Keypoint& kp, float offset_s, float offset_x, float offset_y,
                                   float sigma_min,
                                   float min_pix_dist, int n_spo)
{
    kp.sigma = std::pow(2, kp.octave) * sigma_min * std::pow(2, (offset_s+kp.scale)/n_spo);
    kp.x = min_pix_dist * std::pow(2, kp.octave) * (offset_x+kp.i);
    kp.y = min_pix_dist * std::pow(2, kp.octave) * (offset_y+kp.j);
}

bool Cpu::refine_or_discard_keypoint(Keypoint& kp, const std::vector<Image>& octave,
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

std::vector<Image> Cpu::image_partitions(const Image& img, int num_of_parts)
{
    std::vector<Image> img_part(num_of_parts);
    
    std::string resize = "resized_part_";
    char numstr[21];
    std::string res;
        
        Image first_part(img.width, (img.height/num_of_parts) + OFFSET_UP_DOWN , 1);
            for (int x = 0; x < img.width; x++) {
                for (int y = 0; y < (img.height/num_of_parts) + OFFSET_UP_DOWN; y++) {
                    data_t val = img.get_pixel(x, y, 0);
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
                        data_t val = img.get_pixel(x, y, 0);
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
                        data_t val = img.get_pixel(x, y, 0);
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


std::vector<Image> Cpu::combine_partitions(std::vector< std::vector <Image> > img_vec, int num_of_parts, int num_octaves, 
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

                        data_t val = img_vec[i][j].get_pixel(x, y, 0);
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

void Cpu::write_hard(sc_dt::sc_uint<64> addr, sc_dt::sc_int<16> val)
{
	pl_t pl;
	unsigned char buf[2];
	toUchar2(buf, val);
	pl.set_address(VP_ADDR_IP_CORE_L + addr);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_WRITE_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	interconnect_socket->b_transport(pl, offset);
}

int Cpu::read_hard(sc_dt::sc_uint<64> addr)
{
	pl_t pl;
	unsigned char buf;
	pl.set_address(VP_ADDR_IP_CORE_L + addr);
	pl.set_data_length(1); 
	pl.set_data_ptr(&buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	interconnect_socket->b_transport(pl, offset);
	return toInt(&buf);
}

void Cpu::write_mem(sc_dt::sc_uint<64> addr, data_t pix1, data_t pix2)
{
    offset += sc_core::sc_time(10*DELAY , sc_core::SC_NS);	
	pl_t pl;
	unsigned char buf[4];
	Fixed_to_Uchar(buf, pix1, pix2);
	pl.set_address(addr);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_WRITE_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	interconnect_socket->b_transport(pl, offset);
}

void Cpu::read_mem(sc_dt::sc_uint<64> addr, data_t& pix1, data_t& pix2)
{
    offset += sc_core::sc_time(10*DELAY , sc_core::SC_NS);	
	pl_t pl;
	unsigned char buf[4];
	pl.set_address(addr);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	interconnect_socket->b_transport(pl, offset);
	Uchar_to_Fixed(buf, pix1, pix2);
}

