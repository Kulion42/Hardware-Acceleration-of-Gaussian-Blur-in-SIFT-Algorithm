#include <iostream> 
#include <string>
#include <cstring>
#include "image.hpp"
#include "sift.hpp"

int main(int argc, char *argv[])
{
    std::ios_base::sync_with_stdio(false);
    std::cin.tie(NULL);
    FILE *res;
    char *exe = argv[0];
    char *name = argv[1];
    if (argc != 2) {
        std::cerr << "Usage: ./find_keypoints input.jpg (or .png)\n";
        return EXIT_FAILURE;
    }
    Image img(argv[1]);
    
    if(img.height > 256 || img.width > 256)
    {
      std::cerr << "Image can't be bigger than 256x256 pixels.\n";
      return EXIT_FAILURE;
    } 
    img =  img.channels == 1 ? img : rgb_to_grayscale(img);

    std::vector<sift::Keypoint> kps = sift::find_keypoints_and_descriptors(img);
    Image result = sift::draw_keypoints(img, kps);
    
    res = fopen("log_file.txt", "a+");
    
    if (res == NULL){
    	std::cout << "Greska" << std::endl;
    	return -1;
    }
    char res_full[30];
     strcpy(res_full, argv[1]);
    char res_cut[20];
    for (int i = 0; i < 20; i++)
        res_cut[i]=res_full[i + 10];
    std::string output = res_cut;
    result.save(output.c_str());
    std::cout << "Found " << kps.size() << " keypoints. Output image is saved as "<< output.c_str()<< std::endl;
    fprintf(res, "Using %s executable on image %s found %ld keypoints.\n", exe, output.c_str(), kps.size());
    fclose(res);
    return 0;
}
