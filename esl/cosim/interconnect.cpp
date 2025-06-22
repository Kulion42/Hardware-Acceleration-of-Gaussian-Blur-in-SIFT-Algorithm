#include "interconnect.hpp"

using namespace std;
using namespace tlm;

Interconnect::Interconnect(sc_core::sc_module_name name)
  : sc_module(name),
   offset(sc_core::SC_ZERO_TIME),
   ip_core_socket("ip_core_socket"),
   cpu_socket("cpu_socket")
{
  ip_core_socket(*this);
  cpu_socket(*this);
  SC_REPORT_INFO("Interconnect", "Constructed.");
}

Interconnect::~Interconnect()
{
  SC_REPORT_INFO("Interconnect", "Destroyed.");
}

void Interconnect::b_transport(pl_t &pl, sc_core::sc_time &offset)
{
  sc_dt::uint64 addr = pl.get_address(); 
  //sc_dt::uint64 taddr = addr & 0x00FFFFFF; 

	if (addr >= VP_ADDR_IP_CORE_L && addr <= VP_ADDR_IP_CORE_H)
	{
		//pl.set_address(taddr);
		ip_core_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else if (addr >= VP_ADDR_MAIN_BRAM_L && addr <= VP_ADDR_MAIN_BRAM_H)
	{
		//pl.set_address(taddr);
		ip_core_socket->b_transport(pl, offset);
		pl.set_address(addr);
	}
	else
	{
	    std::cout << std::hex << addr << std::endl;
		SC_REPORT_ERROR("Interconnect", "Wrong address.");
		pl.set_response_status ( tlm::TLM_ADDRESS_ERROR_RESPONSE );
		offset += sc_core::sc_time(5*DELAY, sc_core::SC_NS);
	}
}
tlm_sync_enum  Interconnect::nb_transport_bw(pl_t& pl, ph_t& phase, sc_time& offset)
{
	return tlm::TLM_ACCEPTED;
}

void Interconnect::invalidate_direct_mem_ptr(uint64  start, uint64  end)
{
	
}

tlm_sync_enum Interconnect::nb_transport_fw(pl_t& pl, ph_t& phase, sc_time& offset)
{
	return tlm::TLM_ACCEPTED;
}

bool Interconnect::get_direct_mem_ptr(pl_t& pl, tlm_dmi& dmi)
{
	return true;
}

unsigned int Interconnect::transport_dbg(pl_t &)
{
	return 0;
}
