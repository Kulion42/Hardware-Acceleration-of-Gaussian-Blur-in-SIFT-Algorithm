# Hardware Acceleration of Gaussian Blur in the SIFT Algorithm

This repository implements an FPGA hardware accelerator for the **Gaussian blur** stage of the **SIFT** (Scale-Invariant Feature Transform) keypoint-detection algorithm, and carries it end to end through the ASIC/FPGA design flow: software specification, Electronic System Level (ESL) modeling, RTL functional verification, physical design/synthesis, and embedded software integration on a Zynq SoC.

Gaussian blur (repeated convolution to build the scale-space pyramid) is the dominant hotspot in a software SIFT implementation - profiling (`esl/spec/profiler.txt`) shows `gaussian_blur` consuming over half of total runtime - which motivated offloading it to a dedicated hardware IP core.

## Target platform

- **Board:** Digilent Zybo Z7-10 (Xilinx Zynq-7000 SoC, `xc7z010clg400-1`)
- **Architecture:** ARM Cortex-A9 Processing System (PS) running Linux, driving a custom Gaussian blur IP core in Programmable Logic (PL) over an AXI4-Lite control interface plus a shared BRAM data path.

## Repository layout

The repository is organized into successive stages of the hardware design flow, in the order the project was developed:

| Folder | Stage | Description |
|---|---|---|
| [`esl/`](esl/) | Electronic System Level | Pure C++ golden-model SIFT, SystemC bit-width/HW-vs-SW analysis, a SystemC TLM virtual prototype (VP) of the CPU/interconnect/IP core, and SystemC↔VHDL co-simulation of the accelerator. |
| [`fvh/`](fvh/) | Functional Verification (RTL) | UVM-style SystemVerilog testbench (agents, drivers, monitors, scoreboards, sequences) that verifies the VHDL Gaussian blur core against golden reference vectors, plus Vivado simulation scripts. |
| [`psds/`](psds/) | Physical Design & System Integration | Synthesizable VHDL RTL for the accelerator (including the AXI4-Lite wrapper), Zybo Z7 board constraints (`.xdc`), Vivado TCL build scripts, and the Vitis bare-metal application/test used to bring up the block design on hardware. |
| [`eos/`](eos/) | Embedded OS / Software | Linux kernel platform driver for the IP core, and the final/test C++ SIFT applications that call into the accelerator (via the driver) from user space on the Zynq PS running Linux. |

Each stage progressively refines and verifies the same Gaussian blur design: `esl` establishes *what* to build and its numerical behavior, `fvh` and `psds` verify and implement the RTL *in hardware*, and `eos` integrates the resulting IP into a full embedded Linux application.

### `esl/` - Electronic System Level modeling

- `spec/` - Reference (floating-point) C++ implementation of the full SIFT pipeline (`sift.cpp/hpp`, `find_keypoints.cpp`) used as the golden model and for profiling.
- `bit_analysis/` - SystemC fixed-point (`sc_ufixed`) exploration (`hard.cpp`/`soft.cpp`) used to choose word lengths/precision for the hardware Gaussian blur before committing to RTL.
- `vp/` - SystemC TLM virtual prototype: `cpu`, `interconnect`, `ip_core`, `bram_main`/`bram_tmp`, `kernel_rom` model the target SoC architecture in software, ahead of RTL.
- `cosim/` - Co-simulation harness pairing the SystemC platform model (`sc_main.cpp`, `cpu`, `interconnect`, `ip_core`) with the actual VHDL RTL (`gaussian_blur.vhd`, `convolute_loops.vhd`, `dsp_unit_*.vhd`, `bram.vhd`, `kernel_rom.vhd`, `top_model.vhd`) via Cadence Xcelium (`xmsc_run`).
- `images/` - Sample test images (JPEG) shared across the ESL stages.

Each subfolder builds independently via its own `Makefile` (`make` then `make run` to process the sample image set).

### `fvh/` - Functional Verification Harness

SystemVerilog/UVM-style testbench for the standalone Gaussian blur RTL (independent of the Zynq PS):

- `verif/agent/`, `verif/agent_rand/` - Driver/monitor/sequencer agents for directed and randomized stimulus.
- `verif/sequences/`, `verif/config/` - Test sequences and DUT configuration objects.
- `verif/scoreboard.sv`, `verif/scoreboard_rand.sv` - Self-checking comparison against golden output vectors.
- `verif/env.sv`, `verif/env_rand.sv`, `verif/*_test*.sv` - Verification environments and top-level tests (`simple_test`, `rand_test`).
- `image_files/`, `img_dimensions/` - Golden input/output pixel vectors and per-image geometry (width/height/offsets, per SIFT octave and image-per-octave index) used to drive and check the DUT.
- `scripts/run.tcl`, `scripts/flow.sh` - Vivado batch simulation entry points:
  ```sh
  vivado -mode tcl -nolog -nojournal -source run.tcl [test_name] [number_of_tests]
  # test_name: "simple" (default, image-file based) or "rand" (randomized data)
  ```

