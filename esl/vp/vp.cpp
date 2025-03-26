#include "vp.hpp"

 sc_core::sc_time offset_system;

Vp:: Vp (sc_core::sc_module_name name, char** strings, int argc): 
	sc_module (name),
	cpu("Cpu", strings, argc),
	ip_core("IP_Core"),
	interconnect("Interconnect"),
	main_bram("Main_BRAM"),
	tmp_bram("Tmp_BRAM"),
	kernel_rom("Kernel_ROM")
{
	cpu.interconnect_socket.bind(interconnect.cpu_socket);
	
	interconnect.ip_core_socket.bind(ip_core.interconnect_socket);
	interconnect.main_bram_socket.bind(main_bram.interconnect_socket);
	
	ip_core.main_bram_socket.bind(main_bram.ip_core_socket);
	ip_core.tmp_bram_socket.bind(tmp_bram.ip_core_socket);
    ip_core.kernel_rom_socket.bind(kernel_rom.ip_core_socket);
    
	SC_REPORT_INFO("Virtual Platform", "Constructed.");
}

Vp::~Vp()
{
 	SC_REPORT_INFO("Virtual Platform", "Destroyed.");
}


