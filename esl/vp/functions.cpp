#include "functions.hpp"
#include <iostream>

int toInt(unsigned char *buf)
{
    int val = 0;
    val += ((int)buf[0]) << 24;
    val += ((int)buf[1]) << 16;
    val += ((int)buf[2]) << 8;
    val += ((int)buf[3]);
    return val;
}
int toInt2(unsigned char *buf)
{
    int val = 0;
    val += ((int)buf[0]) << 8;
    val += ((int)buf[1]);
    return val;
}

void toUchar4(unsigned char *buf,int val)
{
    buf[0] = (char) (val >> 24);
    buf[1] = (char) (val >> 16);
    buf[2] = (char) (val >> 8);
    buf[3] = (char) (val);
}

void toUchar2(unsigned char *buf, int val)
{
    buf[0] = (unsigned char) (val >> 8);
    buf[1] = (unsigned char) (val);
}

void toUchar1(unsigned char *buf, int val)
{
    buf[0] = (unsigned char) (val);
}

unsigned char Convert_to_UnsignedC(char val)
{
    unsigned char buf = (unsigned)val;
    return buf;
} 
char Convert_to_SigendC(unsigned char val)
{
    char buf = signed(val);
    return buf;
}

void Fixed_to_Uchar(unsigned char *buf, data_t input)
{
    double val = ((double)input / (double)(1 << FIXED_POINT_FRACTIONAL_BITS));
    
    buf[0] = (char) (val >> 8);
    buf[1] = (char) (val);
}

data_t Uchar_to_Fixed(unsigned char *buf)
{
    uint16_t input;
    
    input += (buf[0]) << 8;
    input += buf[1];
    
    return (data_t)(input * (1 << FIXED_POINT_FRACTIONAL_BITS));
}

