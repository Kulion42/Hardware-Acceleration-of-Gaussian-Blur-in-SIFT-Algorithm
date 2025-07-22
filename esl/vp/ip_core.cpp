#include "ip_core.hpp"


using namespace std;
using namespace sc_dt;
using namespace sc_core;


Ip_Core::Ip_Core(sc_module_name name):
	sc_module(name),
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
			  img_width = toInt<int>(buffer, 2);  
              //cout << "img_width = " << img_width << endl;
			  break;
			case ADDR_IMG_HEIGHT:
			  img_height = toInt<int>(buffer, 2);
			  //cout << "img_height = " << img_height << endl;
			  break;
			case ADDR_IMG_OFFSET_UP:
			  img_offset_up = toInt<int>(buffer, 2);
			 // cout << "img_offset_up = " << img_offset_up << endl;
			  break;
			case ADDR_IMG_OFFSET_DOWN:
			  img_offset_down = toInt<int>(buffer, 2);
			 // cout << "img_offset_down = " << img_offset_down << endl;
			  break;
			case ADDR_NUM_IMG_OCT:
			  img_per_octave = toInt<int>(buffer, 2);
			 // cout << "img_per_octave = " << img_per_octave << endl;
			  break;
			case ADDR_START:
			  start = toInt<int>(buffer, 1);
			 // cout << "start_bit = " <<  start << endl;
			  gaussian_blur(offset);
			  break;
			case ADDR_RESET:
			  reset = toInt<int>(buffer, 1);			  
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
		  toChar<int>(buffer, ready, 1);
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
        //cout << "Hard started" << endl;
        ready = 0;
        offset+=sc_time(DELAY, SC_NS);
   }

    else if (start == 0 && ready == 0 && reset == 0){
    //Start with work
    //cout << "Startig gaussian_blur"<<endl;
    sc_int<16> c_y, c_x1, c_x2;
    float sigma = sigma_vals[img_per_octave];
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
           data_t sum[2] = {0, 0};
            for ( sc_int<16> k = 0; k < size; k++) {
                 sc_int<16> dy = -center + k;
                 
                 if (y+dy < 0 && img_offset_up == 0)
                    c_y = 0;
                 else if (y+dy < img_offset_up != 0)
                    c_y = img_offset_up + dy;                 
                 else if (y+dy >= img_height && img_offset_down == 0)
                    c_y = img_height - 1;
                 else if (y+dy >= img_height-img_offset_down && img_offset_down != 0)
                    c_y =  img_height-img_offset_down + dy;
                 else
                    c_y = y + dy;
                    
                 data_t pix[2];
				 data_t kernel_val;
                 read_rom(VP_ADDR_KERNEL_ROM_L + addr_off + k, &kernel_val);
				 //cout << "Reading kernel value: " << kernel_val << " at address: " << addr_off + k << endl;
                 //cout << std::hex << VP_ADDR_MAIN_BRAM_L + (y+dy)*img_width + x << endl;
                 read_mem(VP_ADDR_MAIN_BRAM_L + 2 *(c_y*img_width + x), pix);
                 //cout << pix[0] << " " << pix[1] << endl;
                 sum[0] += pix[0] * kernel_val;
				 sum[1] += pix[1] * kernel_val;
                 
                 //cout << sum << endl;
                 offset += sc_time(DELAY, SC_NS);
            }
          //  tmp.set_pixel(x, y-offset_up, 0, sum);
          write_mem(VP_ADDR_TMP_BRAM_L + 2 *((y-img_offset_up)*img_width + x), sum);
          offset += sc_time(DELAY, SC_NS);
        }
        offset += sc_time(DELAY, SC_NS);
    }
    offset += sc_time(DELAY, SC_NS);
       //while(1); 
    // convolve horizontal
       for (sc_int<16> x = 0; x < img_width; x+=2) {
           for (sc_int<16> y = 0; y < img_height - img_offset_up - img_offset_down; y++) {           
               data_t sum[2] = {0, 0};
                 for (sc_int<16> k = 0; k < size; k++) {
                 sc_int<16> dx = -center + k;
                 if (x+dx < 0 )
                    c_x1 = 0;
                 else if (x+dx >= img_width)
                    c_x1 = img_width - 1;
                 else
                    c_x1 = x + dx;
                    
                 data_t pix[2];  
				 data_t kernel_val;
                 read_rom(VP_ADDR_KERNEL_ROM_L + addr_off + k, &kernel_val);
                 read_mem(VP_ADDR_TMP_BRAM_L + 2 * (y*img_width + c_x1), pix);                 
                 
                 sum[0] += pix[0] * kernel_val;
				 sum[1] += pix[1] * kernel_val;

                 offset += sc_time(DELAY, SC_NS);
               
            }
           write_mem(VP_ADDR_MAIN_BRAM_L + 2 * (y*img_width + x), sum);
           offset += sc_time(DELAY, SC_NS);
        }
        offset += sc_time(DELAY, SC_NS);
    }
   offset += sc_time(DELAY, SC_NS);
   
   addr_off+=size;
   //cout << addr_off << endl;
   //cout << "Time used in hardware--> " << offset << endl;
   //cout << "Gaussian blur finished" << endl;
   //cout << endl;
      ready = 1;
   }
   
   

}

void Ip_Core::write_mem(sc_dt::sc_uint<64> addr, data_t *pix)
{
	pl_t pl;
	sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[4];
	to_Uchar<data_t>(buf, pix);
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
	else
	{
	    SC_REPORT_ERROR("IP_Core_Write", "Wrong address.");
	}
}

void Ip_Core::read_mem(sc_dt::sc_uint<64> addr, data_t *pix)
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
		main_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_TMP_BRAM_L && addr <= VP_ADDR_TMP_BRAM_H)
	{
		pl.set_address(taddr);
		tmp_bram_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else
	{
	    cout << std::hex << addr << endl;
	    SC_REPORT_ERROR("IP_Core_Read", "Wrong address.");
	}
	from_Uchar<data_t>(buf, pix);
	
}

void Ip_Core::read_rom(sc_dt::sc_uint<64> addr, data_t *val)    
{
    pl_t pl;
    sc_dt::uint64 taddr = addr & 0x00FFFFFF;
	unsigned char buf[2];
	pl.set_address(taddr);
	pl.set_data_length(2); 
	pl.set_data_ptr(buf);
	pl.set_command( tlm::TLM_READ_COMMAND );
	pl.set_response_status ( tlm::TLM_INCOMPLETE_RESPONSE );
	kernel_rom_socket->b_transport(pl, offset);
	//cout << "Reading kernel value: " << toInt<unsigned int>(buf, 2) << " at address: " << taddr << endl;	
	*val = ((double)toInt<uint16_t>(buf, 2)) / (double)(1 << 16);
	
}


