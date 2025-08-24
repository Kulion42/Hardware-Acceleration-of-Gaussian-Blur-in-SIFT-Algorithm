/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <unistd.h>

#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_mmu.h"
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_cache.h"

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


#define IMG_WIDTH_OFFSET 0
#define IMG_HEIGHT_OFFSET 4
#define IMG_OFFSET_UP_OFFSET 8
#define IMG_OFFSET_DOWN_OFFSET 12
#define IMG_PER_OCTAVE_OFFSET 16
#define RESET_REG_OFFSET 20
#define START_REG_OFFSET 24
#define READY_REG_OFFSET 28

#define ADDR_FACTOR 4

void run_test(
    const uint16_t *image_data,
    const uint16_t *result_data,
    uint16_t width, uint16_t height,
    uint16_t offset_up, uint16_t offset_down,
    uint16_t img_per_octave,
    uint16_t *end_buffer,
    const char* image_name)
{
	float d1, d2, d3, d4, d5, d6;
	int incorrect = 0;
	int correct = 0;
	int zeros = 0;

	XTime p0_time, p1_time;
	XTime p2_time, p3_time;
	XTime p4_time, p5_time;
	XTime p6_time, p7_time;
	XTime p8_time, p9_time;

	XTime *p_p0_time = &p0_time;
	XTime *p_p1_time = &p1_time;
	XTime *p_p2_time = &p2_time;
	XTime *p_p3_time = &p3_time;
	XTime *p_p4_time = &p4_time;
	XTime *p_p5_time = &p5_time;
	XTime *p_p6_time = &p6_time;
	XTime *p_p7_time = &p7_time;
	XTime *p_p8_time = &p8_time;
	XTime *p_p9_time = &p9_time;

    printf("\n--------------- TEST OF %s ---------------\n", image_name);

    // Time of start of sending parameters to the IP core
    XTime_GetTime(p_p0_time);

	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, width);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, height);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, offset_up);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, offset_down);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, img_per_octave);

	// Time after parameters were sent and beggining of reset
	XTime_GetTime(p_p1_time);

	// Reset of the system
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Time after reset and at the beggining of reading parameters
	XTime_GetTime(p_p2_time);

	//------------------------Read parameters from AXI LITE---------------------------------
	uint16_t width_read = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET);
	uint16_t height_read = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET);
	uint16_t offset_up_read = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET);
	uint16_t offset_down_read = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET);
	uint16_t img_per_octave_read = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET);

	//Time after parameters were read
	XTime_GetTime(p_p3_time);

	printf("Width in core is: %d.\n", width_read);
	printf("Height in core is: %d.\n", height_read);
	printf("Offset up in core is: %d.\n", offset_up_read);
	printf("Offset down core is: %d.\n", offset_down_read);
	printf("Imgs pre octave in core is: %d.\n", img_per_octave_read);

	//Beggining of sending image to main BRAM
	XTime_GetTime(p_p4_time);
	//------------------------Write image to BRAM---------------------------------
	for (uint16_t i = 0; i < width*height; i+=2)
	{
		uint32_t packed = (image_data[i] << 16) | image_data[i+1];
		Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*i, packed);
	}
	//End of sending image to main BRAM
	XTime_GetTime(p_p5_time);

	printf("Image sent to main BRAM!\n");

	printf("Starting IP!\n");

	//Time of starting the IP Core
	XTime_GetTime(p_p6_time);
	//------------------------Start Guassian Blur IP---------------------------------
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 1);
	while(Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	//Time when the IP Core finished processing image
	XTime_GetTime(p_p7_time);

	printf("IP finished!\n");

	//Start time for reading the image from BRAM
	XTime_GetTime(p_p8_time);
	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < width*(height - offset_up - offset_down)-1; j+=2)
	{
		uint32_t packed = Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer[j+1] = packed & 0xFFFF;
		end_buffer[j] = (packed >> 16) & 0xFFFF;
	}
	//End time for reading the image from BRAM
	XTime_GetTime(p_p9_time);
	printf("Image read!\n");

	// Compare results
	for(uint16_t j = 0; j < width*(height - offset_up - offset_down); j++)
	{
		if(end_buffer[j] < result_data[j] - 1 || end_buffer[j] > result_data[j] + 1)
			incorrect++;
		else
			correct++;
		if(end_buffer[j] == 0)
			zeros++;
	}

	printf("Correct: %d, Incorrect: %d, Zeros: %d\n", correct, incorrect, zeros);

	// Duration of sending the parameters to IP core
	d1 = 1.0 * ((int) p1_time - (int) p0_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of the reset of the system
	d2 = 1.0 * ((int) p2_time - (int) p1_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of reading the parameters from IP core
	d3 = 1.0 * ((int) p3_time - (int) p2_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of the sending image to the main BRAM
	d4 = 1.0 * ((int) p5_time - (int) p4_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of IP core processing the image
	d5 = 1.0 * ((int) p7_time - (int) p6_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of reading processed image from main BRAM
	d6 = 1.0 * ((int) p9_time - (int) p8_time) / (COUNTS_PER_SECOND / 1000000);

	printf("Duration of sending the parameters to IP core is %.2f[us].\n", d1);
	printf("Duration of the reset of the system is %.2f[us].\n", d2);
	printf("Duration of reading the parameters from IP core is %.2f[us].\n", d3);
	printf("Duration of the sending image to the main BRAM is %.2f[us].\n", d4);
	printf("Duration of IP core processing the image is %.2f[us].\n", d5);
	printf("Duration of reading processed image from main BRAM is %.2f[us].\n", d6);

    printf("--------------- TEST OF %s FINISHED ---------------\n\n", image_name);
}

int main()
{
    init_platform();
    Xil_DCacheDisable();
    Xil_ICacheDisable();

    // Enabling burst-mode of AXI BRAM Controller
	Xil_SetTlbAttributes(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR, 0x15de6);

	printf("------------------------------------\n");
	printf("--- GAUSSIAN BLUR IP CORE ---\n");
	printf("------------------------------------\n\n");

	run_test(image_data0, result_data0, IMG0_WIDTH_C, IMG0_HEIGHT_C, IMG0_OFFSET_UP_C, IMG0_OFFSET_DOWN_C, IMG0_OCTAVE_C, end_buffer0, "IMAGE 0");
	run_test(image_data1, result_data1, IMG1_WIDTH_C, IMG1_HEIGHT_C, IMG1_OFFSET_UP_C, IMG1_OFFSET_DOWN_C, IMG1_OCTAVE_C, end_buffer1, "IMAGE 1");
	run_test(image_data2, result_data2, IMG2_WIDTH_C, IMG2_HEIGHT_C, IMG2_OFFSET_UP_C, IMG2_OFFSET_DOWN_C, IMG2_OCTAVE_C, end_buffer2, "IMAGE 2");
	run_test(image_data3, result_data3, IMG3_WIDTH_C, IMG3_HEIGHT_C, IMG3_OFFSET_UP_C, IMG3_OFFSET_DOWN_C, IMG3_OCTAVE_C, end_buffer3, "IMAGE 3");
	run_test(image_data4, result_data4, IMG4_WIDTH_C, IMG4_HEIGHT_C, IMG4_OFFSET_UP_C, IMG4_OFFSET_DOWN_C, IMG4_OCTAVE_C, end_buffer4, "IMAGE 4");
	run_test(image_data5, result_data5, IMG5_WIDTH_C, IMG5_HEIGHT_C, IMG5_OFFSET_UP_C, IMG5_OFFSET_DOWN_C, IMG5_OCTAVE_C, end_buffer5, "IMAGE 5");

	printf("\n--------------- EXIT ---------------\n");
	printf("------------------------------------\n\n\n\n");

    cleanup_platform();
    return 0;
}
