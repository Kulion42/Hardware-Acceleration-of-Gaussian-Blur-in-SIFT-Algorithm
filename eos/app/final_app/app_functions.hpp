#include <cstdint>
#include <cstdio>
#include <string>
#include <optional>

#include "image.hpp"

#define IMG_WIDTH_REG_OFFSET 0
#define IMG_HEIGHT_REG_OFFSET 4
#define IMG_OFFSET_UP_REG_OFFSET 8
#define IMG_OFFSET_DOWN_REG_OFFSET 12
#define IMG_OCTAVE_NUM_REG_OFFSET 16
#define RESET_REG_OFFSET 20
#define START_REG_OFFSET 24
#define READY_REG_OFFSET 28

#define MAX_BRAM_SIZE 50000

uint16_t floatToQ2_14(const float &value);
float q2_14ToFloat(const uint16_t &value);
void write_bram(const Image &image, const uint32_t& length);
void read_bram(Image &image, const uint32_t& length);
void write_hard(const uint16_t& addr, const uint16_t& val);
std::optional<uint16_t> read_hard(const uint16_t& addr);
void clear_bram();