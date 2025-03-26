#include "ip_core.hpp"


using namespace std;
using namespace sc_dt;
using namespace sc_core;


Ip_Core::Ip_Core(sc_module_name name):
	sc_module(name),
	offset_hard(sc_core::SC_ZERO_TIME),
	ready(1)
	
{
    sigma_vals = {
         1.24899959564208984375,     1.22627341747283935546875,  1.5450077056884765625,      1.94658792018890380859375,  2.4525470733642578125,      3.09001576900482177734375
    };
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
              //cout << "img_width = " << img_width << endl;
			  break;
			case ADDR_IMG_HEIGHT:
			  img_height = toInt2(buffer);
			  //cout << "img_height = " << img_height << endl;
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
		  toUchar2(buffer, ready);
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

void Ip_Core::gaussian_blur(sc_core::sc_time& offset)
{
 //  pl_t pl;
    
    if (start == 1 && ready == 1 && reset == 0){
       // cout << "Hard started" << endl;
        ready = 0;
        offset_hard+=sc_time(DELAY, SC_NS);
   }

    else if (start == 0 && ready == 0 && reset == 0){
    //Start with work
    cout << "Startig gaussian_blur"<<endl;
    sc_int<16> c_y, c_x1, c_x2;
    sigma_t sigma = sigma_vals[img_per_octave];
    //cout << sigma << endl;
    sc_int<16> size = std::ceil(6 * sigma);
    
    if (size % 2 == 0)
        size++;
   // cout << size << endl;
    sc_int<16> center = size / 2;
    
    if (img_per_octave == 0)
    addr_off=0;
    
    else if(img_per_octave == 1)
    addr_off=size;
    
    // convolve vertical
    for (sc_int<16> x = 0; x < img_width; x+=2) {
        for (sc_int<16> y = img_offset_up; y < img_height - img_offset_down; y++) {
       //cout << img.height - offset_down << y << endl;
           sum_t sum1 = 0; sum_t sum2 = 0;
            for ( sc_int<16> k = 0; k < size; k++) {
                 sc_int<16> dy = -center + k;
                 
                 if (y+dy < 0 && img_offset_up == 0)
                    c_y = 0;
                 else if (y+dy < img_offset_up == 10)
                    c_y = img_offset_up + dy;                 
                 else if (y+dy >= img_height && img_offset_down == 0)
                    c_y = img_height - 1;
                 else if (y+dy >= img_height-img_offset_down && img_offset_down == 10)
                    c_y =  img_height-img_offset_down + dy;
                 else
                    c_y = y + dy;
                    
                 data_t pix1, pix2, val1;
                 val1 = read_rom(VP_ADDR_SIGMA_ROM_L + addr_off + k);
                 //cout << std::hex << VP_ADDR_MAIN_BRAM_L + (y+dy)*img_width + x << endl;
                 read_mem(VP_ADDR_MAIN_BRAM_L + 2 *(c_y*img_width + x), pix1, pix2);
                 
                 sum1 += pix1 * val1;
                 sum2 += pix2 * val1;
                 
                 //cout << sum << endl;
                 offset_hard += sc_time(DELAY, SC_NS);
            }
          //  tmp.set_pixel(x, y-offset_up, 0, sum);
          write_mem(VP_ADDR_TMP_BRAM_L + 2 *((y-img_offset_up)*img_width + x), sum1, sum2);
          offset_hard += sc_time(DELAY, SC_NS);
        }
        offset_hard += sc_time(DELAY, SC_NS);
    }
    offset_hard += sc_time(DELAY, SC_NS);
        
    // convolve horizontal
       for (sc_int<16> x = 0; x < img_width; x+=2) {
           for (sc_int<16> y = 0; y < img_height - img_offset_up - img_offset_down; y++) {           
               sum_t sum1 = 0; sum_t sum2 = 0;
                 for (sc_int<16> k = 0; k < size; k++) {
                 sc_int<16> dx = -center + k;
                 if (x+dx < 0 )
                    c_x1 = 0;
                 else if (x+dx >= img_width)
                    c_x1 = img_width - 1;
                 else
                    c_x1 = x + dx;
                    
                 data_t pix1, pix2,  val1;
                 val1 = read_rom(VP_ADDR_SIGMA_ROM_L + addr_off + k);
                 
                 read_mem(VP_ADDR_TMP_BRAM_L + 2 * (y*img_width + c_x1), pix1, pix2);                 
                 
                 sum1 += pix1 * val1;
                 sum2 += pix2 * val1;
                // fprintf(fp, "%2.14lf\n", (double)tmp);
               //  cout << sum << endl;
                 offset_hard += sc_time(DELAY, SC_NS);
               
            }
            //fprintf(fp, "%2.14lf\n\n", (double)sum);
           // filtered.set_pixel(x, y, 0, sum);
           write_mem(VP_ADDR_MAIN_BRAM_L + 2 * (y*img_width + x), sum1, sum2);
           offset_hard += sc_time(DELAY, SC_NS);
        }
        offset_hard += sc_time(DELAY, SC_NS);
    }
   offset_hard += sc_time(DELAY, SC_NS);
   
   addr_off+=size;
   //cout << "Time used in hardware--> " << offset_hard << endl;
      cout << "Adress offset is " << addr_off << endl;
   cout << "Gaussian blur finished" << endl;
   cout << endl;
      ready = 1;
   }
   
   
   //after this in CPU is added with software time
   offset_system = offset_hard;
   //cout << "Time used in HW is " << offset_system << endl;

}

void Ip_Core::write_mem(sc_dt::sc_uint<64> addr, data_t pix1, data_t pix2)
{
	pl_t pl;
	sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[4];
	Fixed_to_Uchar(buf, pix1, pix2);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_WRITE_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	
	if (addr >= VP_ADDR_MAIN_BRAM_L && addr <= VP_ADDR_MAIN_BRAM_H)
	{
		pl.set_address(taddr);
		main_bram_socket->b_transport(pl, offset_hard);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_TMP_BRAM_L && addr <= VP_ADDR_TMP_BRAM_H)
	{
		pl.set_address(taddr);
		tmp_bram_socket->b_transport(pl, offset_hard);
		pl.set_address(addr);
	}
	else
	{
	    SC_REPORT_ERROR("IP_Core_Write", "Wrong address.");
	}
}

void Ip_Core::read_mem(sc_dt::sc_uint<64> addr, data_t& pix1, data_t& pix2)
{
	pl_t pl;
	sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[4];
	pl.set_address(addr);
	pl.set_data_length(BUS_WIDTH); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	if (addr >= VP_ADDR_MAIN_BRAM_L && addr <= VP_ADDR_MAIN_BRAM_H)
	{
		pl.set_address(taddr);
		main_bram_socket->b_transport(pl, offset_hard);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_TMP_BRAM_L && addr <= VP_ADDR_TMP_BRAM_H)
	{
		pl.set_address(taddr);
		tmp_bram_socket->b_transport(pl, offset_hard);
		pl.set_address(addr);
	}
	else
	{
	    cout << std::hex << addr << endl;
	    SC_REPORT_ERROR("IP_Core_Read", "Wrong address.");
	}
	Uchar_to_Fixed(buf, pix1, pix2);
}

data_t Ip_Core::read_rom(sc_dt::sc_uint<64> addr)    
{
    pl_t pl;
    sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[4];
	pl.set_address(taddr);
	pl.set_data_length(4); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	kernel_rom_socket->b_transport(pl, offset_hard);
	return Uchar_to_Data_t(buf);
	
}


