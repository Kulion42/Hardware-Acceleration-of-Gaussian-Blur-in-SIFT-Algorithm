#ifndef SIGMA_ROM_HPP
#define SIGMA_ROM_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <vector>
#include "addr.hpp"
#include "sc_types.hpp"
#include "functions.hpp"
#include <iostream>

class Sigma_Rom : public sc_core::sc_module
{
public:
	Sigma_Rom (sc_core::sc_module_name name);
	~Sigma_Rom();
	tlm_utils::simple_target_socket<Sigma_Rom> ip_core_socket;
	
protected:
	void b_transport(pl_t&, sc_core::sc_time&);
	std::vector<sigma_t> sigrom;
};

#endif
