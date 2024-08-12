CC = g++
PROJECT = main

SRC = main.cpp ip_core.cpp cpu.cpp interconnect.cpp bram_main.cpp bram_tmp.cpp bram_kernel.cpp functions.cpp image.cpp

$(PROJECT) : $(SRC)
	$(CC) -g -lsystemc -lpthread $(SRC) -o $(PROJECT)

run:
	./$(PROJECT) ../imgs/"bleach.png" 
clean:
	rm main *.jpg
