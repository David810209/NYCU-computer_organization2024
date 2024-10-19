module sw_forward (
    input      EX_MEM_mem_write,
    input      MEM_WB_mem_to_reg,
    input   [4:0] EX_MEM_rt,
    input   [4:0] MEM_WB_rd,
    output reg  sw_forward
);
    always @(*)begin
        if(EX_MEM_mem_write && MEM_WB_mem_to_reg && EX_MEM_rt != 0 && EX_MEM_rt== MEM_WB_rd)begin
            sw_forward <= 1;
        end
        else begin
            sw_forward <= 0;
        end
    end

endmodule