`timescale 1ns / 1ps

module Half_Subtractor(
    In_A, In_B, Difference, Borrow_out
    );
    input In_A, In_B;
    output Difference, Borrow_out;
    wire A_bar;
    
    // implement half subtractor circuit, your code starts from here.
    // hint: gate(output, input1, input2);
    xor( Difference,In_A ,In_B );
    not( A_bar, In_A);
    and(Borrow_out ,A_bar , In_B);

endmodule
