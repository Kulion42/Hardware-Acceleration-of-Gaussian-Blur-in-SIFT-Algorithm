#include "vp.hpp"

using namespace sc_core;

int sc_main(int argc, char* argv[])
{
    Vp vp("Virtual_Platform", argv, argc);
    sc_start();
   
    return 0;
}  
