#ifndef _INTERCONNECT_HPP_
#define _INTERCONNECT_HPP_

#include <iostream>
#include <systemc>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "addr.hpp"

class Interconnect : public sc_core::sc_module
{
	public:
		Interconnect(sc_core::sc_module_name name);
		~Interconnect();
		tlm_utils::simple_target_socket<Interconnect> cpu_socket;
		tlm_utils::simple_target_socket<Interconnect> ip_core_tsocket;
		
		tlm_utils::simple_initiator_socket<Interconnect> ip_core_isocket;
		tlm_utils::simple_initiator_socket<Interconnect> main_bram_socket;
		tlm_utils::simple_initiator_socket<Interconnect> tmp_bram_socket;
		tlm_utils::simple_initiator_socket<Interconnect> kernel_bram_socket;
		tlm_utils::simple_initiator_socket<Interconnect> sigma_rom_socket;

	protected:
		pl_t pl;
		sc_core::sc_time offset;
		void b_transport(pl_t &pl, sc_core::sc_time &offset);
};

#endif 
