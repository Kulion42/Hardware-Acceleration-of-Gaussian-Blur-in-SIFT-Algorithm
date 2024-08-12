#include "ip_core.hpp"


using namespace std;
using namespace sc_dt;
using namespace sc_core;

Ip_core::Ip_core(sc_module_name name):
	sc_module(name),
	ready(1)
	
{
	interconnect_socket.register_b_transport(this, &Ip_core::b_transport);
	
	SC_REPORT_INFO("IP core", "Constructed.");
}

Ip_core::~Ip_core()
{
	SC_REPORT_INFO("IP core", "Destroyed.");
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
			case ADDR_IMG_WIDTH:
			  img_width = toInt2(buffer);  
			  cout << "tmpl_width = " << img_width << endl;
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
			case ADDR_SIZE:
			  size = toInt2(buffer);
			  cout << "size = " << size << endl;
			  break;
			case ADDR_START:
			  start = toInt2(buffer);
			  cout << "start bit" << endl;
			  gaussian_blur(sc_time& offset);
			  break;
			case ADDR_RESET:
			  reset = toInt2(buffer);
			  cout << "reset bit" << endl;
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

void Ip_core::gaussian_blur(sc_time offset)
{
 //  pl_t pl;
   
   if (start == 1 && ready == 1){
        cout << "Hard started" << endl;
        ofset+=sc_time(DELAY, SC_NS);
   }

    else if (start == 0 && ready == 0 ){
    //Start with work
    cout << "Startig gaussian_blur"<<endl;
    
    assert(img.channels == 1);

    
    center = size / 2;
        
   // cout << center << endl;
  //  Image kernel(size, 1, 1);
    sum = 0;
        for (k = -size/2; k <= size/2; k++) {
        val = std::exp(-(k*k) / (2*sigma*sigma));
    //    kernel.set_pixel(center+k, 0, 0, val);
        write_mem(VP_ADDR_KERNEL_BRAM_L + center+k, val);
        sum += val;
        offset += sc_time(DELAY, SC_NS);
    }
   // cout << kernel.size << endl;
 //  cout << endl;
    for (k = 0; k < size; k++){
       // kernel.data[k] /= sum;
       val = read_mem(VP_ADDR_KERNEL_BRAM_L + k) / sum;
       write_mem(VP_ADDR_KERNEL_BRAM_L + k, val);
       offset += sc_time(DELAY, SC_NS);
        }

 //   Image tmp(img.width, img.height-(offset_up + offset_down), 1);
   // Image filtered(img.width, img.height-(offset_up + offset_down), 1);
    
    // convolve vertical
    for ( x = 0; x < img_width; x++) {
        for (y = offset_up; y < img_height - offset_down; y++) {
       //cout << img.height - offset_down << y << endl;
            sum = 0;
            for ( k = 0; k < size; k++) {
                 dy = -center + k;
               // sum += img.get_pixel(x, y+dy, 0) * ;
                 sum = read_mem(VP_ADDR_MAIN_BRAM_L + (y+dy)*img_width + x) * kernel.data[k];
                 offset += sc_time(DELAY, SC_NS);
            }
          //  tmp.set_pixel(x, y-offset_up, 0, sum);
          write_mem(VP_ADDR_TMP_BRAM_L + (y-offset)*img_width + x);
        }
    }
    

    // convolve horizontal
    for ( x = 0; x < img_width; x++) {
        for ( y = 0; y < img_height - offset_up - offset_down; y++) {
             sum = 0;
            for (k = 0; k < size; k++) {
                 dx = -center + k;
                
                //sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                 sum = read_mem(VP_ADDR_TMP_BRAM_L + y*img_width + x+dx) * kernel.data[k];
                 offset += sc_time(DELAY, SC_NS);
            }

           // filtered.set_pixel(x, y, 0, sum);
           write_mem(VP_ADDR_MAIN_BRAM_L + y*img_width + x);
        }
    }
   offset += sc_time(DELAY, SC_NS);
   }
   
   ready = 1;
   cout << " Gaussian blur finished" << endl;
}

void Ip_core::write_mem(sc_dt::sc_uint<64> addr, data_t val)
{
	pl_t pl;
	unsigned char buf[2];
	Fixed_to_Uchar(buf, val);
	pl.set_address(addr);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_WRITE_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	bram_socket->b_transport(pl, offset);
}

data_t Ip_core::read_mem(sc_dt::sc_uint<64> addr)
{
	pl_t pl;
	unsigned char buf;
	pl.set_address(addr);
	pl.set_data_length(2); 
	pl.set_data_ptr(&buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	bram_socket->b_transport(pl, offset);
	return Uchar_to_Fixed(buf);
}
