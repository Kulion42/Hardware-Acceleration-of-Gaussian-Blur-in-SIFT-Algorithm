#ifndef _FUNCTIONS_HPP
#define _FUNCTIONS_HPP

#define SC_INCLUDE_FX

#include <systemc>
#include <sysc/datatypes/fx/sc_fixed.h>
#include <iostream>
#include <string.h>
#include <bitset>
#include <math.h>
#include <string>
#include <systemc>
#include <tlm>
#include "sc_types.hpp"

using namespace std;

static const int FIXED_POINT_FRACTIONAL_BITS = 14;

int toInt(unsigned char *buf);

int toInt2(unsigned char *buf);

void toUchar1(unsigned char *buf,int val);

void toUchar2(unsigned char *buf,int val);

void toUchar4(unsigned char *buf,int val);

unsigned char Convert_to_UnsignedC(char val);

unsigned char Convert_to_UnsignedD(double val);

char Convert_to_SigendC(unsigned char val);

void Fixed_to_Uchar(unsigned char *buf, data_t input);

data_t Uchar_to_Fixed(unsigned char *buf);

#endif
