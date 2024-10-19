`timescale 1ns / 1ps
// 111550076

/** [Reading] 4.4 p.316-318
 * "The ALU Control"
 */
/**
 * This module is the ALU control in FIGURE 4.17
 * You can implement it by any style you want.
 * There's a more hardware efficient design in Appendix D.
 */

/* checkout FIGURE 4.12/13 */
module alu_control (
    input  [1:0] alu_op,    // ALUOp
    input  [5:0] funct,     // Funct field
    output reg [3:0] operation  // Operation
);

    always @(*)begin
        casex({alu_op, funct})
            8'b10_100100: operation = 4'b0000; // and
            8'b10_100101: operation = 4'b0001; // or
            8'b10_100000,8'b00_xxxxxx: operation = 4'b0010; // add lw sw addi
            8'b10_100010, 8'b01_xxxxxx: operation = 4'b0110; // sub beq
            8'b10_101010: operation = 4'b0111; // slt
            default: operation = 4'b1111; // nop
        endcase
    end
endmodule