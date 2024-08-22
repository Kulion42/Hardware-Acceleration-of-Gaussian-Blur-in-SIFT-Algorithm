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
    
    char numstr[21];
    string str = "result_";
    string res_name;
    
   //for (int i = 4; i<17; i+=4){
        
        
        sprintf(numstr, "%d", N_IP);
        std::vector<Keypoint> kps = find_keypoints_and_descriptors(img);
        Image result = draw_keypoints(img, kps);
        res_name = str + numstr + "_parts" + ".jpg";
        //cout << res_name << endl;
        result.save(res_name);
        
       // res = fopen("../log_file.txt", "a+");
        
        if (res == NULL){
        	std::cout << "Greska" << std::endl;
        	return -1;
        }
        std::cout << "Found " << kps.size() << " keypoints. Output image is saved as "<< res_name << "\n";
        //fprintf(res, "Using %s executable on image %s with %d parts found %ld keypoints.\n", exe, name, 4 , kps.size());
        fclose(res);
    
  // }
    return 0;
}
