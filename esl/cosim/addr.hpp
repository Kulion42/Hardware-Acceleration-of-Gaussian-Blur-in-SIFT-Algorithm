#ifndef ADDR_HPP
#define ADDR_HPP

#ifndef SC_INCLUDE_FX
#define SC_INCLUDE_FX
#endif

#include <systemc>
#include <tlm>

typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
typedef tlm::tlm_base_protocol_types::tlm_phase_type ph_t;

//registers in Ip_hard
#define ADDR_IMG_WIDTH 0x00
#define ADDR_IMG_HEIGHT 0x04
#define ADDR_IMG_OFFSET_UP 0x08
#define ADDR_IMG_OFFSET_DOWN 0x0C
#define ADDR_NUM_IMG_OCT 0x10
#define ADDR_RESET 0X14
#define ADDR_START 0x18
#define ADDR_READY 0x1C

//bram size is 240KB
#define BRAM_SIZE 0x3A980

// offset
#define DELAY 8

// 32-bit data bus, 4 bytes,
#define BUS_WIDTH 4

// locations for memory and ip 
#define VP_ADDR_MAIN_BRAM_L 0x40000000
#define VP_ADDR_MAIN_BRAM_H 0x40000000 + BRAM_SIZE/2

#define VP_ADDR_TMP_BRAM_L 0x42000000
#define VP_ADDR_TMP_BRAM_H 0x42000000 + BRAM_SIZE/2 

#define VP_ADDR_IP_CORE_L 0x44000000
#define VP_ADDR_IP_CORE_H 0x4400FFFF 

#endif // ADDR_HPP
