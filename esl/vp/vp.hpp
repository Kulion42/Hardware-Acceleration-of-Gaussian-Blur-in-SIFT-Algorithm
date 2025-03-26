#ifndef _VP_HPP_
#define _VP_HPP_

#include <systemc>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "cpu.hpp"
#include "interconnect.hpp"
#include "ip_core.hpp"
#include "bram_main.hpp"
#include "bram_tmp.hpp"
#include "kernel_rom.hpp"

class Vp :  public sc_core::sc_module
{
	public:
		Vp(sc_core::sc_module_name name, char** strings, int argc);
		~Vp();

	protected:
	
		Cpu cpu;
		Interconnect interconnect;
		Ip_Core ip_core;
		Main_Bram main_bram;
		Tmp_Bram tmp_bram;
		Kernel_Rom kernel_rom;
};

#endif 
