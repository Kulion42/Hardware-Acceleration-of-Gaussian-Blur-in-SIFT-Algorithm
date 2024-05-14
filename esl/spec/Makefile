CC = g++
PROJECT = find_keypoints

SRC = find_keypoints.cpp sift.cpp image.cpp 

$(PROJECT) : $(SRC)
	$(CC) -g  $(SRC) -o $(PROJECT)
run:
	./$(PROJECT) ../images/"parrot.jpeg" 
clean:
	rm find_keypoints result.jpg
