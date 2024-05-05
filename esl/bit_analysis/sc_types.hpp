#ifndef TYPES_H
#define TYPES_H

#define SC_INCLUDE_FX

#include <systemc>

typedef sc_dt::sc_ufixed_fast<16, 0> num_t;
typedef sc_dt::sc_fixed_fast<16, 10> floor_ceil_t;
typedef sc_dt::sc_ufixed_fast<16, 1> sigma_base_diff_t;
typedef sc_dt::sc_ufixed_fast<24, 3> sigma_prev_total_t;
typedef sc_dt::sc_ufixed_fast<16, 1> k_t;
typedef sc_dt::sc_ufixed_fast<16, 2> sum_t;


#endif
