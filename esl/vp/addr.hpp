#ifndef ADDR_HPP
#define ADDR_HPP

#include <systemc>
#include <tlm>

typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
typedef tlm::tlm_base_protocol_types::tlm_phase_type ph_t;

//registers in Ip_hard
#define ADDR_IMG_WIDTH 0x00
#define ADDR_IMG_HEIGHT 0x01
#define ADDR_IMG_OFFSET_UP 0x02
#define ADDR_IMG_OFFSET_DOWN 0x03
#define ADDR_NUM_IMG_OCT 0x04
#define ADDR_RESET 0X05
#define ADDR_START 0x06
#define ADDR_READY 0x07

//bram size is 240KB
#define BRAM_SIZE 0x3A980
#define KERNEL_SIZE 0x14
#define SIGMA_SIZE 0x06

// macro for offset (DELAY = T = 1/f = 1/100MHz = 10ns)
#define DELAY 10

// 32-bit data bus, 4 bytes,
#define BUS_WIDTH 4

// locations for memory and ip 
#define VP_ADDR_MAIN_BRAM_L 0x00000000
#define VP_ADDR_MAIN_BRAM_H 0x00000000 + BRAM_SIZE/2

#define VP_ADDR_TMP_BRAM_L 0x10000000
#define VP_ADDR_TMP_BRAM_H 0x10000000 + BRAM_SIZE/2 - KERNEL_SIZE

#define VP_ADDR_KERNEL_BRAM_L 0x11000000
#define VP_ADDR_KERNEL_BRAM_H 0x11000000 + KERNEL_SIZE

#define VP_ADDR_SIGMA_ROM_L 0x20000000
#define VP_ADDR_SIGMA_ROM_H 0x20000000 + SIGMA_SIZE

#define VP_ADDR_IP_CORE_L 0x40000000
#define VP_ADDR_IP_CORE_H 0x40000010 

#endif // ADDR_HPP
