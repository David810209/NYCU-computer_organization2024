`timescale 1ns / 1ps
// 111550076

/* checkout FIGURE C.5.10 (Bottom) */
/* [Prerequisite] complete bit_alu.v */
module msb_bit_alu (
    input        a,          // 1 bit, a
    input        b,          // 1 bit, b
    input        less,       // 1 bit, Less
    input        a_invert,   // 1 bit, Ainvert
    input        b_invert,   // 1 bit, Binvert
    input        carry_in,   // 1 bit, CarryIn
    input  [1:0] operation,  // 2 bit, Operation
    output reg      result,     // 1 bit, Result (Must it be a reg?)
    output       set,        // 1 bit, Set
    output       overflow    // 1 bit, Overflow
);

    /* [step 1] invert input on demand */
    wire ai, bi;  // what's the difference between `wire` and `reg` ?
    assign ai = a_invert ? ~a : a;  // remember `?` operator in C/C++?
    //assign bi = (???)| (???);  // you can use logical expression too!
    assign bi = b_invert ? ~b : b;

    /* [step 2] implement a 1-bit full adder */
    /**
     * Full adder should take ai, bi, carry_in as input, and carry_out, sum as output.
     * What is the logical expression of each output? (Checkout C.5.1)
     * Is there another easier way to implement by `+` operator?
     * https://www.chipverify.com/verilog/verilog-combinational-logic-assign
     * https://www.chipverify.com/verilog/verilog-full-adder
     */
    wire sum;
    wire carry_out;
    assign carry_out = (ai & bi) | ((ai ^ bi) & carry_in);
    assign sum       = (ai ^ bi) ^ carry_in;

    //slt 
    //don't know how to do
    assign set = sum ^ overflow_count;

    //overflow
    assign overflow = (operation == 2'b11) ? 0 : carry_in ^ carry_out;//carryin of msb != carryout msb 
    assign overflow_count =  carry_in ^ carry_out;

    /* [step 3] using a mux to assign result */
    always @(*) begin  // `*` auto captures sensitivity ports, now it's combinational logic
        case (operation)  // `case` is similar to `switch` in C
            2'b00:   result <= ai & bi;  // AND
            2'b01:   result <= ai | bi;  // OR
            2'b10:   result <= sum;  // ADD
            2'b11:   result <= less;  // SLT
            default: result <= 0;  // should not happened
        endcase
    end
endmodule
