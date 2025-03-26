#ifndef KERNEL_ROM_HPP
#define KERNEL_ROM_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <vector>
#include "addr.hpp"
#include "sc_types.hpp"
#include "functions.hpp"
#include <iostream>

class Kernel_Rom : public sc_core::sc_module
{
public:
	Kernel_Rom (sc_core::sc_module_name name);
	~Kernel_Rom();
	tlm_utils::simple_target_socket<Kernel_Rom> ip_core_socket;
	
protected:
	void b_transport(pl_t&, sc_core::sc_time&);
	std::vector<data_t> kernel_rom;
};

#endif
