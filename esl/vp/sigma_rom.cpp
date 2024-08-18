#include "sigma_rom.hpp"

Sigma_Rom::Sigma_Rom(sc_core::sc_module_name name) : sc_module(name)
{
	ip_core_socket.register_b_transport(this, &Sigma_Rom::b_transport);
	sigrom.reserve(SIGMA_SIZE);
	sigrom = {1.24899959564208984375, 1.22627341747283935546875, 1.5450077056884765625, 1.94658792018890380859375, 2.4525470733642578125, 3.09001576900482177734375 };

	SC_REPORT_INFO("Sigma ROM", "Constructed.");
}

Sigma_Rom::~Sigma_Rom()
{
	SC_REPORT_INFO("Sigma ROM", "Destroyed.");
}

void Sigma_Rom::b_transport(pl_t &pl, sc_core::sc_time &offset)
{
	tlm::tlm_command cmd = pl.get_command();
	sc_dt::uint64 addr = pl.get_address();
	unsigned int len = pl.get_data_length();
	unsigned char *buf = pl.get_data_ptr(); 
	
	int32_t value;
	
	switch(cmd)
	{
		case tlm::TLM_READ_COMMAND:

				value = (int32_t)((sigrom[addr]) << 23);
				
				//std::cout << value  << std::endl;
		  		buf[0] = (unsigned char)(value >> 24);
		  		buf[1] = (unsigned char)(value >> 16);
		  		buf[2] = (unsigned char)(value >> 8);
		  		buf[3] = (unsigned char)(value);
			    
			    //std::cout << (value >> 24) << (value >> 16) << (value >> 8) << std::endl;
			pl.set_response_status(tlm::TLM_OK_RESPONSE);
			
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
			break;
	
		default:
			pl.set_response_status( tlm::TLM_COMMAND_ERROR_RESPONSE );
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
	}
}

 
