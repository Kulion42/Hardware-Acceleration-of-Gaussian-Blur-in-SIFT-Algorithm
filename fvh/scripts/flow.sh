exit 0

#For simple simulation with image files
vivado -mode tcl -nolog -nojournal -source run.tcl [-tclargs] [number_of_tests]
# Keeps output file in ../result_files/

#For rand simulation with random data
vivado -mode tcl -nolog -nojournal -source run.tcl -tclargs rand [number_of_tests]
# Keeps both input and output file in ../result_files/