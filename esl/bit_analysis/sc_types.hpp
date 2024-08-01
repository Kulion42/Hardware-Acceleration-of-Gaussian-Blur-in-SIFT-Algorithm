#ifndef TYPES_H
#define TYPES_H

#define SC_INCLUDE_FX

#include <systemc>

typedef sc_dt::sc_ufixed_fast<16, 1> num_t;
typedef sc_dt::sc_ufixed_fast<32, 9> sigma_prev_total_t;
typedef sc_dt::sc_fixed_fast<16, 2> data_t;


#endif
