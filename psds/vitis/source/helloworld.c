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

#include "test_image0.h"
#include "test_image1.h"
#include "test_image2.h"
#include "test_image3.h"
#include "test_image4.h"
#include "test_image5.h"

#include "test_image0_res.h"
#include "test_image1_res.h"
#include "test_image2_res.h"
#include "test_image3_res.h"
#include "test_image4_res.h"
#include "test_image5_res.h"


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

    float d1, d2, d3, d4, d5, d6;

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

    // Enabling burst-mode of AXI BRAM Controller
    Xil_SetTlbAttributes(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR, 0x15de6);

	printf("------------------------------------\n");
	printf("--- GAUSSIAN BLUR IP CORE ---\n");
	printf("------------------------------------\n\n");

	// Time at the beginning of initialization and resetting
	XTime_GetTime(p_p0_time);
	// Initialization of the system
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Time after reset and at the beggining of sending parameters
	XTime_GetTime(p_p1_time);
	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, IMG0_WIDTH_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, IMG0_HEIGHT_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, IMG0_OFFSET_UP_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, IMG0_OFFSET_DOWN_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, IMG0_OCTAVE_C);

	//Time after parameters were sent and beggining of reading parameters
	XTime_GetTime(p_p2_time);

	//------------------------Read parameters from AXI LITE---------------------------------
	uint16_t width = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET);
	uint16_t height = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET);
	uint16_t offset_up = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET);
	uint16_t offset_down = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET);
	uint16_t img_per_octave = Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET);

	//Time after parameters were read
	XTime_GetTime(p_p3_time);

	printf("Width in core is: %d.\n", width);
	printf("Height in core is: %d.\n", height);
	printf("Offset up in core is: %d.\n", offset_up);
	printf("Offset down core is: %d.\n", offset_down);
	printf("Imgs pre octave in core is: %d.\n", img_per_octave);

	//Beggining of sending image to main BRAM
	XTime_GetTime(p_p4_time);

	//------------------------Write image to BRAM---------------------------------
	for (uint16_t i = 0; i < IMG0_WIDTH_C*IMG0_HEIGHT_C; i+=2)
	{
		uint32_t packed = (image0_data[i] << 16) | image0_data[i+1];
		Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR +  2*i, packed);						//i*2 because of 2 byte per pixel and 2 pixels. i increments by 2
		//printf("image_data[%" PRIu16 "] = %" PRIu16 " and image_data[%" PRIu16 "] = %" PRIu16 " sent.\n", i, image_data[i], i+1, image_data[i+1]);
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
	// Waiting for the core to finish processing
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));

	//Time when the IP Core finished processing image
	XTime_GetTime(p_p7_time);
	printf("IP finished!\n");

	//Start time for reading the image from BRAM
	XTime_GetTime(p_p8_time);

	int incorrect = 0;
	int correct = 0;
	int zeros = 0;


	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < (IMG0_WIDTH_C)*(IMG0_HEIGHT_C - IMG0_OFFSET_UP_C - IMG0_OFFSET_DOWN_C)-1; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer0[j+1] = (uint16_t)(packed & 0xFFFF);
		end_buffer0[j] = (uint16_t)((packed >> 16) & 0xFFFF);
