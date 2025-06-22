#include "ip_core.hpp"


using namespace std;
using namespace sc_dt;
using namespace sc_core;

SC_HAS_PROCESS(Ip_Core);

Ip_Core::Ip_Core(sc_module_name name):
	sc_module(name),
	interconnect_socket("interconnect_socket"),
	top("TOP"),
	clk("clk", DELAY, SC_NS)
	
{
	    interconnect_socket(*this);
	    top.clk(clk.signal()) ;
		top.reset(reset) ;
		top.start(start) ;
		
		top.img_height(img_height) ;
        top.img_width(img_width) ;
        top.img_offset_up(img_offset_up) ;
        top.img_offset_down(img_offset_down) ;
        top.img_per_octave(img_per_octave) ;
        
        top.main_bram_a_cpu_en(main_bram_a_cpu_en) ;
        top.main_bram_a_cpu_we(main_bram_a_cpu_we) ;
        top.main_bram_a_cpu_addr(main_bram_a_cpu_addr) ;
        top.main_bram_a_cpu_rdata(main_bram_a_cpu_rdata) ;
        top.main_bram_a_cpu_wdata(main_bram_a_cpu_wdata) ;
        
        top.ready(ready) ;
        
        
        
        reset.write(static_cast<sc_logic> (0)) ;
		start.write(static_cast<sc_logic> (0)) ; 
		
		img_height.write(static_cast< sc_lv<16> > (0)) ;
        img_width.write(static_cast< sc_lv<16> > (0)) ;
        img_offset_up.write(static_cast< sc_lv<16> > (0)) ;
        img_offset_down.write(static_cast< sc_lv<16> > (0)) ;
        img_per_octave.write(static_cast< sc_lv<16> > (0)) ;
        
        main_bram_a_cpu_en.write(static_cast<sc_logic> (0)) ;
        main_bram_a_cpu_we.write(static_cast< sc_lv<4> > (0)) ;
        main_bram_a_cpu_addr.write(static_cast< sc_lv<15> > (0)) ;
        main_bram_a_cpu_wdata.write(static_cast< sc_lv<32> > (0)) ;
        
	SC_REPORT_INFO("IP Core", "Constructed.");
}

Ip_Core::~Ip_Core()
{
	SC_REPORT_INFO("IP Core", "Destroyed.");
}


