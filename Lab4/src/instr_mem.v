`timescale 1ns / 1ps

/** Instruction Memory
 * Do not modify this module!
 * Instantiate with:
 *     instr_mem #(.BYTES(<num>)) <name>(...);
 */
module instr_mem #(
    parameter integer BYTES = 1024,       // size of the memory in bytes
    parameter integer START = 'h00400000  // start address of memory
) (
    input  [31:0] address,  // word-aligned address of instruction
    output [31:0] instr     // instruction read from memory at address
);

    reg [7:0] memory[START:(START+BYTES-1)];

    // MIPS is big-endian.
    assign instr = {memory[address], memory[address+1], memory[address+2], memory[address+3]};

endmodule
