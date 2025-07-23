#ifndef _FUNCTIONS_HPP
#define _FUNCTIONS_HPP

#include <systemc>
#include <sysc/datatypes/fx/sc_fixed.h>
#include <iostream>
#include <string.h>
#include <bitset>
#include <math.h>
#include <string>
#include <tlm>
#include "sc_types.hpp"

using namespace std;

static const int FIXED_POINT_FRACTIONAL_BITS_DATA_T = FRACTIONAL;
static const int FIXED_POINT_FRACTIONAL_BITS_SIGMA_T = 23;

extern sc_core::sc_time offset_system;

template <typename T1 = int, typename T2 = unsigned char> T1 toInt(T2 *buf, int len)
{
    if (len< 1 || len> 4) {
        throw std::invalid_argument("Length must be between 1 and 4.");
    }
    
    T1 val = 0;
    for (int i = 0; i < len; ++i) {
        val += ((T1)buf[i]) << (8 * (len- 1 - i));
    }
    return val;
}


template <typename T1 int, typename T2 = unsigned char > void toChar(T2 *buf,T1 val, int len)
{
    if (len< 1 || len> 4) {
        throw std::invalid_argument("Length must be between 1 and 4.");
    }
    
    for (int i = 0; i < len; ++i) {
        buf[i] = (T2)((val >> (8 * (len- 1 - i))) & 0xFF);
    }

}

unsigned char Convert_to_UnsignedC(char val);

char Convert_to_SigendC(unsigned char val);

uint16_t to_Uint16_t(data_t input, int shift = FIXED_POINT_FRACTIONAL_BITS_DATA_T);

//void Fixed_to_Uchar(unsigned char *buf, data_t input1, data_t input2);
template <typename T1 = data_t> void to_Uchar(unsigned char *buf, T1 *input, int shift = FIXED_POINT_FRACTIONAL_BITS_DATA_T)
{
    /*if constexpr (std::is_same<T1, uint16_t>::value || std::is_same<T1, int16_t>::value) {
        toChar<T1>(buf, input[0], 2);
        toChar<T1>(buf + 2, input[1], 2);
    }*/
  //  else if constexpr (std::is_same<T1, data_t>::value) {
        toChar<uint16_t>(buf, (uint16_t)(input[0] * (1 << shift)), 2);
        toChar<uint16_t>(buf + 2, (uint16_t)(input[1] * (1 << shift)), 2);
    //}

}
//void Uchar_to_Fixed(unsigned char *buf, data_t& output1, data_t& output2);
template <typename T1 = data_t> void from_Uchar(unsigned char *buf, T1 *output, int shift = FIXED_POINT_FRACTIONAL_BITS_DATA_T)
{
   /* if constexpr (std::is_same<T1, uint16_t>::value || std::is_same<T1, int16_t>::value) {
   //     output[0] = toInt<T1>(buf, 2);
    //    output[1] = toInt<T1>(buf + 2, 2);
    } */
   // else if constexpr (std::is_same<T1, data_t>::value) {
        output[0] = (double)(toInt<uint16_t>(buf, 2)) / (double)(1 << shift);
        output[1] = (double)(toInt<uint16_t>(buf + 2, 2)) / (double)(1 << shift);
    //}
}

#endif
