#include "sigma_rom.hpp"

Sigma_Rom::Sigma_Rom(sc_core::sc_module_name name) : sc_module(name)
{
	ip_core_socket.register_b_transport(this, &Sigma_Rom::b_transport);
	sigrom.reserve(SIGMA_SIZE);
	sigrom = {  1.24899959564208984375,     1.22627341747283935546875,  1.5450077056884765625,      1.94658792018890380859375,  2.4525470733642578125,      3.09001576900482177734375,
	            0.32051277160644531250000,	0.33250284194946289062500,	0.20946359634399414062500,	0.13195371627807617187500,	0.08312559127807617187500,	0.05236589908599853515625, 
	            0.31947910785675048828125,	0.32538223266601562500000,	0.25828945636749267578125,	0.20509529113769531250000,	0.16300272941589355468750,	0.12936770915985107421875 
	            };

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
	
	uint32_t value;
	
	switch(cmd)
	{
		case tlm::TLM_READ_COMMAND:

				value = (uint32_t)((sigrom[addr]) << FIXED_POINT_FRACTIONAL_BITS_SIGMA_T);
				
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

 
