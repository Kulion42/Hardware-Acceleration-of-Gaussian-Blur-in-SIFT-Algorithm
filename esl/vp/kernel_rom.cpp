#include "kernel_rom.hpp"

Kernel_Rom::Kernel_Rom(sc_core::sc_module_name name) : sc_module(name)
{
	ip_core_socket.register_b_transport(this, &Kernel_Rom::b_transport);
	kernel_rom.reserve(KERNEL_SIZE);
	kernel_rom = {
	    0.00183105468750,	0.01782226562500,	0.08862304687500,	0.23187255859375,	0.31945800781250,	0.23187255859375,	0.08862304687500,	0.01782226562500,	0.00183105468750,	
        0.00158691406250,	0.01629638671875,	0.08599853515625,	0.23333740234375,	0.32537841796875,	0.23333740234375,	0.08599853515625,	0.01629638671875,	0.00158691406250,	
        0.00134277343750,	0.00903320312500,	0.03918457031250,	0.11169433593750,	0.20947265625000,	0.25823974609375,	0.20947265625000,	0.11169433593750,	0.03918457031250,	0.00903320312500,	0.00134277343750,	
        0.00170898437500,	0.00750732421875,	0.02478027343750,	0.06250000000000,	0.12097167968750,	0.17974853515625,	0.20507812500000,	0.17974853515625,	0.12097167968750,	0.06250000000000,	0.02478027343750,	0.00750732421875,	0.00170898437500,	
        0.00274658203125,	0.00811767578125,	0.02038574218750,	0.04309082031250,	0.07708740234375,	0.11688232421875,	0.14996337890625,	0.16296386718750,	0.14996337890625,	0.11688232421875,	0.07708740234375,	0.04309082031250,	0.02038574218750,	0.00811767578125,	0.00274658203125,	
        0.00183105468750,	0.00451660156250,	0.00988769531250,	0.01959228515625,	0.03491210937500,	0.05596923828125,	0.08068847656250,	0.10491943359375,	0.12274169921875,	0.12933349609375,	0.12274169921875,	0.10491943359375,	0.08068847656250,	0.05596923828125,	0.03491210937500,	0.01959228515625,	0.00988769531250,	0.00451660156250,	0.00183105468750  
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

				value = (uint16_t)((kernel_rom[addr]) << FIXED_POINT_FRACTIONAL_BITS_DATA_T);
				
				//std::cout << value  << std::endl;
		  		buf[0] = (unsigned char)(value >> 8);
		  		buf[1] = (unsigned char)(value);
			    
			    //std::cout << (value >> 24) << (value >> 16) << (value >> 8) << std::endl;
			pl.set_response_status(tlm::TLM_OK_RESPONSE);
			
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
			break;
	
		default:
			pl.set_response_status( tlm::TLM_COMMAND_ERROR_RESPONSE );
			offset += sc_core::sc_time(DELAY, sc_core::SC_NS);
	}
}

 
