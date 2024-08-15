#include "vp.hpp"

Vp:: Vp (sc_core::sc_module_name name, char** strings, int argc): 
	sc_module (name),
	cpu("Cpu", strings, argc),
	ip_core("IP_core"),
	interconnect("Interconnect"),
	main_bram("Main_Bram"),
	tmp_bram("Tmp_Bram"),
	kernel_bram("Kernel_Bram"),
	sigma_rom("Sigma_Rom")
{
	cpu.interconnect_socket.bind(interconnect.cpu_socket);
	
	interconnect.ip_core_isocket.bind(ip_core.interconnect_socket);
	interconnect.main_bram_socket.bind(main_bram.interconnect_socket);
	interconnect.tmp_bram_socket.bind(tmp_bram.ip_core_socket);
	interconnect.kernel_bram_socket.bind(kernel_bram.ip_core_socket);
	interconnect.sigma_rom_socket.bind(sigma_rom.ip_core_socket);
	
	ip_core.mem_socket.bind(interconnect.ip_core_tsocket);

	SC_REPORT_INFO("Virtual Platform", "Constructed.");
}

Vp::~Vp()
{
 	SC_REPORT_INFO("Virtual Platform", "Destroyed.");
}


