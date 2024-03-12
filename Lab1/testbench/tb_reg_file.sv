`timescale 1ns / 1ps

module tb_reg_file #(
    parameter integer NUM_TEST = 1  // # of test file to run
);

    reg         clk = 0;
    reg         rstn = 1;
    reg  [ 4:0] read_reg_1 = 0;
    reg  [ 4:0] read_reg_2 = 0;
    reg         reg_write = 0;
    reg  [ 4:0] write_reg = 0;
    reg  [31:0] write_data = 0;
    wire [31:0] read_data_1 = 0;
    wire [31:0] read_data_2 = 0;

    reg_file reg_file (
        .clk        (clk),
        .rstn       (rstn),
        .read_reg_1 (read_reg_1),
        .read_reg_2 (read_reg_2),
        .reg_write  (reg_write),
        .write_reg  (write_reg),
        .write_data (write_data),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2)
    );

    /* entry of the testbench & record results */
    initial begin
        automatic int passed_cnt = 0;
        automatic int failed_cnt = 0;
        automatic int ret = 1;
        automatic reg rets           [NUM_TEST];
        $display("#### tb_reg_file.sv ####");
        for (int i = 0; i < NUM_TEST; i++) begin
            $display("==== Test %2d RUNNING ====", i);
            test(i, ret);
            rets[i] = ret;
            if (ret == 0) begin
                passed_cnt++;
                $display("==== Test %2d PASSED ====", i);
            end else begin
                failed_cnt++;
                $display("==== Test %2d FAILED ====", i);
            end
            #1;  // wait
        end
        $display("#### Test Result ####");
        $write("Passed %2d :", passed_cnt);
        for (int i = 0; i < NUM_TEST; i++) if (rets[i] == 0) $write(" %0d", i);
        $write("\n");
        $write("Failed %2d :", failed_cnt);
        for (int i = 0; i < NUM_TEST; i++) if (rets[i] != 0) $write(" %0d", i);
        $write("\n");
        if (passed_cnt == NUM_TEST) $display("#### all passed!");
        else $display("#### some failed.");
        $finish;
    end

    reg [31:0] ans_registers[32] = '{default: 32'b0};
    task automatic test(  // read mem file and perform test
        input int test_id,  // test to process
        output int ret    // return value (0: EXIT_SUCCESS, 1: EXIT_FAILURE)
    );
        int    fd;
        string line;
        int    case_cnt = 0;
        begin
            fd = $fopen($sformatf("tb_reg_file.%0d.txt", test_id), "r");
            if (0 == fd) begin
                $display("failed to open: %s", $sformatf("tb_reg_file.%0d.txt", test_id));
                ret = 1;
                return;
            end

            /* reset */
            ans_registers = '{default: 32'b0};
            #1 rstn = 0;
            #1 rstn = 1;

            /* test */
            for (int i = 0; $fgets(line, fd); i++) begin
                string str_write_data;
                if (5 == $sscanf(
                        line,
                        "%5b %5b %1b %5b %s",
                        read_reg_1,
                        read_reg_2,
                        reg_write,
                        write_reg,
                        str_write_data
                    )) begin
                    reg err;
                    {err, write_data} = parseNum(str_write_data);
                    if (err) begin
                        $display("testcase with wrong format: \"%s\"", line);
                        ret = 1;
                        return;
                    end
                    $display("[case %2d] %5b %5b %1b %5b 0x%8h", i, read_reg_1, read_reg_2,
                             reg_write, write_reg, write_data);
                    /* before write */
                    #1;  // wait for combinational logic
                    if (read_data_1 != ans_registers[read_reg_1]) begin
                        $display("wrong `read_data_1` before write: expected 0x%8h found 0x%8h !",
                                 ans_registers[read_reg_1], read_data_1);
                        ret = 1;
                        return;
                    end
                    if (read_data_2 != ans_registers[read_reg_2]) begin
                        $display("wrong `read_data_2` before write: expected 0x%8h found 0x%8h !",
                                 ans_registers[read_reg_2], read_data_2);
                        ret = 1;
                        return;
                    end
                    #1 clk = 1;  // each cycle has 2 time units of 1 and 2 time units of 0
                    /* after write */
                    if (reg_write) ans_registers[write_reg] = (write_reg == 0) ? 0 : write_data;
                    #2;  // wait for combinational & sequential logic
                    if (read_data_1 != ans_registers[read_reg_1]) begin
                        $display("wrong `read_data_1` after write: expected 0x%8h found 0x%8h !",
                                 ans_registers[read_reg_1], read_data_1);
                        ret = 1;
                        return;
                    end
                    if (read_data_2 != ans_registers[read_reg_2]) begin
                        $display("wrong `read_data_2` after write: expected 0x%8h found 0x%8h !",
                                 ans_registers[read_reg_2], read_data_2);
                        ret = 1;
                        return;
                    end
                    ans_registers[0] = reg_file.registers[0];
                    if (reg_file.registers !== ans_registers) begin
                        $display("wrong write or failed write!: ");
                        for (int i = 0; i < 32; i++) begin
                            if (reg_file.registers[i] !== ans_registers[i]) begin
                                $display("reg %2d expect 0x%h found 0x%h", i,
                                         reg_file.registers[i], ans_registers[i]);
                            end
                        end
                        ret = 1;
                        return;
                    end
                    clk = 0;
                end else if (line.substr(0, 4) == "reset") begin
                    $display("[case %2d] reset", i);
                    rstn          = 0;
                    ans_registers = '{default: 32'b0};
                    #2 clk = 1;
                    #2;
                    ans_registers[0] = reg_file.registers[0];
                    if (reg_file.registers !== ans_registers) begin
                        $display("registers not reset!");
                        ret = 1;
                        return;
                    end
                    rstn = 1;
                    clk  = 0;
                end else begin
                    $display("testcase with wrong format: \"%s\"", line);
                    ret = 1;
                    return;
                end
            end
            ret = 0;
            return;
        end
    endtask

    /* [31:0] is the parsed num, [32] is set when parse failed */
    function automatic reg [32:0] parseNum(string str);
        reg [32:0] ret = 32'b0;
        if ($sscanf(str, "0x%h", ret[31:0]));
        else if ($sscanf(str, "0b%b", ret[31:0]));
        else if ($sscanf(str, "%d", ret[31:0]));
        else ret[32] = 1'b1;
        return ret;
    endfunction

endmodule
