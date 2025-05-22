CC = g++
CXXFLAGS = -std=c++20 -O3
PROJECT = find_keypoints
IMAGE_FILES := ../../../esl/images/"parrot.jpg"

SRC = find_keypoints.cpp sift.cpp image.cpp app_functions.cpp

$(PROJECT) : $(SRC)
	$(CC) -g  $(SRC) -o $(PROJECT)
run:
	$(foreach img,$(IMAGE_FILES),./$(PROJECT) $(img);)
clean:
	rm find_keypoints *.jpg
