`timescale 1ns / 1ps
// 111550076

/** [Reading] 4.4 p.318-321
 * "Designing the Main Control Unit"
 */
/** [Prerequisite] alu_control.v
 * This module is the Control unit in FIGURE 4.17
 * You can implement it by any style you want.
 */

/* checkout FIGURE 4.16/18 to understand each definition of control signals */
module control (
    input  [5:0] opcode,      // the opcode field of a instruction is [?:?]
    input  [5:0] funct,
    output       reg_dst,     // select register destination: rt(0), rd(1)
    output       alu_src,     // select 2nd operand of ALU: rt(0), sign-extended(1)
    output       mem_to_reg,  // select data write to register: ALU(0), memory(1)
    output       reg_write,   // enable write to register file
    output       mem_read,    // enable read form data memory
    output       mem_write,   // enable write to data memory
    output       branch,      // this is a branch instruction or not (work with alu.zero)
    output [1:0] alu_op
);


    /* implement "combinational" logic satisfying requirements in FIGURE 4.18 */
    /* You can check the "Green Card" to get the opcode/funct for each instruction. */
    // ppt 32

    
    wire r, lw, sw, beq, addi;
    assign r = ~opcode[0] & ~opcode[1] & ~opcode[2] & ~opcode[3] & ~opcode[4] & ~opcode[5];
    assign lw = (opcode[0] & opcode[1] & ~opcode[2] & ~opcode[3] & ~opcode[4] & opcode[5]) ;
    assign sw = opcode[0] & opcode[1] & ~opcode[2] & opcode[3] & ~opcode[4] & opcode[5];
    assign beq = ~opcode[0] & ~opcode[1] & opcode[2] & ~opcode[3] & ~opcode[4] & ~opcode[5];
    assign addi = ~opcode[0] & ~opcode[1] & ~opcode[2] & opcode[3] & ~opcode[4] & ~opcode[5];
    assign nop = (r & ~|funct) ;
    assign reg_dst = r & ~nop;
    assign alu_src = (lw | sw | addi) & ~nop;
    assign mem_to_reg = lw & ~nop;
    assign reg_write = (r  | lw | addi) & ~nop;
    assign mem_read = lw & ~nop;
    assign mem_write = sw & ~nop;
    assign branch = beq & ~nop;
    assign alu_op[1] = r & ~nop;
    assign alu_op[0] = beq & ~nop;

endmodule