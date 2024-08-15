#ifndef SC_TYPES_HPP
#define SC_TYPES_HPP

#include <systemc>

//#define SC_INCLUDE_FX

//----------------SC TYPES-----------------------
typedef sc_dt::sc_ufixed_fast<16, 1> sum_t; //16 0
//typedef sc_dt::sc_ufixed_fast<24, 3> sigma_base_diff_t; //16.2 bilo, 24.3 
typedef sc_dt::sc_ufixed_fast<24, 4> sigma_t;// 16.3 bilo, 32.9 
//typedef sc_dt::sc_ufixed_fast<32, 10> k_t; //16.1 je bilo, 32.10
typedef sc_dt::sc_fixed_fast<16, 2> data_t; //16 2 je zadovoljavaljuce, najvaznije zbog ustede prostora
//-----------------------------------------------

#endif
