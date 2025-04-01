#include <iostream> 
#include <string> 
#include <cstring> 
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
        char res_c[30];
        strcpy(res_c, argv[1]);
        char res_cut[20];
        for (int i = 0; i < 20; i++)
           res_cut[i]=res_c[i + 10];
        std::string output = res_cut;

        result.save(output);
        res = fopen("log_file.txt", "a+");
    
        if (res == NULL){
    	    std::cout << "Greska" << std::endl;
    	    return -1;
        }
        fprintf(res, "Using %s executable on image %s found %ld keypoints.\n", exe, output.c_str(), kps.size());
        fclose(res);
        std::cout << "Found " << kps.size() << " keypoints. Output image is saved as "<< output << "\n";

    return 0;
}
