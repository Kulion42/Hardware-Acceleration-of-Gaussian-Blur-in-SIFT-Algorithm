CC = g++
PROJECT = fkey_keypoints_sc

SRC = find_keypoints_sc.cpp sift.cpp image.cpp 

$(PROJECT) : $(SRC)
	$(CC) -g -lsystemc $(SRC) -o $(PROJECT)

clean:
	rm fkey_keypoints_sc result.jpg
