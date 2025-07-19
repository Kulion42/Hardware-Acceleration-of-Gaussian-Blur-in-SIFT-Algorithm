#include <iostream>
#include <cinttypes>
#include <cmath>

#include "app_functions.hpp"

// Funkcija za konverziju float vrednosti u Q2_14 format koji se koristi u IP jezgru
uint16_t floatToQ2_14(const float &value) {
    if (value < 0.0f || value >= 4.0f) {
        std::cout << "Value of pixel is out of [0, 4.0] bounds." << std::endl;
    }

    return static_cast<uint16_t>(std::round(value * (1 << 14)));
}

// Funkcija za konvertiju Q2_14 formata u float format
float q2_14ToFloat(const uint16_t &value) {
    return static_cast<float>(value) / (1 << 14);
}

void write_bram(const Image &image) {
    
    // Ako je slika veca od dozvoljenog
    if(image.height*image.width > MAX_BRAM_SIZE) {
        return;
    }
    
    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "w");
    if (!main_bram_file) {
		std::cout << "Nemoguce otvoriti /dev/main_bram_ctrl." << std::endl;
		return;
	}

    std::fflush(main_bram_file);

    // for (uint16_t i = 0; i < length; i += 2) {
        
    //     // Convert 2 pixels from float to Q2_14 format of uint16_t
    //     uint16_t upper16bits = floatToQ2_14(image.data[i]);
    //     uint16_t lower16bits = floatToQ2_14(image.data[i+1]);

    //     // Pack those 2 pixels to uint32_t variable
    //     uint32_t packed = (static_cast<uint32_t>(upper16bits << 16)) | lower16bits;

    //     // Send image to the FPGA bram
    //     std::fprintf(main_bram_file, "%" PRIu32 ", %" PRIu16 "\n", packed, i/2);
    //     std::fflush(main_bram_file);
    // }

    for(int x = 0; x < image.width; x+=2) {    
        for(int y = 0; y < image.height; y++) {
            float pix1 = image.get_pixel(x, y, 0);
            float pix2 = (x + 1 < image.width) ? image.get_pixel(x + 1, y, 0) : 0.0f;
            
            uint16_t upper16bits = floatToQ2_14(pix1);
            uint16_t lower16bits = floatToQ2_14(pix2);

            // Pack those 2 pixels to uint32_t variable
            uint32_t packed = (static_cast<uint32_t>(upper16bits << 16)) | lower16bits;

            // Send image to the FPGA bram
            std::fprintf(main_bram_file, "%" PRIu32 ", %" PRIu16 "\n", packed, (y*image.width + x)/2);
            std::fflush(main_bram_file);
        }
    }   

    std::fclose(main_bram_file);
}

void read_bram(Image &image) {
    
    // Ako je slika veca od dozvoljenog
    if(image.height*image.width > MAX_BRAM_SIZE) {
        return;
    }

    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "r");
    if (!main_bram_file) {
		std::cout << "Nemoguce otvoriti /dev/main_bram_ctrl." << std::endl;
		return;
	}

    // for (int i = 0; i < length; i += 2) {

    //     uint32_t packed = 0;

    //     // Read 2 pixels from BRAM
    //     std::fscanf(main_bram_file, "%" PRIu32 " ", &packed);

    //     // Store 2 pixels to data array of the image
    //     image.data[i + 1] = q2_14ToFloat(static_cast<uint16_t>(packed & 0xFFFF));
    //     image.data[i] = q2_14ToFloat(static_cast<uint16_t>((packed >> 16) & 0xFFFF));
    // }

    for(int x = 0; x < image.width; x+=2) {    
        for(int y = 0; y < image.height; y++) {
                float pix1, pix2;

                uint32_t packed = 0;

                // Read 2 pixels from BRAM
                std::fscanf(main_bram_file, "%" PRIu32 " ", &packed);

                pix1 = q2_14ToFloat(static_cast<uint16_t>((packed >> 16) & 0xFFFF));
                pix2 = q2_14ToFloat(static_cast<uint16_t>(packed & 0xFFFF));

                image.set_pixel(x, y, 0, pix1);
                if(x + 1 < image.width)
                image.set_pixel(x+1, y, 0, pix2);
        }
    }
    
    std::fscanf(main_bram_file, "\n");
    std::fclose(main_bram_file);
}

void write_hard(const uint16_t& addr, const uint16_t& val) {
    FILE* gaussian_blur_core_file = std::fopen("/dev/gaussian_blur_core", "w");
    if (!gaussian_blur_core_file) {
		std::cout << "Nemoguce otvoriti /dev/gaussian_blur_core." << std::endl;
		return;
	}

    std::fprintf(gaussian_blur_core_file, "%" PRIu32 ", %" PRIu16 "\n", val, addr);
    std::fflush(gaussian_blur_core_file);
    std::fclose(gaussian_blur_core_file);
}

std::optional<uint16_t> read_hard(const uint16_t& addr) {
    FILE* gaussian_blur_core_file = std::fopen("/dev/gaussian_blur_core", "r");
    if (!gaussian_blur_core_file) {
		std::cout << "Nemoguce otvoriti /dev/gaussian_blur_core." << std::endl;
		return std::nullopt;
	}
    
    uint16_t val[8] = {};
    uint16_t index = addr / 4;

    int count = std::fscanf(gaussian_blur_core_file,
        "%" SCNu16 " %" SCNu16 " %" SCNu16 " %" SCNu16 " %" SCNu16 " %" SCNu16 " %" SCNu16 " %" SCNu16,
        &val[0], &val[1], &val[2], &val[3], &val[4], &val[5], &val[6], &val[7]);

    std::fclose(gaussian_blur_core_file);

    if (count != 8) {
        // std::cerr << "fscanf error: Procitano " << count << " vrednosti iz /dev/gaussian_blur_core." << std::endl;
        return std::nullopt;
    }

    if (index >= 8) {
        std::cerr << "read_hard(): addr " << addr << " daje pogresan index " << static_cast<int>(index) << std::endl;
        return std::nullopt;
    }

    return val[index];
}

void clear_bram() {
    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "w");
    if (!main_bram_file){
		std::cout << "Nemoguce otvoriti /dev/main_bram_ctrl." << std::endl;
		return;
	}

    std::fflush(main_bram_file);

    for (uint16_t i = 0; i < 60000; i += 2) {
        std::fprintf(main_bram_file, "%" PRIu32 ", %" PRIu16 "\n", 0, i/2);
        std::fflush(main_bram_file);
    }

    std::fclose(main_bram_file);
}
