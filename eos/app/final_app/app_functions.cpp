#include <iostream>
#include <cinttypes>
#include <cmath>

#include "app_functions.hpp"

// Funkcija za konverziju float vrednosti u Q1_15 format koji se koristi u IP jezgru
uint16_t floatToQ1_15(const float &value) {
    if (value < 0.0f || value >= 2.0f) {
        std::cout << "Value of pixel is out of [0, 2.0] bounds." << std::endl;
    }
    return static_cast<uint16_t>(std::round(value * (1 << 15)));
}

// Funkcija za konvertiju Q1_15 formata u float format
float q1_15ToFloat(const uint16_t &value) {
    return static_cast<float>(value) / (1 << 15);
}

void write_bram(const Image &image) {
    
    // Ako je slika veca od dozvoljenog
    if(image.height*image.width > MAX_BRAM_SIZE) {
        std::cout << "Slika je veca od " << MAX_BRAM_SIZE << "piksela.\n";
        return;
    }
    
    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "w");
    if (!main_bram_file) {
		std::cout << "Nemoguce otvoriti /dev/main_bram_ctrl." << std::endl;
		return;
	}
    // Iskljuci buffering
    setvbuf(main_bram_file, NULL, _IONBF, 0);

    for (int y = 0; y < image.height; ++y) {
        for (int x = 0; x < image.width; x += 2) {
            float pix1 = image.get_pixel(x, y, 0);
            float pix2 = (x + 1 < image.width) ? image.get_pixel(x + 1, y, 0) : 0.0f;

            uint16_t upper16bits = floatToQ1_15(pix1);
            uint16_t lower16bits = floatToQ1_15(pix2);

            uint32_t packed = (static_cast<uint32_t>(upper16bits) << 16) | lower16bits;

            // Indeks identican kao u prvoj funkciji
            uint16_t linear_index = y * image.width + x;
            std::fprintf(main_bram_file, "%" PRIu32 ", %" PRIu16 "\n", packed, linear_index / 2);
        }
    }

    std::fclose(main_bram_file);
}

void read_bram(Image &image) {
    // Ako je slika veca od dozvoljenog
    if(image.height*image.width > MAX_BRAM_SIZE) {
        std::cout << "Slika je veca od " << MAX_BRAM_SIZE << "piksela.\n";
        return;
    }

    FILE* main_bram_file = std::fopen("/dev/main_bram_ctrl", "r");
    if (!main_bram_file) {
		std::cout << "Nemoguce otvoriti /dev/main_bram_ctrl." << std::endl;
		return;
	}

    for (int y = 0; y < image.height; ++y) {
        for (int x = 0; x < image.width; x += 2) {
            uint32_t packed = 0;

            // citanje 2 spojena piksela iz BRAM-a
            if (std::fscanf(main_bram_file, "%" PRIu32 " ", &packed) != 1) {
                std::cerr << "Greska u citanju BRAM-a na poziciji y=" << y << ", x=" << x << "\n";
                break;
            }
            float pix1 = q1_15ToFloat(static_cast<uint16_t>((packed >> 16) & 0xFFFF));
            float pix2 = q1_15ToFloat(static_cast<uint16_t>(packed & 0xFFFF));

            // Upis nazad u sliku
            image.set_pixel(x, y, 0, pix1);
            if (x + 1 < image.width)
                image.set_pixel(x + 1, y, 0, pix2);
        }
    }
    
    std::fclose(main_bram_file);
}

void write_hard(const uint16_t& addr, const uint16_t& val) {
    if((addr % 4) != 0) {
        std::cerr << "Greska u adresi " << addr << ". Adresa mora biti deljiva sa 4.\n";
        return;
    }
    
    FILE* gaussian_blur_core_file = std::fopen("/dev/gaussian_blur_core", "w");
    if (!gaussian_blur_core_file) {
		std::cout << "Nemoguce otvoriti /dev/gaussian_blur_core." << std::endl;
		return;
	}
    // Iskljuci buffering
    setvbuf(gaussian_blur_core_file, NULL, _IONBF, 0);

    std::fprintf(gaussian_blur_core_file, "%" PRIu32 ", %" PRIu16 "\n", val, addr);
    std::fclose(gaussian_blur_core_file);
}

std::optional<uint16_t> read_hard(const uint16_t& addr) {
    if((addr % 4) != 0) {
        std::cerr << "Greska u adresi " << addr << ". Adresa mora biti deljiva sa 4.\n";
        return std::nullopt;
    }
    
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
    // Iskljuci buffering
    setvbuf(main_bram_file, NULL, _IONBF, 0);

    for (uint16_t i = 0; i < 60000; i += 2) {
        std::fprintf(main_bram_file, "%" PRIu32 ", %" PRIu16 "\n", 0, i/2);
    }

    std::fclose(main_bram_file);
}
