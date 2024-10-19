`timescale 1ns / 1ps

/** Data Memory
 * Do not modify this module!
 * Instantiate with:
 *     data_mem #(.BYTES(<num>)) <name>(...);
 */
module data_mem #(
    parameter integer BYTES = 1024,       // size of the memory in bytes
    parameter integer START = 'h10008000  // start address of memory
) (
    input         clk,         // clock
    input         mem_read,    // enable read
    input         mem_write,   // enable write
    input  [31:0] address,     // word-aligned address of instruction
    input  [31:0] write_data,  // data write to memory at address
    output [31:0] read_data    // data read from memory at address
);

    reg [7:0] memory[START:(START+BYTES-1)];

    // MIPS is big-endian.
    wire [31:0] word = {memory[address], memory[address+1], memory[address+2], memory[address+3]};

    assign read_data = mem_read ? word : 0;

    always @(posedge clk) begin
        if (mem_write) begin
            {memory[address], memory[address+1], memory[address+2], memory[address+3]} <= write_data;
        end
    end

endmodule
