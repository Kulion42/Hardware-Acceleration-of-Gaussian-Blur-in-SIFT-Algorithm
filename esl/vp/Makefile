CC = "g++"
PROJECT = main
IMAGE_FILES := ../images/"parrot.jpg" ../images/"bird.jpg" ../images/"eagle.jpg" ../images/"shark.jpg" ../images/"squirrel.jpg" ../images/"mountain1.jpg" ../images/"mountain2.jpg" ../images/"mushroom.jpg" ../images/"palma.jpg" ../images/"sandals.jpg" ../images/"seashore.jpg"


SRC = main.cpp vp.cpp ip_core.cpp cpu.cpp interconnect.cpp bram_main.cpp bram_tmp.cpp kernel_rom.cpp functions.cpp image.cpp

$(PROJECT) : $(SRC)
	$(CC) -DSC_INCLUDE_FX -I ${SYSTEMC}/include -L${SYSTEMC}/lib-linux64 -lsystemc $(SRC) -o $(PROJECT)

run:
	$(foreach img,$(IMAGE_FILES),./$(PROJECT) $(img);)
clean:
	rm main *.jpg log_file.txt frame_file.txt 