//		printf("end_buffer[%" PRIu16 "] = %d and end_buffer[%" PRIu16 "] = %d.\n", j, end_buffer[j], j+1, end_buffer[j+1]);
//		printf("j = %" PRIu16 ", address = 0x%08X\n", j, XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2 * j);
	}

	//End time for reading the image from BRAM
	XTime_GetTime(p_p9_time);
	printf("Image read!\n");


	for(uint16_t j = 0; j < (IMG0_WIDTH_C)*(IMG0_HEIGHT_C - IMG0_OFFSET_UP_C - IMG0_OFFSET_DOWN_C); j++)
	{

		if((end_buffer0[j] < result_data0[j] - 1) || (end_buffer0[j] > result_data0[j] + 1))
		{
			incorrect++;
		}
		else
		{
			correct++;
		}
		if(end_buffer0[j] == 0)
			zeros++;
	}

	printf("There are %d correct values and %d incorrect values!\n", correct, incorrect);
	printf("There are %d zero values!\n", zeros);

	// Duration of the initialisation and reset of the system
	d1 = 1.0 * ((int) p1_time - (int) p0_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of sending the parameters to IP core
	d2 = 1.0 * ((int) p2_time - (int) p1_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of reading the parameters from IP core
	d3 = 1.0 * ((int) p3_time - (int) p2_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of the sending image to the main BRAM
	d4 = 1.0 * ((int) p5_time - (int) p4_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of IP core processing the image
	d5 = 1.0 * ((int) p7_time - (int) p6_time) / (COUNTS_PER_SECOND / 1000000);

	// Duration of reading processed image from main BRAM
	d6 = 1.0 * ((int) p9_time - (int) p8_time) / (COUNTS_PER_SECOND / 1000000);

	printf("Duration of the initialisation and reset of the system is %.2f[us].\n", d1);
	printf("Duration of sending the parameters to IP core is %.2f[us].\n", d2);
	printf("Duration of reading the parameters from IP core is %.2f[us].\n", d3);
	printf("Duration of the sending image to the main BRAM is %.2f[us].\n", d4);
	printf("Duration of IP core processing the image is %.2f[us].\n", d5);
	printf("Duration of reading processed image from main BRAM is %.2f[us].\n", d6);

	printf("\n--------------- TEST OF MAIN IMAGE FINISHED ---------------\n");

/*------------------------------------------------------------------------------------------------------*/

	printf("\n--------------- TEST OF 1. IMAGE ---------------\n");
	// Reset
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, IMG1_WIDTH_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, IMG1_HEIGHT_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, IMG1_OFFSET_UP_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, IMG1_OFFSET_DOWN_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, IMG1_OCTAVE_C);

	//------------------------Start Guassian Blur IP---------------------------------
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 1);
	while(Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	// Waiting for the core to finish processing
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));

	incorrect = 0;
	correct = 0;
	zeros = 0;


	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < (IMG1_WIDTH_C)*(IMG1_HEIGHT_C - IMG1_OFFSET_UP_C - IMG1_OFFSET_DOWN_C)-1; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer1[j+1] = (uint16_t)(packed & 0xFFFF);
		end_buffer1[j] = (uint16_t)((packed >> 16) & 0xFFFF);
	}

	for(uint16_t j = 0; j < (IMG1_WIDTH_C)*(IMG1_HEIGHT_C - IMG1_OFFSET_UP_C - IMG1_OFFSET_DOWN_C); j++)
	{

		if((end_buffer1[j] < result_data1[j] - 1) || (end_buffer1[j] > result_data1[j] + 1))
		{
			incorrect++;
		}
		else
		{
			correct++;
		}
		if(end_buffer1[j] == 0)
			zeros++;
	}
	printf("There are %d correct values and %d incorrect values!\n", correct, incorrect);
	printf("There are %d zero values!\n", zeros);

/*------------------------------------------------------------------------------------------------------*/

	printf("\n--------------- TEST OF 2. IMAGE ---------------\n");

	// Reset
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, IMG2_WIDTH_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, IMG2_HEIGHT_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, IMG2_OFFSET_UP_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, IMG2_OFFSET_DOWN_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, IMG2_OCTAVE_C);

	//------------------------Start Guassian Blur IP---------------------------------
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 1);
	while(Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	// Waiting for the core to finish processing
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));

	incorrect = 0;
	correct = 0;
	zeros = 0;


	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < (IMG2_WIDTH_C)*(IMG2_HEIGHT_C - IMG2_OFFSET_UP_C - IMG2_OFFSET_DOWN_C)-1; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer2[j+1] = (uint16_t)(packed & 0xFFFF);
		end_buffer2[j] = (uint16_t)((packed >> 16) & 0xFFFF);
	}

	for(uint16_t j = 0; j < (IMG2_WIDTH_C)*(IMG2_HEIGHT_C - IMG2_OFFSET_UP_C - IMG2_OFFSET_DOWN_C); j++)
	{

		if((end_buffer2[j] < result_data2[j] - 1) || (end_buffer2[j] > result_data2[j] + 1))
		{
			incorrect++;
		}
		else
		{
			correct++;
		}
		if(end_buffer2[j] == 0)
			zeros++;
	}
	printf("There are %d correct values and %d incorrect values!\n", correct, incorrect);
	printf("There are %d zero values!\n", zeros);

