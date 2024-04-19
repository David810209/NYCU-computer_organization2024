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
    output       reg_dst,     // select register destination: rt(0), rd(1)
    output       jump,
    output       alu_src,     // select 2nd operand of ALU: rt(0), sign-extended(1)
    output       mem_to_reg,  // select data write to register: ALU(0), memory(1)
    output       reg_write,   // enable write to register file
    output       mem_read,    // enable read form data memory
    output       mem_write,   // enable write to data memory
    output       branch,      // this is a branch instruction or not (work with alu.zero)
    output       lui_op,
    output       ori_op,
    output [1:0] alu_op // ALUOp passed to ALU Control unit
);

    /* implement "combinational" logic satisfying requirements in FIGURE 4.18 */
    /* You can check the "Green Card" to get the opcode/funct for each instruction. */
    /*
    r-format 000000
    lw       100011
    sw       101011
    beq      000100
    lui      001111
    ori      001101
    j        000010
    nop      0000000000000000000000000000
    */
    wire lw_op;
    assign lui_op = opcode == 6'b001111;
    assign ori_op = opcode == 6'b001101;
    assign lw_op = opcode==6'b100011 | lui_op | ori_op;
    assign reg_dst = opcode== 6'b000000;
    assign alu_src = (lw_op || opcode==6'b101011);
    assign mem_to_reg = lw_op;
    assign reg_write = opcode == 6'b000000 ||lw_op;
    assign mem_read = lw_op;
    assign mem_write = opcode==6'b101011;
    assign branch = opcode == 6'b000100;
    assign alu_op[1] = opcode== 6'b000000;
    assign alu_op[0] = opcode== 6'b000100;
    assign jump = opcode == 6'b000010;
    
    
    
endmodule
