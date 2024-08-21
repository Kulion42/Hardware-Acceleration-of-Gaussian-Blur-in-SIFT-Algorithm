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
			 // cout << "img_offset_up = " << img_offset_up << endl;
			  break;
			case ADDR_IMG_OFFSET_DOWN:
			  img_offset_down = toInt2(buffer);
			 // cout << "img_offset_down = " << img_offset_down << endl;
			  break;
			case ADDR_NUM_IMG_OCT:
			  img_per_octave = toInt2(buffer);
			 // cout << "img_per_octave = " << img_per_octave << endl;
			  break;
			case ADDR_START:
			  start = toInt2(buffer);
			 // cout << "start_bit = " <<  start << endl;
			  gaussian_blur(offset);
			  break;
			case ADDR_RESET:
			  reset = toInt2(buffer);			  
			 // cout << "reset_bit = " << reset << endl;
			  if (reset == 1)
			  gaussian_blur(offset);
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
   FILE *fp; 
    std::string blur_x= "convolute_x_";
    std::string blur_y = "convolute_y_";
    std::string kernel_val = "kernel_state_";
    
    char numstr[21];
    std::string res;
    
    if (start == 1 && ready == 1 && reset == 0){
       // cout << "Hard started" << endl;
        ready = 0;
        offset+=sc_time(DELAY, SC_NS);
   }

    else if (start == 0 && ready == 0 && reset == 0){
    //Start with work
    cout << "Startig gaussian_blur"<<endl;
    sc_int<16> c_y, c_x;
    sigma_t sigma = read_rom(VP_ADDR_SIGMA_ROM_L + img_per_octave);
    //cout << sigma << endl;
    sc_int<16> size = std::ceil(6 * sigma);
    
    if (size % 2 == 0)
        size++;
   // cout << size << endl;
    sc_int<16> center = size / 2;
        
   // cout << center << endl;
  //  Image kernel(size, 1, 1);
    sprintf(numstr, "%d", (int)img_per_octave);
    res = kernel_val + numstr + "_one" +".txt";
    fp = fopen(res.c_str(), "w+");
    sum_t sum_kernel = 0;
        for (sc_int<16> k = -size/2; k <= size/2; k++) {
      // cout << std::hex << VP_ADDR_SIGMA_ROM_L + img_per_octave << endl;
         sum_t val = std::exp(-(k*k) / (2*sigma*sigma));
     //   cout << "Test1" << endl;
    //    kernel.set_pixel(center+k, 0, 0, val);
    
        write_mem(VP_ADDR_KERNEL_BRAM_L + 2 *(center+k), (data_t)val);
        
        data_t tmp = read_mem(VP_ADDR_KERNEL_BRAM_L + 2 *(center+k));
        fprintf(fp, "%2.14lf\n", (double)tmp);
        
        sum_kernel += val;
        offset += sc_time(DELAY, SC_NS);
    }
    fclose(fp);
    
    sprintf(numstr, "%d", (int)img_per_octave);
    res = kernel_val + numstr + "_two" + ".txt";
    fp = fopen(res.c_str(), "w+");
    for (sc_int<16> k = 0; k < size; k++){
       // kernel.data[k] /= sum;
       sum_t val = (sum_t)read_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k) / sum_kernel;
      // cout << val << endl;
       write_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k, (data_t)val);
       
       data_t tmp = read_mem(VP_ADDR_KERNEL_BRAM_L + 2 *k);
       fprintf(fp, "%2.14lf\n", (double)tmp);
       
       offset += sc_time(DELAY, SC_NS);
        } 
      fclose(fp); 
 //   Image tmp(img.width, img.height-(offset_up + offset_down), 1);
   // Image filtered(img.width, img.height-(offset_up + offset_down), 1);
    sprintf(numstr, "%d", (int)img_per_octave);
    res = blur_y + numstr + ".txt";
    fp = fopen(res.c_str(), "w+");
    // convolve vertical
    for (sc_int<16> x = 0; x < img_width; x++) {
        for (sc_int<16> y = img_offset_up; y < img_height - img_offset_down; y++) {
       //cout << img.height - offset_down << y << endl;
           sum_t sum = 0;
            for ( sc_int<16> k = 0; k < size; k++) {
                 sc_int<16> dy = -center + k;
                 
                 if (y+dy < img_offset_up)
                    c_y = 0;
                 else if (y+dy >= img_height - img_offset_down)
                    c_y = img_height - img_offset_down - 1;
                 else
                    c_y = y + dy;
               // sum += img.get_pixel(x, y+dy, 0) *  kernel.data[k];
                 sum_t val = (sum_t)read_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k);
                 //cout << std::hex << VP_ADDR_MAIN_BRAM_L + (y+dy)*img_width + x << endl;
                 data_t tmp = read_mem(VP_ADDR_MAIN_BRAM_L + 2 *(c_y*img_width + x));
                 fprintf(fp, "%2.14lf\n", (double)tmp);
                 sum += (sum_t)read_mem(VP_ADDR_MAIN_BRAM_L + 2 *(c_y*img_width + x)) * val;
                 
                 //cout << sum << endl;
                 offset += sc_time(DELAY, SC_NS);
            }
          //  tmp.set_pixel(x, y-offset_up, 0, sum);
          write_mem(VP_ADDR_TMP_BRAM_L + 2 *((y-img_offset_up)*img_width + x), (data_t)sum);
        }
    }
    fclose(fp);
    
    sprintf(numstr, "%d", (int)img_per_octave);
    res = blur_x + numstr + ".txt";
    fp = fopen(res.c_str(), "w+");
    // convolve horizontal
       for (sc_int<16> x = 0; x < img_width; x++) {
           for (sc_int<16> y = 0; y < img_height - img_offset_up - img_offset_down; y++) {           
               sum_t sum = 0;
                 for (sc_int<16> k = 0; k < size; k++) {
                 sc_int<16> dx = -center + k;
                 if (x+dx < 0 )
                    c_x = 0;
                 else if (x+dx >= img_width)
                    c_x = img_width - 1;
                 else
                    c_x = x + dx;
                //sum += tmp.get_pixel(x+dx, y, 0) * kernel.data[k];
                 sum_t val = (sum_t)read_mem(VP_ADDR_KERNEL_BRAM_L + 2 * k);
                 sum += (sum_t)read_mem(VP_ADDR_TMP_BRAM_L + 2 * (y*img_width + c_x)) * val;
                 data_t tmp = read_mem(VP_ADDR_TMP_BRAM_L + 2 * (y*img_width + c_x));
                 fprintf(fp, "%2.14lf\n", (double)tmp);
               //  cout << sum << endl;
                 offset += sc_time(DELAY, SC_NS);
            }

           // filtered.set_pixel(x, y, 0, sum);
           write_mem(VP_ADDR_MAIN_BRAM_L + 2 * (y*img_width + x), (data_t)sum);
        }
    }
    fclose(fp);
   offset += sc_time(DELAY, SC_NS);
   

   cout << "Gaussian blur finished" << endl;
   cout << endl;
      ready = 1;
   }
   
    else if (reset == 1){
    
        ready = 0;
        
        for (sc_dt::sc_uint<64> k = VP_ADDR_MAIN_BRAM_L; k < VP_ADDR_MAIN_BRAM_H; k+=2)
        {
            write_mem(k, data_t(0.0));
        }
        for (sc_dt::sc_uint<64> k = VP_ADDR_TMP_BRAM_L; k < VP_ADDR_TMP_BRAM_H; k+=2)
        {
            write_mem(k, data_t(0.0));
        }
        for (sc_dt::sc_uint<64> k = VP_ADDR_KERNEL_BRAM_L; k < VP_ADDR_KERNEL_BRAM_H; k+=2)
        {
            write_mem(k, data_t(0.0));
        }
        
        ready = 1;
   }
   
}

