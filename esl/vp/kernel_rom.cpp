#include "kernel_rom.hpp"

Kernel_Rom::Kernel_Rom(sc_core::sc_module_name name) : sc_module(name)
{
	ip_core_socket.register_b_transport(this, &Kernel_Rom::b_transport);
	kernel_rom.reserve(KERNEL_SIZE);
	kernel_rom = {
	    0.001892,	0.017838,	0.088638,	0.231857,	0.319473,	0.231857,	0.088638,	0.017838,	0.001892,	
		0.001587,	0.016312,	0.086044,	0.233337,	0.325378,	0.233337,	0.086044,	0.016312,	0.001587,	
		0.001373,	0.009048,	0.039200,	0.111740,	0.209473,	0.258286,	0.209473,	0.111740,	0.039200,	0.009048,	0.001373,	
		0.001770,	0.007568,	0.024826,	0.062531,	0.120972,	0.179733,	0.205093,	0.179733,	0.120972,	0.062531,	0.024826,	0.007568,	0.001770,	
		0.002762,	0.008163,	0.020401,	0.043106,	0.077133,	0.116882,	0.149994,	0.162994,	0.149994,	0.116882,	0.077133,	0.043106,	0.020401,	0.008163,	0.002762,	
		0.001846,	0.004532,	0.009933,	0.019638,	0.034927,	0.055969,	0.080750,	0.104919,	0.122757,	0.129364,	0.122757,	0.104919,	0.080750,	0.055969,	0.034927,	0.019638,	0.009933,	0.004532,	0.001846	
    };
	SC_REPORT_INFO("Kernel_Rom", "Constructed.");
}

Kernel_Rom::~Kernel_Rom()
{
	SC_REPORT_INFO("Kernel_Rom", "Destroyed.");
}

void Kernel_Rom::b_transport(pl_t &pl, sc_core::sc_time &offset)
{
	tlm::tlm_command cmd = pl.get_command();
	sc_dt::uint64 addr = pl.get_address();
	unsigned int len = pl.get_data_length();
	unsigned char *buf = pl.get_data_ptr(); 
	
	uint16_t value;
	switch(cmd)
	{
		case tlm::TLM_READ_COMMAND:

				value = (uint16_t)(((data_t)kernel_rom[addr]) * (1<< 16));
				
				toChar<uint16_t>(buf, value, 2);
			    
			    //std::cout << (value >> 24) << (value >> 16) << (value >> 8) << std::endl;
			pl.set_response_status(tlm::TLM_OK_RESPONSE);
			
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
			break;
	
		default:
			pl.set_response_status( tlm::TLM_COMMAND_ERROR_RESPONSE );
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
	}
}

 
