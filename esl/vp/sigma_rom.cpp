#include "sigma_rom.hpp"

Sigma_Rom::Sigma_Rom(sc_core::sc_module_name name) : sc_module(name)
{
	ip_core_socket.register_b_transport(this, &Sigma_Rom::b_transport);
	sigrom.reserve(SIGMA_SIZE);
	sigrom = {1.2489986419677734375, 1.2262725830078125, 1.54500675201416015625, 1.94658565521240234375, 2.452545166015625, 3.0900135040283203125 };

	SC_REPORT_INFO("Sigma_Rom", "Constructed.");
}

Sigma_Rom::~Sigma_Rom()
{
	SC_REPORT_INFO("Sigma_Rom", "Destroyed.");
}

void Sigma_Rom::b_transport(pl_t &pl, sc_core::sc_time &offset)
{
	tlm::tlm_command cmd = pl.get_command();
	sc_dt::uint64 addr = pl.get_address();
	unsigned int len = pl.get_data_length();
	unsigned char *buf = pl.get_data_ptr(); 
	
	uint16_t value;
	
	switch(cmd)
	{
		case tlm::TLM_READ_COMMAND:
			for (unsigned int i = 0; i < len; i+=3)
			{
				value = (uint16_t)(sigrom[addr] << 20);
				
		  		buf[i] = (unsigned char)(value >> 16);
		  		buf[i+1] = (unsigned char)(value & 0xFF00);
		  		buf[i+2] = (unsigned char)(value & 0xFF);
			}
			pl.set_response_status(tlm::TLM_OK_RESPONSE);
			
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
			break;
	
		default:
			pl.set_response_status( tlm::TLM_COMMAND_ERROR_RESPONSE );
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
	}
}

 
