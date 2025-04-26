#include <iostream>
#include <cinttypes>

#include "app_functions.h"

void write_bram(const uint16_t* val, int length) {

    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "w");
    if (!main_bram_file)
	{
		std::cout << "Could not open /dev/main_bram_ctrl." << std::endl;
		return;
	}

    std::fflush(main_bram_file);

    for (uint16_t i = 0; i < length; i += 2) {
        uint32_t packed = (static_cast<uint32_t>(val[i + 1]) << 16) | val[i];
        std::fprintf(main_bram_file, "%" PRIu32 ", %" PRIu16 "\n", packed, i/2);
        std::fflush(main_bram_file);
    }

    std::fclose(main_bram_file);
}

void read_bram(uint16_t* val, int length) {
    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "r");
    if (!main_bram_file)
	{
		std::cout << "Could not open /dev/main_bram_ctrl." << std::endl;
		return;
	}

    uint32_t packed = 0;

    for (int i = 0; i < length; i += 2) {
        std::fscanf(main_bram_file, "%" PRIu32 " ", &packed);
        val[i]     = static_cast<uint16_t>(packed & 0xFFFF);
        val[i + 1] = static_cast<uint16_t>((packed >> 16) & 0xFFFF);
    }
    
    std::fscanf(main_bram_file, "\n");
    std::fclose(main_bram_file);
}

void write_hard(uint16_t addr, uint16_t val) {
    FILE* gaussian_blur_core_file = std::fopen("/dev/gaussian_blur_core", "w");
    if (!gaussian_blur_core_file) 
	{
		std::cout << "Could not open /dev/gaussian_blur_core." << std::endl;
		return;
	}

    std::fprintf(gaussian_blur_core_file, "%" PRIu32 ", %" PRIu16 "\n", val, addr);
    std::fflush(gaussian_blur_core_file);
    std::fclose(gaussian_blur_core_file);
}

std::optional<uint16_t> read_hard(uint16_t addr) {
    FILE* gaussian_blur_core_file = std::fopen("/dev/gaussian_blur_core", "r");
    if (!gaussian_blur_core_file)
	{
		std::cout << "Could not open /dev/gaussian_blur_core." << std::endl;
		return std::nullopt;
	}

    uint16_t val[8] = {};
    unsigned char index = addr / 4;

    std::fscanf(gaussian_blur_core_file,
        "%" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 "\n",
        &val[0], &val[1], &val[2], &val[3], &val[4], &val[5], &val[6], &val[7]);

    std::fclose(gaussian_blur_core_file);

    return val[index];
}

void clear_bram()
{
    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "w");
    if (!main_bram_file)
	{
		std::cout << "Could not open /dev/main_bram_ctrl." << std::endl;
		return;
	}

    std::fflush(main_bram_file);

    for (uint16_t i = 0; i < 60000; i += 2) {
        std::fprintf(main_bram_file, "%" PRIu32 ", %" PRIu16 "\n", 0, i/2);
        std::fflush(main_bram_file);
    }

    std::fclose(main_bram_file);
}