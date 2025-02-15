#include <stdint.h>
#include "app_functions.h"

//Treba da bude slika kao argument u write_bram i read_bram.
void write_bram(uint16_t * val, int length)
{
	FILE *main_bram_file;
	main_bram_file = fopen("/dev/main_bram_ctrl", "w");
			
	
	fflush(main_bram_file);
	//treba zameniti sa IMG_WIDTH*IMG_HEIGH
	for(uint16_t i = 0; i < length; i+=2)
	{
		//spoj 2 piksela i posalji
		uint32_t packed = (val[i+1] << 16) | val[i];
		
		//implementacija je sa i/2 jer se for krece kroz celu petlju a u bram se 2 piksela upisuju na 1 poziciju
		fprintf(main_bram_file, "%d, %d\n", packed, i/2); //mozda je greska
		fflush(main_bram_file);
	}
	
	fclose(main_bram_file);
}

void read_bram(uint16_t * val, int length)
{
	FILE *main_bram_file;
	uint32_t packed;
	bram_file = fopen ("/dev/main_bram_ctrl", "r");
	
	//treba zameniti sa IMG_WIDTH*IMG_HEIGH
	for (uint16_t i = 0; i < length; i+=2)
  {
		fscanf(main_bram_file, "%d ", &packed); //ucita 2 piksela od jednom
		
		//razdvoj piksele i sacuvaj u niz
    val[i] = (uint16_t)(packed & 0xFFFF);
    val[i+1] = (uint16_t)((packed >> 16) & 0xFFFF);
  }
	fscanf(main_bram_file, "\n");
	fclose(main_bram_file);	
}

void write_hard(unsigned char addr, int val)
{
	FILE *gaussian_blur_core_file;
	
	gaussian_blur_core_file = fopen("/dev/gaussian_blur_core", "w");
	fprintf(gaussian_blur_core_file, "%d, %d\n", val, addr);
	fflush(gaussian_blur_core_file);
	fclose(gaussian_blur_core_file);
}

uint16_t read_hard(unsigned char addr)
{
	FILE *gaussian_blur_core_file;
	int val[8];
	char tmp = addr/4;
	
	gaussian_blur_core_file = fopen("/dev/gaussian_blur_core", "r");
	fscanf(gaussian_blur_core_file, "%d %d %d %d %d %d %d %d\n", &val[0], &val[1], &val[2], &val[3], &val[4], &val[5], &val[6], &val[7]);
	fclose(gaussian_blur_core_file);
	
	return val[tmp];
}