void Ip_Core::b_transport(pl_t &pl, sc_time &offset)
{
	
	tlm::tlm_command command = pl.get_command();
 	sc_dt::uint64 addr = pl.get_address();
	sc_dt::uint64 taddr;
	unsigned int length = pl.get_data_length();
 	unsigned char *buf = pl.get_data_ptr();
 	pl.set_response_status( tlm::TLM_OK_RESPONSE );
 	
	switch(command)
 	{	
	 	case tlm::TLM_WRITE_COMMAND:
			if (addr == VP_ADDR_IP_CORE_L + ADDR_START)
			{
				start.write(static_cast<sc_logic> (toInt2(buf)));
				//cout << "Write " << toInt1(buf) << " in start"<<endl;
				printf("write %d in start\n", toInt1(buf));
				wait(DELAY, SC_NS);
			}
			else if (addr == VP_ADDR_IP_CORE_L + ADDR_RESET)
			{
				reset.write(static_cast<sc_logic> (toInt2(buf)));
				//cout << "Write " << toInt1(buf) << " in reset"<<endl;
				printf("write %d in reset\n", toInt1(buf));
				wait(DELAY, SC_NS);
			}
			else if (addr == VP_ADDR_IP_CORE_L + ADDR_IMG_WIDTH)
			{
				img_width.write(static_cast< sc_lv<16> > (toInt2(buf)));
				//cout << "Write " << toIn2t(buf) << " in img_width"<<endl;
				printf("write %d in img_width\n", toInt2(buf));
				wait(DELAY, SC_NS);
			}
			else if (addr == VP_ADDR_IP_CORE_L + ADDR_IMG_HEIGHT)
			{
				img_height.write(static_cast< sc_lv<16> > (toInt2(buf)));
				//cout << "Write " << toInt2(buf) << " in img_height"<<endl;
				printf("write %d in img_height\n", toInt2(buf));
				wait(DELAY, SC_NS);
			}
			else if (addr == VP_ADDR_IP_CORE_L + ADDR_IMG_OFFSET_UP)
			{
				img_offset_up.write(static_cast< sc_lv<16> > (toInt2(buf)));
				//cout << "Write " << toInt2(buf) << " in img_offset_up"<<endl;
				printf("write %d in img_offset_up\n", toInt2(buf));
				wait(DELAY, SC_NS);
			}
			else if (addr == VP_ADDR_IP_CORE_L + ADDR_IMG_OFFSET_DOWN)
			{
				img_offset_down.write(static_cast< sc_lv<16> > (toInt2(buf)));
				//cout << "Write " << toInt2(buf) << " in img_offset_down"<<endl;
				printf("write %d in img_offset_down\n", toInt(buf));
				wait(DELAY, SC_NS);
			}
			else if (addr == VP_ADDR_IP_CORE_L + ADDR_NUM_IMG_OCT)
			{
				img_per_octave.write(static_cast< sc_lv<16> > (toInt2(buf)));
				//cout << "Write " << toInt2(buf) << " in num_img_oct"<<endl;
				printf("write %d in img_per_ocatve\n", toInt(buf));
				wait(DELAY, SC_NS);
			}
			else if (addr >= VP_ADDR_MAIN_BRAM_L and addr <= VP_ADDR_MAIN_BRAM_H)
			{
				taddr = addr - VP_ADDR_MAIN_BRAM_L;
				main_bram_a_cpu_en.write(static_cast<sc_logic> (1)) ;
                main_bram_a_cpu_we.write(static_cast< sc_lv<4> > (15)) ;
                main_bram_a_cpu_addr.write(static_cast< sc_lv<15> > (taddr/4)) ;
                main_bram_a_cpu_wdata.write(static_cast< sc_lv<32> > (toInt(buf))) ;
                
				wait(DELAY, SC_NS);
				main_bram_a_cpu_we.write(static_cast< sc_lv<4> > (0));
				main_bram_a_cpu_en.write(static_cast<sc_logic> (0)) ;
                printf("write %X in addres %d of main bram\n", toInt(buf), taddr/4);
			}
			else
			{
				pl.set_response_status( tlm::TLM_ADDRESS_ERROR_RESPONSE );
				cout << "Wrong write address!" << endl;
			}
			break;
		case tlm::TLM_READ_COMMAND:
			if (addr == VP_ADDR_IP_CORE_L + ADDR_READY)
			{
				wait(DELAY, SC_NS);
				if (ready.read() == '1')
				{
					toUchar1(buf, 1);
					//printf("read %d from ready\n", toInt(buf));
				}				
				else
				{
					toUchar1(buf, 0);
					//printf("read %d from ready\n", toInt(buf));
				}			

			}
			else if (addr >= VP_ADDR_MAIN_BRAM_L and addr <= VP_ADDR_MAIN_BRAM_H)
			{
				taddr = addr - VP_ADDR_MAIN_BRAM_L;
				main_bram_a_cpu_en.write(static_cast<sc_logic> (1)) ;
				main_bram_a_cpu_addr.write(static_cast< sc_lv<15> > (taddr/4)) ;
				wait(DELAY, SC_NS);
				toUchar4(buf, static_cast< sc_uint<32> > (main_bram_a_cpu_rdata.read()));
				main_bram_a_cpu_en.write(static_cast<sc_logic> (0)) ;
				printf("read %X from addres %d of main bram\n", toInt(buf), taddr/4);
			}
			else
			{
				pl.set_response_status( tlm::TLM_ADDRESS_ERROR_RESPONSE );
				cout << "Wrong read address!" << endl;
				printf("Wrong read address!\n");
			}
			break;
		default:
			pl.set_response_status( tlm::TLM_COMMAND_ERROR_RESPONSE );
			cout << "Wrong command!" << endl;
	}
	
	offset += sc_time(DELAY, SC_NS);
}

tlm_sync_enum Ip_Core::nb_transport_fw(pl_t& pl, ph_t& phase, sc_time& offset)
{
	return TLM_ACCEPTED;
}

bool Ip_Core::get_direct_mem_ptr(pl_t& pl, tlm_dmi& dmi)
{
	return true;
}

unsigned int Ip_Core::transport_dbg(pl_t &)
{
	return 0;
}