### `psds/` - Physical Design & System Integration

- `rtl/` - Synthesizable VHDL: the core convolution datapath (`convolute_loops.vhd`, `dsp_unit_add/mac_shift/mul_shift.vhd`), memory (`bram.vhd`, `kernel_rom.vhd`, `memory_subsystem.vhd`), the top-level (`top_model.vhd`, `gaussian_blur.vhd`), and the AXI4-Lite-wrapped IP (`gaussian_blur_v1_0.vhd`, `gaussian_blur_v1_0_S00_AXI.vhd`) used as a Vivado IP-Integrator block-design core.
- `constraints/`, `rtl/Zybo-Z7-Master.xdc` - Zybo Z7 pin/timing constraints.
- `tb/convolute_loops_tb/` - Standalone VHDL testbenches (with Vivado `.wcfg` waveform configs) for the convolution datapath, the Gaussian blur core, and the full top model.
- `tb/load_bram/` - Precomputed BRAM initialization data for simulation.
- `tcl/script.tcl`, `tcl/simulation.tcl` - Vivado project/build and simulation automation scripts.
- `vitis/` - Bare-metal Vitis test application (`source/helloworld.c`) that exercises the accelerator directly from the Zynq PS over AXI (register offsets for image width/height, vertical/horizontal offsets, images-per-octave, reset/start/ready handshake), plus reference input/output image headers (`images/`) and bring-up instructions (`startup.txt`): create a Vitis platform/application project from the exported `.xsa`, copy in the sources, build, and run over a serial console.
- `goto_gaussian_blur.txt` - Pseudocode/flowchart notes for the convolution control FSM (`convolution_y_loop` / `convolution_x_loop` / `convolution_k_loop`) implemented in the RTL.

### `eos/` - Embedded OS / Linux integration

- `driver/gaussian_blur_driver.c` - Linux platform (character) driver (`gaussian_blur_driver`) that binds to the `main_bram_ctrl` and `gaussian_blur_core` device-tree nodes, `ioremap`s their register windows, and exposes `open/read/write` file operations so user-space can configure and trigger the accelerator (image geometry registers, `RESET`/`START`/`READY` handshake, semaphore-guarded critical sections, wait queue for completion).
- `app/final_app/` - Full user-space SIFT application (`SIFT.cpp/hpp`, `find_keypoints.cpp`, `app_functions.*`) that offloads Gaussian-pyramid generation to the hardware accelerator through the driver.
- `app/test_app/` - Standalone driver/accelerator test application plus precomputed input/output reference vectors (`res_file_img_*.h`) for multiple image sizes and vertical offsets, used to validate the hardware path in isolation from the full SIFT pipeline.

## End-to-end flow

1. **Specify** the algorithm and profile it in software (`esl/spec`) to identify Gaussian blur as the hotspot worth accelerating.
2. **Model** the target fixed-point precision (`esl/bit_analysis`) and system architecture (`esl/vp`), then **co-simulate** the SystemC platform against the real VHDL core (`esl/cosim`) before committing to silicon-bound RTL.
3. **Verify** the standalone RTL core against golden vectors using the SystemVerilog testbench (`fvh`).
4. **Integrate and implement** the RTL as an AXI4-Lite IP core in a Zynq block design, constrain it for the Zybo Z7, and validate it with a bare-metal Vitis application (`psds`).
5. **Deploy** the accelerator under Linux via a platform driver and drive it from a full user-space SIFT application (`eos`).

## Requirements

- Xilinx/AMD Vivado and Vitis (2023-era, matching the Zybo Z7 / Zynq-7000 tool support referenced in `psds/vitis`)
- Cadence Xcelium (`xmsc_run`) for SystemC↔VHDL co-simulation (`esl/cosim`)
- SystemC library (with fixed-point, `SC_INCLUDE_FX`) for `esl/bit_analysis` and `esl/vp`
- A C++20-capable compiler (`g++`) for the ESL and `eos` applications
- Linux kernel headers matching the target (PetaLinux/Zynq) for building `eos/driver`

## Authors

Developed by Luka Papić and Borislav Surovi
