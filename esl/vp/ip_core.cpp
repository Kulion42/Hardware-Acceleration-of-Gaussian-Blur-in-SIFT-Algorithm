#include "ip_core.hpp"


using namespace std;
using namespace sc_dt;
using namespace sc_core;

Ip_Core::Ip_Core(sc_module_name name):
	sc_module(name),
	ready(1)
	
{
	interconnect_socket.register_b_transport(this, &Ip_Core::b_transport);
	
	SC_REPORT_INFO("IP Core", "Constructed.");
}

Ip_Core::~Ip_Core()
{
	SC_REPORT_INFO("IP Core", "Destroyed.");
}


void Ip_Core::b_transport(pl_t &pl, sc_time &offset)
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
			case ADDR_IMG_WIDTH:
			  img_width = toInt2(buffer);  
			  cout << "img_width = " << img_width << endl;
			  break;
			case ADDR_IMG_HEIGHT:
			  img_height = toInt2(buffer);
			  cout << "img_height = " << img_height << endl;
			  break;
			case ADDR_IMG_OFFSET_UP:
			  img_offset_up = toInt2(buffer);
			  cout << "img_offset_up = " << img_offset_up << endl;
			  break;
			case ADDR_IMG_OFFSET_DOWN:
			  img_offset_down = toInt2(buffer);
			  cout << "img_offset_down = " << img_offset_down << endl;
			  break;
			case ADDR_NUM_IMG_OCT:
			  img_per_octave = toInt2(buffer);
			  cout << "img_per_octave = " << img_per_octave << endl;
			  break;
			case ADDR_START:
			  start = toInt2(buffer);
			 // cout << "start_bit = " <<  start << endl;
			  gaussian_blur(offset);
			  break;
			case ADDR_RESET:
			  reset = toInt2(buffer);
			  //cout << "reset_bit = " << reset << endl;
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
		  toUchar4(buffer, ready);
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

void Ip_Core::gaussian_blur(sc_core::sc_time &offset)
{
 //  pl_t pl;
   
   if (start == 1 && ready == 1){
        cout << "Hard started" << endl;
        ready = 0;
        offset+=sc_time(DELAY, SC_NS);
   }

    else if (start == 0 && ready == 0 ){
    //Start with work
    cout << "Startig gaussian_blur"<<endl;
    
    size = std::ceil(6 * sigma);
    
    if (size % 2 == 0)
        size++;
    
    center = size / 2;
        
   // cout << center << endl;
  //  Image kernel(size, 1, 1);
    sigma = read_rom(VP_ADDR_SIGMA_ROM_L + img_per_octave);
    
    //cout << sigma << endl;
    sum = 0;
        for (k = -size/2; k <= size/2; k++) {
      // cout << std::hex << VP_ADDR_SIGMA_ROM_L + img_per_octave << endl;
        val = std::exp(-(k*k) / (2*sigma*sigma));
     //   cout << "Test1" << endl;
    //    kernel.set_pixel(center+k, 0, 0, val);
    
        write_mem(VP_ADDR_KERNEL_BRAM_L + 2 *(center+k), val);
        sum += val;
        offset += sc_time(DELAY, SC_NS);
    }
 //  cout << endl;
    for (k = 0; k < size; k++){
       // kernel.data[k] /= sum;
       val = read_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k) / sum;
       write_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k, val);
       offset += sc_time(DELAY, SC_NS);
        }
 //   Image tmp(img.width, img.height-(offset_up + offset_down), 1);
   // Image filtered(img.width, img.height-(offset_up + offset_down), 1);
    
    // convolve vertical
    for ( x = 0; x < img_width; x++) {
        for (y = img_offset_up; y < img_height - img_offset_down; y++) {
       //cout << img.height - offset_down << y << endl;
            sum = 0;
            for ( k = 0; k < size; k++) {
                 dy = -center + k;
                 
                 if (y+dy > img_offset_up && y+dy < img_height - img_offset_down)
                    c_y = y+dy;
               // sum += img.get_pixel(x, y+dy, 0) * ;
                 val = read_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k);
                 //cout << std::hex << VP_ADDR_MAIN_BRAM_L + (y+dy)*img_width + x << endl;
                 sum = read_mem(VP_ADDR_MAIN_BRAM_L + 2 *(c_y*img_width + x)) * val;
                 
                 offset += sc_time(DELAY, SC_NS);
            }
          //  tmp.set_pixel(x, y-offset_up, 0, sum);
          write_mem(VP_ADDR_TMP_BRAM_L + 2 *((y-img_offset_up)*img_width + x), sum);
        }
    }
    
    // convolve horizontal
    for ( x = 0; x < img_width; x++) {
        for ( y = 0; y < img_height - img_offset_up - img_offset_down; y++) {
             sum = 0;
            for (k = 0; k < size; k++) {
                 dx = -center + k;
                 if (x+dx > 0 && x+dy < img_width)
                    c_x = x+dx;
                //sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                 val = read_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k);
                 sum = read_mem(VP_ADDR_TMP_BRAM_L + 2 * (y*img_width + c_x)) * val;
                 offset += sc_time(DELAY, SC_NS);
            }

           // filtered.set_pixel(x, y, 0, sum);
           write_mem(VP_ADDR_MAIN_BRAM_L + 2 * (y*img_width + x), sum);
        }
    }
   offset += sc_time(DELAY, SC_NS);
   

   cout << "Gaussian blur finished" << endl;
   cout << endl;
      ready = 1;
   }
   
}

void Ip_Core::write_mem(sc_dt::sc_uint<64> addr, data_t val)
{
	pl_t pl;
	unsigned char buf[2];
	Fixed_to_Uchar(buf, val);
	pl.set_address(addr);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_WRITE_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	mem_socket->b_transport(pl, offset);
}

data_t Ip_Core::read_mem(sc_dt::sc_uint<64> addr)
{
	pl_t pl;
	unsigned char buf;
	pl.set_address(addr);
	pl.set_data_length(2); 
	pl.set_data_ptr(&buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	mem_socket->b_transport(pl, offset);
	return Uchar_to_Fixed(&buf);
}

sigma_t Ip_Core::read_rom(sc_dt::sc_uint<64> addr)    
{
    pl_t pl;
	unsigned char buf;
	pl.set_address(addr);
	pl.set_data_length(4); 
	pl.set_data_ptr(&buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	mem_socket->b_transport(pl, offset);
	return Uchar_to_Sigma_t(&buf);
	
}
