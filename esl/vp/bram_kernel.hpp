#ifndef _BRAM_KERNEL_HPP_
#define _BRAM_KERNEL_HPP_

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <vector>
#include "addr.hpp"
#include <iostream>


class Kernel_Bram : public sc_core::sc_module
{
	public:
		Kernel_Bram (sc_core::sc_module_name name);
		~Kernel_Bram();
		tlm_utils::simple_target_socket<Kernel_Bram> ip_core_socket;
		
	protected:
		void b_transport(pl_t &, sc_core::sc_time &);
		std::vector<unsigned char> mem;
};

#endif

