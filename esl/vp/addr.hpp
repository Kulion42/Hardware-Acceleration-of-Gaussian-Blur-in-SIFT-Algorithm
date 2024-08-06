#ifndef ADDR_HPP
#define ADDR_HPP

#define SC_INCLUDE_FX
#include <systemc>
#include <tlm>

typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
typedef tlm::tlm_base_protocol_types::tlm_phase_type ph_t;

//registers in Ip_hard
#define ADDR_IMG_WIDTH 0x00
#define ADDR_IMG_HEIGHT 0x01
#define ADDR_IMG_OFFSET_UP 0x02
#define ADDR_IMG_OFFSET_DOWN 0x03
#define ADDR_RESET 0X04
#define ADDR_START 0x05
#define ADDR_READY 0x06

//bram size is 240KB
#define BRAM_SIZE 0x3A980
#define KERNEL_SIZE 20
//maximum calculated ip_core memory alocations 2155600=5*(512*512 + 256*256 + 128*128 + 64 *64 + 32*32 + 16*16 + 8*8 + 4*4)  
//#define DATA_SIZE 0x20E450

// macro for offset (DELAY = T = 1/f = 1/100MHz = 10ns)
#define DELAY 10

// 64-bit data bus, 8 bytes,
#define BUS_WIDTH 8

// locations for memory and ip 
#define VP_ADDR_BRAM1_L 0x00000000
#define VP_ADDR_BRAM1_H 0x00000000 + BRAM_SIZE/2

#define VP_ADDR_BRAM2_L 0x10000000
#define VP_ADDR_BRAM2_H 0x10000000 + BRAM_SIZE/2 - KERNEL_SIZE

#define VP_ADDR_KERNEL_L 0x20000000
#define VP_ADDR_KERNEL_H 0x20000000 + KERNEL_SIZE

#define VP_ADDR_IP_HARD_L 0x40000000
#define VP_ADDR_IP_HARD_H 0x40000010 
//#define VP_ADDR_DDR_L 0x80000000
//#define VP_ADDR_DDR_H 0x80000000 + DATA_SIZE

#endif // ADDR_HPP
