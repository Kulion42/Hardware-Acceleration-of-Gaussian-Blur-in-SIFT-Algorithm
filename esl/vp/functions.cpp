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

void Fixed_to_Uchar(unsigned char *buf, data_t input1, data_t input2)
{
    int16_t in1 = (int16_t)((double)input1 * (double)(1 << FIXED_POINT_FRACTIONAL_BITS_DATA_T));
    int16_t in2 = (int16_t)((double)input2 * (double)(1 << FIXED_POINT_FRACTIONAL_BITS_DATA_T));
    //std::cout << in1 << " "<< in2 << endl;
    buf[0] = (char) (in1 >> 8);
    buf[1] = (char) (in1);
    buf[2] = (char) (in2 >> 8);
    buf[3] = (char) (in2);
}

void Uchar_to_Fixed(unsigned char *buf, data_t& output1, data_t& output2)
{
    int16_t out1 = 0;
    int16_t out2 = 0;
    
    out1 += ((int16_t)buf[0]) << 8;
    out1 += ((int16_t)buf[1]);
    
    out2 += ((int16_t)buf[2]) << 8;
    out2 += ((int16_t)buf[3]);
    
    output1 = (double)(out1) / (double)(1 <<  FIXED_POINT_FRACTIONAL_BITS_DATA_T);
    output2 = (double)(out2) / (double)(1 <<  FIXED_POINT_FRACTIONAL_BITS_DATA_T);
    //std::cout << output1 << " " << output2 << std::endl;
}

data_t Uchar_to_Data_t(unsigned char *buf)
{
    uint16_t input = 0;
    
    input += ((uint16_t)buf[0]) << 8;
    input += ((uint16_t)buf[1]);
    
    //std::cout << (((int32_t)buf[0]) << 24) << (((int32_t)buf[1]) << 16) << (((int32_t)buf[2]) << 8) << std::endl;
    //std::cout << input << endl;
    return (double)(input) / (double)(1 << FIXED_POINT_FRACTIONAL_BITS_DATA_T);
}

uint16_t to_Uint16_t(data_t val){
    return (uint16_t)((double)val * (double)(1 << FIXED_POINT_FRACTIONAL_BITS_DATA_T));
}
