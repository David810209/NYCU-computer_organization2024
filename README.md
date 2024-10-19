# Computer Organization Labs

This repository contains the Verilog/SystemVerilog source code and reports for four computer organization labs, focusing on building key components of a MIPS-based processor. Each lab builds upon the previous one, culminating in a pipelined processor with hazard detection.

## Table of Contents
- [Lab 1: 32-bit ALU & Register File](#lab-1-32-bit-alu--register-file)
- [Lab 2: Single-Cycle Processor](#lab-2-single-cycle-processor)
- [Lab 3: Pipelined Processor - Part 1](#lab-3-pipelined-processor---part-1)
- [Lab 4: Pipelined Processor - Part 2](#lab-4-pipelined-processor---part-2)

## Lab 1: 32-bit ALU & Register File
In this lab, we implement a 32-bit Arithmetic Logic Unit (ALU) and a MIPS register file using Verilog. The ALU performs operations such as addition, subtraction, bitwise AND, OR, NOR, and set-less-than. The register file enables fast access to data during computation.

### Key Features:
- **ALU Operations**: AND, OR, ADD, SUB, NOR, SLT.
- **Zero & Overflow Detection**: Zero flag and overflow detection during addition/subtraction.
- **Register File**: Implemented with read/write capability on clock edge.
- **Testbenches**: Provided testbenches for both the ALU and register file.

### Files:
- `src/alu.v`
- `src/bit_alu.v`
- `src/msb_bit_alu.v`
- `src/reg_file.v`

## Lab 2: Single-Cycle Processor
In this lab, we construct a single-cycle MIPS processor that executes one instruction per clock cycle. The processor supports a subset of the MIPS instruction set, including arithmetic, logical, load, store, and branch instructions.

### Key Features:
- **Datapath**: Complete single-cycle datapath for MIPS instructions.
- **Control Unit**: ALU control and main control unit for instruction decoding.
- **Instruction Set**: Supports `add`, `sub`, `and`, `or`, `slt`, `lw`, `sw`, `beq`, `j`.
- **Testbenches**: Includes testbenches and assembly test cases.

### Files:
- `src/alu.v`
- `src/alu_control.v`
- `src/control.v`
- `src/single_cycle.v`
- `src/instr_mem.v`
- `src/data_mem.v`

## Lab 3: Pipelined Processor - Part 1
This lab introduces pipelining, where multiple instructions are executed simultaneously in different stages of the pipeline. In this part, we focus on implementing a pipelined processor without hazard detection.

### Key Features:
- **5-Stage Pipeline**: IF, ID, EX, MEM, WB stages for instruction execution.
- **Instruction Set**: Supports the same MIPS instructions as Lab 2.
- **Hazards**: No hazard detection implemented in this part.
- **Testbenches**: Includes testbenches for testing basic pipeline functionality.

### Files:
- `src/pipelined.v`
- `src/alu.v`
- `src/control.v`
- `src/instr_mem.v`
- `src/data_mem.v`

## Lab 4: Pipelined Processor - Part 2
In the final lab, we enhance the pipelined processor with hazard detection and resolution using forwarding and stalling techniques. The goal is to handle data and control hazards efficiently.

### Key Features:
- **Forwarding Unit**: For handling data hazards by forwarding ALU results to earlier stages.
- **Hazard Detection Unit**: Detects hazards and introduces stalls when necessary.
- **Branch Handling**: Implements correct handling of branches with delayed slots.
- **Testbenches**: Includes testbenches for hazard detection and branch handling.

### Files:
- `src/pipelined.v`
- `src/forwarding.v`
- `src/hazard_detection.v`
- `src/alu.v`
- `src/control.v`
- `src/instr_mem.v`
- `src/data_mem.v`

## How to Run
1. Clone the repository.
2. Use a Verilog simulator such as ModelSim or Vivado to compile and run the provided testbenches.
3. Follow the test instructions provided in each lab's report for detailed testing steps.

## Submission
Each lab report and source code is packaged in a zip file format, as required by the course guidelines.

## License
This project is for educational purposes. Please refrain from copying or redistributing without permission.
