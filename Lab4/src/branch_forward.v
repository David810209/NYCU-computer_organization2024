module branch_forward(
    input       take_branch,
    input       EX_MEM_reg_dst,
    input       MEM_WB_mem_to_reg,
    input  [4:0] rs,
    input  [4:0]     rt,
    input [4:0] EX_MEM_rd,
    input [4:0] MEM_WB_rd,
    output reg [1:0] beq_forward_A,
    output reg [1:0] beq_forward_B
);
    always @(*)begin
       if(take_branch)begin
        //operation forward
            if(EX_MEM_reg_dst && EX_MEM_rd != 0 && EX_MEM_rd == rs ) begin
            beq_forward_A <= 2'b10;
            end
            //lw forward
            else if( MEM_WB_mem_to_reg && MEM_WB_rd != 0 &&  MEM_WB_rd == rs) begin
                beq_forward_A <= 2'b01;
            end
            else beq_forward_A <= 2'b00;
            //operation forward
            if(EX_MEM_reg_dst && EX_MEM_rd != 0 && EX_MEM_rd == rt)begin
                beq_forward_B <= 2'b10;
            end
            //lw forward
            else if(MEM_WB_mem_to_reg && MEM_WB_rd != 0 && MEM_WB_rd == rt) begin
                beq_forward_B <= 2'b01;
            end
            else beq_forward_B <= 2'b00;
       end
       else begin
              beq_forward_A <= 2'b00;
              beq_forward_B <= 2'b00;
         end
       
    end
    
   
endmodule