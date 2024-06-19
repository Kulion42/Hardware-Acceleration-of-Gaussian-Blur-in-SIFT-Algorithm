#include "ip_core.hpp"


using namespace std;
using namespace sc_core;
using namespace sc_dt;
using namespace tlm;

floor_ceil_t map_coordinate(float new_max, float current_max, float coord)
{
    float a = new_max / current_max;
    float b = -0.5 + a*0.5;
   
    return a*coord + b;
}

SC_HAS_PROCESS(Ip_core);

Ip_core::Ip_core(sc_module_name name):
	sc_module(name),
	ready(1)
	
{
	interconnect_socket.register_b_transport(this, &Ip_core::b_transport);
	
	SC_REPORT_INFO("IP Core", "Constructed.");
}

Ip_hard::~Ip_core()
{
	SC_REPORT_INFO("IP Core", "Destroyed.");
}


void Ip_core::b_transport(pl_t &pl, sc_time &offset)
{
	
	tlm::tlm_command command = pl.get_command();
 	sc_dt::uint64 address = pl.get_address();
	unsigned int length = pl.get_data_length();
 	unsigned char *buffer = pl.get_data_ptr();
 	pl.set_response_status( tlm::TLM_OK_RESPONSE );
 	
	switch(command)
 	{	
 	case tlm::TLM_WRITE_COMMAND:
      		switch(address)
        	{
			case ADDR_IMG_ROWS:
			  img_width = toInt(buffer);  
			  cout << "tmpl_width = " << img_width << endl;
			  break;
			case ADDR_IMG_COLS:
			  img_height = toInt(buffer);
			  cout << "img_height = " << img_height << endl;
			  break;
			case ADDR_IMG_CANS:
			  img_channels = toInt(buffer);
			  cout << "img_channels = " << img_channels << endl;
			  break;
			case ADDR_START:
			  start = toInt(buffer);
			  cout << "start bit" << endl;
			  generate_gaussian_pyramid(const Image& img, sc_time& offset);
			  break;
			default:
			  pl.set_response_status( tlm::TLM_ADDRESS_ERROR_RESPONSE );
			  cout << "Wrong address" << endl;
		}
      		
      		break;
      		
	case tlm::TLM_READ_COMMAND:
		switch(address)
		{
		case ADDR_READY:
		  toUchar(buffer, ready);
		  break;
		default:
		  pl.set_response_status( tlm::TLM_ADDRESS_ERROR_RESPONSE );
		}
		
		break;
	default:
		pl.set_response_status( tlm::TLM_COMMAND_ERROR_RESPONSE );
		cout << "Wrong command" << endl;
	}
	
	offset += sc_time(DELAY, SC_NS);
}

