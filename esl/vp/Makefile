CC = "g++"
PROJECT = main

SRC = main.cpp vp.cpp ip_core.cpp cpu.cpp interconnect.cpp bram_main.cpp bram_tmp.cpp kernel_rom.cpp functions.cpp image.cpp

$(PROJECT) : $(SRC)
	$(CC) -DSC_INCLUDE_FX -I ${SYSTEMC}/include -L${SYSTEMC}/lib-linux64 -lsystemc $(SRC) -o $(PROJECT)

run:
	./$(PROJECT) ../images/"bellingham.jpeg" 
clean:
	rm main *.jpg ../log_file.txt
