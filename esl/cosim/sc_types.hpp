#ifndef SC_TYPES_HPP
#define SC_TYPES_HPP

#include <systemc>

//#define SC_INCLUDE_FX

const int WIDTH = 16; //width of the data_t type
const int INTEGER = 1; //number of bits in the integer part of the data_t type
const int FRACTIONAL = WIDTH - INTEGER ; //number of bits in the fractional part of the data_t type

//----------------SC TYPES-----------------------
//typedef sc_dt::sc_ufixed_fast<WIDTH, 0> kernel_t; //16 0
//typedef sc_dt::sc_ufixed_fast<24, 3> sigma_base_diff_t; //16.2 bilo, 24.3 
typedef sc_dt::sc_ufixed_fast<32, 9> sigma_t;// 16.3 bilo, 32.9 
//typedef sc_dt::sc_ufixed_fast<32, 10> k_t; //16.1 je bilo, 32.10
typedef sc_dt::sc_ufixed_fast<WIDTH , INTEGER> data_t; //16 2 je zadovoljavaljuce, najvaznije zbog ustede prostora
//-----------------------------------------------

#endif
