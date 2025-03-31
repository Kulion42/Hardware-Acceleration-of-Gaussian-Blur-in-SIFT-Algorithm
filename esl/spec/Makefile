CC = g++
PROJECT = find_keypoints
IMAGE_FILES := ../images/"parrot.jpg" ../images/"bird.jpg" ../images/"eagle.jpg" ../images/"shark.jpg" ../images/"squirrel.jpg" ../images/"mountain1.jpg" ../images/"mountain2.jpg" ../images/"mushroom.jpg" ../images/"palma.jpg" ../images/"sandals.jpg" ../images/"seashore.jpg"


SRC = find_keypoints.cpp sift.cpp image.cpp 

$(PROJECT) : $(SRC)
	$(CC) -g  $(SRC) -o $(PROJECT)
run:
	$(foreach img,$(IMAGE_FILES),./$(PROJECT) $(img);)
clean:
	rm find_keypoints *.jpg log_file.txt
