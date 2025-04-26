#include <iostream>

#include "app_functions.h"
#include "test_image0.h"

int main()
{

    uint16_t end_buffer0[(IMG0_WIDTH_C)*(IMG0_HEIGHT_C - IMG0_OFFSET_UP_C - IMG0_OFFSET_DOWN_C)];
    // uint16_t end_buffer0[(IMG0_WIDTH_C)*(IMG0_HEIGHT_C)];

    std::cout << "Sent reset signal." << std::endl;
    write_hard(RESET_REG_OFFSET, 1);


    std::cout << "Sent image data." << std::endl;
    write_hard(IMG_WIDTH_REG_OFFSET, IMG0_WIDTH_C);
    write_hard(IMG_HEIGHT_REG_OFFSET, IMG0_HEIGHT_C);
    write_hard(IMG_OFFSET_UP_REG_OFFSET, IMG0_OFFSET_UP_C);
    write_hard(IMG_OFFSET_DOWN_REG_OFFSET, IMG0_OFFSET_DOWN_C);
    write_hard(IMG_OCTAVE_NUM_REG_OFFSET, IMG0_OCTAVE_C);

    std::cout << "Sent image to bram." << std::endl;
    write_bram(image0_data, IMG0_WIDTH_C*IMG0_HEIGHT_C);
    
    std::cout << "Image sent to bram." << std::endl;

    // std::cout << "Sent start signal." << std::endl;
    // write_hard(START_REG_OFFSET, 1);

    // while(!(read_hard(READY_REG_OFFSET)).value());

    // std::cout << "IP finished." << std::endl;

    // read_bram(end_buffer0, IMG0_WIDTH_C*(IMG0_HEIGHT_C - IMG0_OFFSET_UP_C - IMG0_OFFSET_DOWN_C));



    // read_bram(end_buffer0, 10);

    // for(int i = 0; i < 10; i++)
    // {
    //     std::cout << "Pixel " << i << " =" << end_buffer0[i] << std::endl;
    // }



    read_bram(end_buffer0, IMG0_WIDTH_C*(IMG0_HEIGHT_C - IMG0_OFFSET_UP_C - IMG0_OFFSET_DOWN_C));

    std::cout << "Image read from BRAM." << std::endl;

    int matched = 0;

    for(int i = 0; i < IMG0_WIDTH_C*(IMG0_HEIGHT_C - IMG0_OFFSET_UP_C - IMG0_OFFSET_DOWN_C); i++)
    {
        if(image0_data[i] == end_buffer0[i])
        {
            matched++;        
        }
    }

    std::cout << "There are " << matched << " matched pixels." << std::endl; 

    

    // for(int i = 0; i < 50; i++)
    // {
    //     std::cout << "Pixel " << i << " =" << end_buffer0[i] << std::endl;
    //     std::cout << "Expected value " << image0_data[i] << std::endl;
    // }

    return 0;
}