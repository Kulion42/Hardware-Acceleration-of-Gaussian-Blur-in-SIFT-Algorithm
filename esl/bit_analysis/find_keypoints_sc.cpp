#include <iostream> 
#include <string> 
#include "image.hpp"
#include "soft.hpp"

int sc_main(int argc, char *argv[])
{
    std::ios_base::sync_with_stdio(false);
    std::cin.tie(NULL);
    FILE *res;
    char *exe = argv[0];
    char *name = argv[1];
    if (argc != 2) {
        std::cerr << "Usage: ./find_keypoints input.jpg (or .png)\n";
        return 0;
    }
    Image img(argv[1]);
    img =  img.channels == 1 ? img : rgb_to_grayscale(img);

    std::vector<Keypoint> kps = find_keypoints_and_descriptors(img);
    Image result = draw_keypoints(img, kps);
    result.save("result.jpg");
    
    res = fopen("../log_file.txt", "a+");
    
    if (res == NULL){
    	std::cout << "Greska" << std::endl;
    	return -1;
    }
    std::cout << "Found " << kps.size() << " keypoints. Output image is saved as result.jpg\n";
    fprintf(res, "Using %s executable on image %s found %ld keypoints.\n", exe, name, kps.size());
    fclose(res);
    return 0;
}