void Ip_Core::write_mem(sc_dt::sc_uint<64> addr, data_t val)
{
	pl_t pl;
	sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[2];
	Fixed_to_Uchar(buf, val);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_WRITE_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	
	if (addr >= VP_ADDR_MAIN_BRAM_L && addr <= VP_ADDR_MAIN_BRAM_H)
	{
		pl.set_address(taddr);
		main_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_TMP_BRAM_L && addr <= VP_ADDR_TMP_BRAM_H)
	{
		pl.set_address(taddr);
		tmp_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_KERNEL_BRAM_L && addr <= VP_ADDR_KERNEL_BRAM_H)
	{
		pl.set_address(taddr);
		kernel_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else
	{
	    SC_REPORT_ERROR("IP_Core_Write", "Wrong address.");
	}
}

data_t Ip_Core::read_mem(sc_dt::sc_uint<64> addr)
{
	pl_t pl;
	sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[2];
	pl.set_address(addr);
	pl.set_data_length(2); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	if (addr >= VP_ADDR_MAIN_BRAM_L && addr <= VP_ADDR_MAIN_BRAM_H)
	{
		pl.set_address(taddr);
		main_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_TMP_BRAM_L && addr <= VP_ADDR_TMP_BRAM_H)
	{
		pl.set_address(taddr);
		tmp_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_KERNEL_BRAM_L && addr <= VP_ADDR_KERNEL_BRAM_H)
	{
		pl.set_address(taddr);
		kernel_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else
	{
	    SC_REPORT_ERROR("IP_Core_Read", "Wrong address.");
	}
	return Uchar_to_Fixed(buf);
}

sigma_t Ip_Core::read_rom(sc_dt::sc_uint<64> addr)    
{
    pl_t pl;
    sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[4];
	pl.set_address(taddr);
	pl.set_data_length(4); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	sigma_rom_socket->b_transport(pl, offset);
	return Uchar_to_Sigma_t(buf);
	
}
