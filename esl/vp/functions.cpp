#include "functions.hpp"
#include <iostream>

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
uint16_t to_Uint16_t(data_t input, int shift)
{
    uint16_t output = (uint16_t)((double)input * (double)(1 << shift));
    if (output > (UINT16_MAX/2)) {
        //cout << "Warning: Value exceeds UINT16_MAX/2, clamping to prevent overflow." << endl;
        output = (UINT16_MAX >> 1); // Prevent overflow
    }
    
    return output;
}