/*------------------------------------------------------------------------------------------------------*/

	printf("\n--------------- TEST OF 3. IMAGE ---------------\n");

	// Reset
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, IMG3_WIDTH_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, IMG3_HEIGHT_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, IMG3_OFFSET_UP_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, IMG3_OFFSET_DOWN_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, IMG3_OCTAVE_C);

	//------------------------Start Guassian Blur IP---------------------------------
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 1);
	while(Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	// Waiting for the core to finish processing
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));

	incorrect = 0;
	correct = 0;
	zeros = 0;


	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < (IMG3_WIDTH_C)*(IMG3_HEIGHT_C - IMG3_OFFSET_UP_C - IMG3_OFFSET_DOWN_C)-1; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer3[j+1] = (uint16_t)(packed & 0xFFFF);
		end_buffer3[j] = (uint16_t)((packed >> 16) & 0xFFFF);
	}

	for(uint16_t j = 0; j < (IMG3_WIDTH_C)*(IMG3_HEIGHT_C - IMG3_OFFSET_UP_C - IMG3_OFFSET_DOWN_C); j++)
	{

		if((end_buffer3[j] < result_data3[j] - 1) || (end_buffer3[j] > result_data3[j] + 1))
		{
			incorrect++;
		}
		else
		{
			correct++;
		}
		if(end_buffer3[j] == 0)
			zeros++;
	}
	printf("There are %d correct values and %d incorrect values!\n", correct, incorrect);
	printf("There are %d zero values!\n", zeros);

/*------------------------------------------------------------------------------------------------------*/

	printf("\n--------------- TEST OF 4. IMAGE ---------------\n");

	// Reset
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, IMG4_WIDTH_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, IMG4_HEIGHT_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, IMG4_OFFSET_UP_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, IMG4_OFFSET_DOWN_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, IMG4_OCTAVE_C);

	//------------------------Start Guassian Blur IP---------------------------------
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 1);
	while(Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	// Waiting for the core to finish processing
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));

	incorrect = 0;
	correct = 0;
	zeros = 0;


	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < (IMG4_WIDTH_C)*(IMG4_HEIGHT_C - IMG4_OFFSET_UP_C - IMG4_OFFSET_DOWN_C)-1; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer4[j+1] = (uint16_t)(packed & 0xFFFF);
		end_buffer4[j] = (uint16_t)((packed >> 16) & 0xFFFF);
	}

	for(uint16_t j = 0; j < (IMG4_WIDTH_C)*(IMG4_HEIGHT_C - IMG4_OFFSET_UP_C - IMG4_OFFSET_DOWN_C); j++)
	{

		if((end_buffer4[j] < result_data4[j] - 1) || (end_buffer4[j] > result_data4[j] + 1))
		{
			incorrect++;
		}
		else
		{
			correct++;
		}
		if(end_buffer4[j] == 0)
			zeros++;
	}
	printf("There are %d correct values and %d incorrect values!\n", correct, incorrect);
	printf("There are %d zero values!\n", zeros);

/*------------------------------------------------------------------------------------------------------*/

	printf("\n--------------- TEST OF 5. IMAGE ---------------\n");

	// Reset
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 1);
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + RESET_REG_OFFSET, 0);

	// Sending parameters to Gaussian_blur-core
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_WIDTH_OFFSET, IMG5_WIDTH_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_HEIGHT_OFFSET, IMG5_HEIGHT_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_UP_OFFSET, IMG5_OFFSET_UP_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_OFFSET_DOWN_OFFSET, IMG5_OFFSET_DOWN_C);
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + IMG_PER_OCTAVE_OFFSET, IMG5_OCTAVE_C);

	//------------------------Start Guassian Blur IP---------------------------------
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 1);
	while(Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));
	Xil_Out16(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + START_REG_OFFSET, 0);
	// Waiting for the core to finish processing
	while(!Xil_In32(XPAR_GAUSSIAN_BLUR_IP_0_S00_AXI_BASEADDR + READY_REG_OFFSET));

	incorrect = 0;
	correct = 0;
	zeros = 0;


	//------------------------Read to end_buffer from BRAM---------------------------------
	for(uint16_t j = 0; j < (IMG5_WIDTH_C)*(IMG5_HEIGHT_C - IMG5_OFFSET_UP_C - IMG5_OFFSET_DOWN_C)-1; j+=2)
	{
		uint32_t packed = (uint32_t)Xil_In32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 2*j);
		end_buffer5[j+1] = (uint16_t)(packed & 0xFFFF);
		end_buffer5[j] = (uint16_t)((packed >> 16) & 0xFFFF);
	}

	for(uint16_t j = 0; j < (IMG5_WIDTH_C)*(IMG5_HEIGHT_C - IMG5_OFFSET_UP_C - IMG5_OFFSET_DOWN_C); j++)
	{

		if((end_buffer5[j] < result_data5[j] - 1) || (end_buffer5[j] > result_data5[j] + 1))
		{
			incorrect++;
		}
		else
		{
			correct++;
		}
		if(end_buffer5[j] == 0)
			zeros++;
	}
	printf("There are %d correct values and %d incorrect values!\n", correct, incorrect);
	printf("There are %d zero values!\n", zeros);


	printf("\n--------------- EXIT ---------------\n");
	printf("------------------------------------\n\n\n\n\n");

    cleanup_platform();
    return 0;
}
