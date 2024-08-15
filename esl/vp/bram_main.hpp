#ifndef _BRAM_MAIN_HPP_
#define _BRAM_MAIN_HPP_

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <vector>
#include "addr.hpp"
#include <iostream>


class Main_Bram : public sc_core::sc_module
{
	public:
		Main_Bram (sc_core::sc_module_name name);
		~Main_Bram();
		tlm_utils::simple_target_socket<Main_Bram> interconnect_socket;
	protected:
		void b_transport(pl_t &, sc_core::sc_time &);
		std::vector<unsigned char> mem;
};

#endif

