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

#include "test_image.h"
//#include "test_image_small.h"

#define IMG_WIDTH_OFFSET 0
#define IMG_HEIGHT_OFFSET 4
#define IMG_OFFSET_UP_OFFSET 8
#define IMG_OFFSET_DOWN_OFFSET 12
#define IMG_PER_OCTAVE_OFFSET 16
#define RESET_REG_OFFSET 20
#define START_REG_OFFSET 24
#define READY_REG_OFFSET 28

#define ADDR_FACTOR 4


int main()
{
    init_platform();
    Xil_DCacheDisable();
    Xil_ICacheDisable();


    float d1;

    XTime p0_time, p1_time;
    //XTime p2_time, p3_time;
    XTime *p_p0_time = &p0_time;
    XTime *p_p1_time = &p1_time;
    //XTime *p_p2_time = &p2_time;
    //XTime *p_p3_time = &p3_time;

    // Enabling burst-mode of AXI BRAM Controller
    Xil_SetTlbAttributes(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR, 0x15de6);

	printf("------------------------------------\n");
	printf("--- GAUSSIAN BLUR IP CORE ---\n");
	printf("------------------------------------\n\n");

	// Time at the beginning
	XTime_GetTime(p_p0_time);

	// Initialization of the system
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, IMG_WIDTH_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, IMG_HEIGHT_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, IMG_OFFSET_UP_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, IMG_OFFSET_DOWN_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, IMG_OCTAVE_C);

	XTime_GetTime(p_p1_time);

	// Duration of the initialisation and sending data to the Hough-core
	d1 = 1.0 * ((int) p1_time - (int) p0_time) / (COUNTS_PER_SECOND / 1000000);

	//------------------------Read parameters from AXI LITE---------------------------------
	uint16_t width = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET);
	uint16_t height = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET);
	uint16_t offset_up = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET);
	uint16_t offset_down = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET);
	uint16_t img_per_octave = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET);

	printf("Parameters set!\n");

	printf("Duration is %.2f[us].\n", d1);
	printf("Width in core is: %d.\n", width);
	printf("Height in core is: %d.\n", height);
	printf("Offset up in core is: %d.\n", offset_up);
	printf("Offset down core is: %d.\n", offset_down);
	printf("Imgs pre octave in core is: %d.\n", img_per_octave);

	// buffers for tests
	//uint16_t start_buffer[60000];



	//------------------------Send and read from BRAM (Not working way)---------------------------------
	//memcpy((void*)XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR, start_buffer, sizeof(start_buffer));
	//memcpy(end_buffer, (void*)XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR, sizeof(end_buffer));


	//------------------------Fill start_buffer (test)---------------------------------
//	for (int i = 0; i < sizeof(start_buffer)/sizeof(start_buffer[0]); i++)
//	{
//		start_buffer[i] = i;
//		printf("start_buffer[%d] filled.\n", i);
//	}

	//------------------------Send start_buffer to BRAM(test)---------------------------------
//	for (int i = 0; i < (sizeof(start_buffer)/sizeof(start_buffer[0]))/2; i++)
//	{
//		uint32_t packed = (start_buffer[2*i+1] << 16) | start_buffer[2*i];
//		Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR +  4*i, packed);
//		printf("start_buffer[%d] and start_buffer[%d] sent.\n", i, i+1);
//	}

//	for (uint32_t i = 30000; i < 40000; i+=2)
//	{
//		uint32_t packed = (image_data[i+1] << 16) | image_data[i];
//		Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR +  4*i, packed);
//		printf("image_data[%" PRIu32 "] and image_data[%" PRIu32 "] sent.\n", i, i+1);
//	}



	//------------------------Write image to BRAM---------------------------------
	for (uint16_t i = 0; i < IMG_WIDTH_C*IMG_HEIGHT_C; i+=2)
	{
		uint32_t packed = (image_data[i+1] << 16) | image_data[i];
		Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR +  2*i, packed);						//i*2 because of 2 byte per pixel and 2 pyxels. i increments by 2
		//printf("image_data[%" PRIu16 "] and image_data[%" PRIu16 "] sent.\n", i, i+1);
	}

	//------------------------Read image from BRAM (test)---------------------------------
	for(uint16_t j = 0; j < IMG_WIDTH_C*IMG_HEIGHT_C; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer[j] = (uint16_t)(packed & 0xFFFF);
		end_buffer[j+1] = (uint16_t)((packed >> 16) & 0xFFFF);
		//printf("end_buffer[%" PRIu16 "] = %d and end_buffer[%" PRIu16 "] = %d.\n", j, end_buffer[j], j+1, end_buffer[j+1]);
		//printf("j = %" PRIu16 ", address = 0x%08X\n", j, XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2 * j);
	}

	for(uint16_t j = 0; j < IMG_WIDTH_C*IMG_HEIGHT_C-1; j++)
	{
		if(end_buffer[j] != image_data[j])
		{
			printf("Wrong value at: %" PRIu16 ".\n", j);
		}
	}


	printf("Starting IP!\n");

	//------------------------Start Guassian Blur IP---------------------------------
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 1);
	while(Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);

	// Waiting for the core to finish processing
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));

	printf("IP finished!\n");

	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < IMG_WIDTH_C*IMG_HEIGHT_C; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer[j] = (uint16_t)(packed & 0xFFFF);
		end_buffer[j+1] = (uint16_t)((packed >> 16) & 0xFFFF);
		printf("end_buffer[%" PRIu16 "] = %d and end_buffer[%" PRIu16 "] = %d.\n", j, end_buffer[j], j+1, end_buffer[j+1]);
		//printf("j = %" PRIu16 ", address = 0x%08X\n", j, XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2 * j);
	}

	printf("Image read!\n");

	printf("\n--------------- EXIT ---------------\n");
	printf("------------------------------------\n\n\n\n\n");

    cleanup_platform();
    return 0;
}
