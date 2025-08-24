#include <iostream>
#include <cstdint>
#include <optional>

#include "app_functions.hpp"

#include "res_file_img_width_116_height_111_offset_up_9_offset_down_9_input.h"
#include "res_file_img_width_220_height_189_offset_up_5_offset_down_0_input.h"
#include "res_file_img_width_224_height_199_offset_up_0_offset_down_0_input.h"
#include "res_file_img_width_240_height_79_offset_up_0_offset_down_8_input.h"
#include "res_file_img_width_260_height_53_offset_up_0_offset_down_0_input.h"
#include "res_file_img_width_264_height_169_offset_up_0_offset_down_0_input.h"

#include "res_file_img_width_116_height_111_offset_up_9_offset_down_9_output.h"
#include "res_file_img_width_220_height_189_offset_up_5_offset_down_0_output.h"
#include "res_file_img_width_224_height_199_offset_up_0_offset_down_0_output.h"
#include "res_file_img_width_240_height_79_offset_up_0_offset_down_8_output.h"
#include "res_file_img_width_260_height_53_offset_up_0_offset_down_0_output.h"
#include "res_file_img_width_264_height_169_offset_up_0_offset_down_0_output.h"

void run_test(
    const uint16_t *image_data,
    const uint16_t *result_data,
    uint16_t width, uint16_t height,
    uint16_t offset_up, uint16_t offset_down,
    uint16_t img_per_octave,
    uint16_t *end_buffer,
    const char* image_name)
{
	int incorrect = 0;
	int correct = 0;
	int zeros = 0;

     std::cout << std::endl << "--------------- TEST OF " << image_name << " ---------------" << std::endl;

     write_hard(IMG_WIDTH_REG_OFFSET, width);
     write_hard(IMG_HEIGHT_REG_OFFSET, height);
     write_hard(IMG_OFFSET_UP_REG_OFFSET, offset_up);
     write_hard(IMG_OFFSET_DOWN_REG_OFFSET, offset_down);
     write_hard(IMG_OCTAVE_NUM_REG_OFFSET, img_per_octave);
     std::cout << "Image data sent." << std::endl;

     write_hard(RESET_REG_OFFSET, 1);
     std::cout << "Reset signal sent." << std::endl;
     while (true) 
     {
          std::optional<uint16_t> ready = read_hard(READY_REG_OFFSET);
          if (ready && ready.value()) break;
     }

     std::optional<uint16_t> width_read = read_hard(IMG_WIDTH_REG_OFFSET);
     std::optional<uint16_t> height_read = read_hard(IMG_HEIGHT_REG_OFFSET);
     std::optional<uint16_t> offset_up_read = read_hard(IMG_OFFSET_UP_REG_OFFSET);
     std::optional<uint16_t> offset_down_read = read_hard(IMG_OFFSET_DOWN_REG_OFFSET);
     std::optional<uint16_t> img_per_octave_read = read_hard(IMG_OCTAVE_NUM_REG_OFFSET);
     std::cout << "Image data read." << std::endl;

	if(width_read)           {std::cout << "Width in core is: " << width_read;}
	if(height_read)          {std::cout << "Height in core is: " << height_read;}
	if(offset_up_read)       {std::cout << "Offset up in core is: " << offset_up_read;}
	if(offset_down_read)     {std::cout << "Offset down core is: " << offset_down_read;}
	if(img_per_octave_read)  {std::cout << "Imgs pre octave in core is: " << img_per_octave_read;}

     write_bram(image_data, width*height);
     std::cout << "Image sent to BRAM." << std::endl;

     write_hard(START_REG_OFFSET, 1);
     std::cout << "Start signal sent." << std::endl;
     while (true) 
     {
          std::optional<uint16_t> ready = read_hard(READY_REG_OFFSET);
          if (ready && ready.value()) break;
     }
     std::cout << "IP finished." << std::endl;

	read_bram(end_buffer, (width*(height - offset_up - offset_down)));
     std::cout << "Image read!" << std::endl;

	// Compare results
	for(uint16_t i = 0; i < width*(height - offset_up - offset_down); i++)
	{
		if(end_buffer[i] < result_data[i] - 1 || end_buffer[i] > result_data[i] + 1)
			incorrect++;
		else
			correct++;
		if(end_buffer[i] == 0)
			zeros++;
	}

	std::cout << "Correct: " << correct << ", Incorrect: " << incorrect << ", Zeros: " << zeros << std::endl;

     std::cout << std::endl << "--------------- TEST OF " << image_name << " FINISHED ---------------" << std::endl;
}

int main()
{
     std::cout << "------------------------------------" << std::endl;
	std::cout << "--- GAUSSIAN BLUR IP CORE ---" << std::endl;
	std::cout << "------------------------------------" << std::endl << std::endl;

     run_test(image_data0, result_data0, IMG0_WIDTH_C, IMG0_HEIGHT_C, IMG0_OFFSET_UP_C, IMG0_OFFSET_DOWN_C, IMG0_OCTAVE_C, end_buffer0, "IMAGE 0");
	run_test(image_data1, result_data1, IMG1_WIDTH_C, IMG1_HEIGHT_C, IMG1_OFFSET_UP_C, IMG1_OFFSET_DOWN_C, IMG1_OCTAVE_C, end_buffer1, "IMAGE 1");
	run_test(image_data2, result_data2, IMG2_WIDTH_C, IMG2_HEIGHT_C, IMG2_OFFSET_UP_C, IMG2_OFFSET_DOWN_C, IMG2_OCTAVE_C, end_buffer2, "IMAGE 2");
	run_test(image_data3, result_data3, IMG3_WIDTH_C, IMG3_HEIGHT_C, IMG3_OFFSET_UP_C, IMG3_OFFSET_DOWN_C, IMG3_OCTAVE_C, end_buffer3, "IMAGE 3");
	run_test(image_data4, result_data4, IMG4_WIDTH_C, IMG4_HEIGHT_C, IMG4_OFFSET_UP_C, IMG4_OFFSET_DOWN_C, IMG4_OCTAVE_C, end_buffer4, "IMAGE 4");
	run_test(image_data5, result_data5, IMG5_WIDTH_C, IMG5_HEIGHT_C, IMG5_OFFSET_UP_C, IMG5_OFFSET_DOWN_C, IMG5_OCTAVE_C, end_buffer5, "IMAGE 5");

     return 0;
}



