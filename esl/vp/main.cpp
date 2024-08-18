#include "vp.hpp"

using namespace sc_core;

int sc_main(int argc, char* argv[])
{
    Vp vp("Virtual_Platform", argv, argc);
    sc_start(1, SC_US);
   
    return 0;
}  
