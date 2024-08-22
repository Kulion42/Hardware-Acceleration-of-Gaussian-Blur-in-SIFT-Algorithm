CC = g++
PROJECT = find_keypoints_sc

SRC = find_keypoints_sc.cpp  image.cpp soft.cpp hard.cpp

$(PROJECT) : $(SRC)
	$(CC) -g -lsystemc $(SRC) -o $(PROJECT)

run:
	./$(PROJECT) ../images/"parrot.jpeg" 
clean:
	rm find_keypoints_sc *.jpg *.txt