Ip_core::ScaleSpacePyramid generate_gaussian_pyramid(const Image& img, sc_time& hard_offset)
{

   pl_t pl;
   sigma_base_diff_t base_sigma;
   base_sigma = SIGMA_MIN / MIN_PIX_DIST;
   sc_uint<8> num_octaves=N_OCT;
   sc_uint<8> scales_per_octave=N_SPO
   sc_uint<16> bram_cnt = 0; 
   
   if (start == 1 && ready == 1){
        cout << "IP_core started" << endl;
        ofset+=sc_time(DELAY, SC_NS);
   }

    else if (start == 0 && ready == 0 ){
    //Start with work
    cout << "Generation of gaussian pyramid"<<endl;
    
    
    sigma_base_diff_t sigma_diff;
    sigma_diff = std::sqrt(base_sigma*base_sigma - 1.0f);
    
    

    assert(img.channels == 1);

    sc_int<8> size = std::ceil(6 * sigma_diff);
  
    if (size % 2 == 0)
        size++;
      
    sc_int<8> center = size / 2;

    Image kernel(size, 1, 1);
    sigma_prev_total_t sum = 0;
        for (sc_int<8> k = -size/2; k <= size/2; k++) {
        k_t val = std::exp(-(k*k) / (2*sigma_diff*sigma_diff));

        write_mem(kernel, center + k, val); //kernel.set_pixel(center+k, 0, 0, val);
        sum += val;
        ofset+=sc_time(DELAY, SC_NS);
    }

    for (sc_int<8> k = 0; k < size; k++){
    
          data_t tmp = read_mem(kernel, k);
          write_mem(kernel, k, tmp/sum); 
          ofset+=sc_time(DELAY, SC_NS);     //kernel.data[k] /= sum;
        }
    Image tmp(img.width, base_img.height, 1);
    Image filtered(img.width, img.height, 1);

    // convolve vertical
    for (sc_int<16> x = 0; x < img_width; x++) {
        for (sc_int<16> y = 0; y < img_height; y++) {
            num_t sum = 0;
            for (sc_int<8> k = 0; k < size; k++) {
                sc_int<8> dy = -center + k;
                sum += read_mem(img, x*img_height + y+dy) * read_mem(k);//img.get_pixel(x, y+dy, 0) * kernel.data[k];
               ofset+=sc_time(DELAY, SC_NS); 
            }
            write_mem(img, x*height + y, sum)//tmp.set_pixel(x, y, 0, sum);
        }
    }
    // convolve horizontal
    for (sc_int<16> x = 0; x < img_width; x++) {
        for (sc_int<16> y = 0; y < img_height; y++) {
            num_t sum = 0;
            for (sc_int<8> k = 0; k < size; k++) {
                sc_int<8> dx = -center + k;
                sum += read_mem(tmp, (x+dx)*img_height + y) * read_mem(k);//tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                ofset+=sc_time(DELAY, SC_NS); 
            }
            write_mem(filtered, x*height + y, sum)//filtered.set_pixel(x, y, 0, sum);
        }

    }
    Image base_img = filtered;
    
    sc_uint<8> imgs_per_octave = scales_per_octave + 3;

    // determine sigma values for bluring
    k_t k;
    k = std::pow(2, 1.0/scales_per_octave);
    std::vector<sigma_prev_total_t> sigma_vals {base_sigma};
    for (sc_uint<8> i = 1; i < imgs_per_octave; i++) {
   	sigma_prev_total_t sigma_prev, sigma_total;
        sigma_prev = base_sigma * std::pow(k, i-1);
        sigma_total = k * sigma_prev;
        sigma_vals.push_back(std::sqrt(sigma_total*sigma_total - sigma_prev*sigma_prev));
        ofset+=sc_time(DELAY, SC_NS); 
		
    }
    // create a scale space pyramid of gaussian images
    // images in each octave are half the size of images in the previous one
    ScaleSpacePyramid pyramid = {
        num_octaves,
        imgs_per_octave,
        std::vector<Image>(num_octaves*imgs_per_octave) //zamenio sam da bude 1D
    };
    for (sc_uint<8> i = 0; i < num_octaves; i++) {

      pyramid.images[i*imgs_per_octave] = (base_img); 
      
      for(sc_uint<8> j = 1; j < imgs_per_octave; j++){  
          
          const Image& prev_img = pyramid.images[i*imgs_per_octave + (j-1)];

        
        assert(prev_img.channels == 1);

        sc_int<8> size = std::ceil(6 * sigma_vals[j]);
      
        if (size % 2 == 0)
            size++;
           
        sc_int<8> center = size / 2;

        Image kernel(size, 1, 1);
        sigma_prev_total_t sum = 0;
        
            for (sc_int<8> k = -size/2; k <= size/2; k++) {
            k_t val = std::exp(-(k*k) / (2*sigma_vals[j]*sigma_vals[j]));

            write_mem(kernel, center+k, val)//kernel.set_pixel(center+k, 0, 0, val);
            sum += val;
            ofset+=sc_time(DELAY, SC_NS); 
        }


        for (sc_int<8> k = 0; k < size; k++){
            data_t tmp = read_mem(kernel, k);
            write_mem(kernel, k, tmp/sum); //kernel.data[k] /= sum;
            ofset+=sc_time(DELAY, SC_NS); 
            }
        Image tmp(img_width, img_height, 1);
        Image filtered(img_width, img_height, 1);

            // convolve vertical
        for (sc_int<16> x = 0; x < img_width; x++) {
            for (sc_int<16> y = 0; y < img_height; y++) {
                num_t sum = 0;
                for (sc_int<8> k = 0; k < size; k++) {
                    sc_int<8> dy = -center + k;
                    sum += read_mem(prev_img, x*img_height + y+dy) * read_mem(k);//img.get_pixel(x, y+dy, 0) * kernel.data[k];
                   ofset+=sc_time(DELAY, SC_NS); 
                }
                write_mem(img, x*height + y, sum)//tmp.set_pixel(x, y, 0, sum);
            }
        }
        // convolve horizontal
        for (sc_int<16> x = 0; x < img_width; x++) {
            for (sc_int<16> y = 0; y < img_height; y++) {
                num_t sum = 0;
                for (sc_int<8> k = 0; k < size; k++) {
                    sc_int<8> dx = -center + k;
                    sum += read_mem(tmp, (x+dx)*img_height + y) * read_mem(k);//tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                    ofset+=sc_time(DELAY, SC_NS); 
                }
                write_mem(filtered, x*height + y, sum)//filtered.set_pixel(x, y, 0, sum);
            }

            }
         pyramid.images[i*imgs_per_octave + j] = filtered;

      }
          
          // prepare base image for next octave
          const Image& next_base_img = pyramid.images[i*imgs_per_octave + (imgs_per_octave - 3)];
           
           img_height/=2;
           img_width/=2;
         
         Image resized(img_width, img_height, img_channels);
            k_t value = 0;
         
            for (sc_int<16> x = 0; x < img_width; x++) {
                for (sc_int<16> y = 0; y < img_height; y++) {
                    for (sc_int<8> c = 0; c < img_channels; c++) {
                    	floor_ceil_t old_x, old_y;
                         old_x = map_coordinate(img_width, img_width, x);
		                 
                         old_y = map_coordinate(img_height, img_height, y);                                                               

                         value = read_mem(next_base_img, old_x * img_height + old_y);//next_base_img.get_pixel(std::round(old_x), std::round(old_y), c);

                         write_mem(resized, x*height + y, value);//resized.set_pixel(x, y, c, value);
                            ofset+=sc_time(DELAY, SC_NS); 
                             }
                     }

                
                }
            base_img = resized;

  
         }
    
    return pyramid;
    }

}


void Ip_core::write_mem(const Image& img, sc_dt::sc_uint<64> addr, data_t val)
{
	pl_t pl;
	unsigned char buf[4];
	toUchar(buf,val);
	pl.set_address(addr/* Plus ofset slike*/);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_WRITE_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	//bram_socket->b_transport(pl, offset);
}

data_t Ip_core::read_mem(const Image& img, sc_dt::sc_uint<64> addr)
{
	pl_t pl;
	unsigned char buf;
	pl.set_address(addr /* Plus ofset slike*/);
	pl.set_data_length(1); 
	pl.set_data_ptr(&buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	//bram_socket->b_transport(pl, offset);
	return Convert_to_SigendC(buf);
}
