`timescale 1ns / 1ps
// 111550076

/* checkout FIGURE C.5.12 */
/** [Prerequisite] complete bit_alu.v & msb_alu.v
 * We recommend you to design a 32-bit ALU with 1-bit ALU.
 * However, you can still implement ALU with more advanced feature in Verilog.
 * Feel free to code as long as the I/O ports remain the same shape.
 */
module alu (
    input  [31:0] a,        // 32 bits, source 1 (A)
    input  [31:0] b,        // 32 bits, source 2 (B)
    input  [ 3:0] ALU_ctl,  // 4 bits, ALU control input
    output [31:0] result,   // 32 bits, result
    output        zero,     // 1 bit, set to 1 when the output is 0
    output        overflow  // 1 bit, overflow
);
    /* [step 1] instantiate multiple modules */
    /**
     * First, we need wires to expose the I/O of 32 1-bit ALUs.
     * You might wonder if we can declare `operation` by `wire [31:0][1:0]` for better readability.
     * No, that is a feature call "packed array" in "System Verilog" but we are using "Verilog" instead.
     * System Verilog and Verilog are similar to C++ and C by their relationship.
     */
    wire [31:0] less, carry_in;
    wire [31:0] carry_out;
    reg [1:0] operation;  // flatten vector
    wire a_invert, b_invert; //inverter
    wire        set;  // set of most significant bit
    
    //sub(0110) handle
    assign a_invert = 0;
    assign b_invert = (ALU_ctl == 4'b0110 || ALU_ctl == 4'b0111);
    assign carry_in[0] = (ALU_ctl == 4'b0110 || ALU_ctl == 4'b0111) ;

    //operation
    always @(*) begin
        case (ALU_ctl)
            4'b0000: operation = 2'b00;  // AND
            4'b0001: operation = 2'b01;  // OR
            4'b0010: operation = 2'b10;  // ADD
            4'b0110: operation = 2'b10;  // SUB
            4'b1100: operation = 2'b01;  // NOR 
            4'b0111: operation = 2'b11;  // SLT
            default: operation = 2'b00;  
        endcase
    end

    //set
    assign less[31:0] =0;

    wire [31:0] tmp_result;
    /**
     * Second, we instantiate the less significant 31 1-bit ALUs
     * How are these modules wried?
     */
    bit_alu lsb0(
        .a        (a[0]),
        .b        (b[0]),
        .less     (set),
        .a_invert (a_invert),
        .b_invert (b_invert),
        .carry_in (carry_in[0]),
        .operation(operation[1:0]),
        .result   (tmp_result[0]),
        .carry_out(carry_out[0])
    );

    bit_alu lsbs[30:1] (
        .a        (a[30:1]),
        .b        (b[30:1]),
        .less     (less[30:1]),
        .a_invert (a_invert),
        .b_invert (b_invert),
        .carry_in (carry_in[30:1]),
        .operation(operation[1:0]),
        .result   (tmp_result[30:1]),
        .carry_out(carry_out[30:1])
    );
    /* Third, we instantiate the most significant 1-bit ALU */
    msb_bit_alu msb (
        .a        (a[31]),
        .b        (b[31]),
        .less     (less[31]),
        .a_invert (a_invert),
        .b_invert (b_invert),
        .carry_in (carry_in[31]),
        .operation(operation[1:0]),
        .result   (tmp_result[31]),
        .set      (set),
        .overflow (overflow)
    );
    /** [step 2] wire these ALUs correctly
     * 1. `a` & `b` are already wired.
     * 2. About `less`, only the least significant bit should be used when SLT, so the other 31 bits ...?
     *    checkout: https://www.chipverify.com/verilog/verilog-concatenation
     * 3. `a_invert` should all connect to ?
     * 4. `b_invert` should all connect to ? (name it `b_negate` first!)
     * 5. What is the relationship between `carry_in[i]` & `carry_out[i-1]` ?
     * 6. `carry_in[0]` and `b_invert` appears to be the same when SUB... , right?
     * 7. `operation` should be wired to which 2 bits in `ALU_ctl` ?
     * 8. `result` is already wired.
     * 9. `set` should be wired to which `less` bit?
     * 10. `overflow` is already wired.
     * 11. You need another logic for `zero` output.
     */

    //carryin and carryout
    /*
    genvar i;
    generate
        for (i = 0; i < 31; i = i + 1) begin : carry_chain
            assign carry_in[i+1] = carry_out[i];
        end
    endgenerate*/

   assign carry_in[31:1] = carry_out[30:0];
    //nor handle
    assign result = (ALU_ctl == 4'b1100) ? ~tmp_result : tmp_result;



    //zero output
   assign zero = ~|result;

endmodule