#include <iostream> 
#include <string> 
#include <cstring> 

#include "image.hpp"
#include "SIFT.hpp"

int main(int argc, char *argv[])
{
    std::ios_base::sync_with_stdio(false);
    std::cin.tie(NULL);
    
    if (argc != 2) {
        std::cerr << "Nacin upotrebe: ./find_keypoints input.jpg (ili .png)\n";
        return EXIT_FAILURE;
    }
    Image img(argv[1]);
    img =  img.channels == 1 ? img : rgb_to_grayscale(img);
           
    std::vector<Keypoint> kps = find_keypoints_and_descriptors(img);
    Image result = draw_keypoints(img, kps);        
    result.save("result.jpg");

    std::cout << "Pronadjeno " << kps.size() << " kljucnih tacaka. Izlazna slika je sacuvana kao result.jpg\n";
    
    return 0;
}
