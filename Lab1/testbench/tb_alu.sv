`timescale 1ns / 1ps
/**
 * Checkout https://www.chipverify.com/verilog/verilog-testbench for more info about writing testbench.
 * Here we use System Verilog to make the testbench easier to write.
 */

module tb_alu #(
    parameter integer NUM_TEST = 1  // # of test file to run
);

    /* input of tested module should be reg */
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [ 3:0] ALU_ctl;
    /* output from tested module should be wire */
    wire [31:0] result;
    wire        zero;
    wire        overflow;
    /* reg storing correct answer */
    reg  [31:0] ansr_result;
    reg         ansr_zero;
    reg         ansr_overflow;

    alu alu (  // instantiate tested module
        .a       (a),
        .b       (b),
        .ALU_ctl (ALU_ctl),
        .result  (result),
        .zero    (zero),
        .overflow(overflow)
    );

    /* test arguments */

    /* entry of the testbench & record results */
    initial begin
        automatic int passed_cnt = 0;
        automatic int failed_cnt = 0;
        automatic int ret = 1;
        automatic reg rets           [NUM_TEST];
        $display("#### tb_alu.sv ####");
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

    task automatic test(  // read mem file and perform test
        input int test_id,  // test to process
        output int ret    // return value (0: EXIT_SUCCESS, 1: EXIT_FAILURE)
    );
        int    fd;
        string line;
        int    case_cnt = 0;
        begin
            fd = $fopen($sformatf("tb_alu.%0d.txt", test_id), "r");  // name test file like this
            if (0 == fd) begin
                $display("failed to open: %s", $sformatf("tb_alu.%0d.txt", test_id));
                ret = 1;
                return;
            end  // https://www.chipverify.com/systemverilog/systemverilog-file-io

            /* test */
            for (int i = 0; $fgets(line, fd); i++) begin
                /* parse testcase */
                string str_a, str_b, str_ALU_ctl, str_ansr_result;
                int num_scan = $sscanf(
                    line,
                    "%s %s %s %s %1b %1b",
                    str_a,
                    str_b,
                    str_ALU_ctl,
                    str_ansr_result,
                    ansr_zero,
                    ansr_overflow
                );
                if ((6 == num_scan) || (4 == num_scan)) begin
                    reg [3:0] err;
                    {err[0], a}           = parseNum(str_a);  // parse int
                    {err[1], b}           = parseNum(str_b);
                    {err[2], ansr_result} = parseNum(str_ansr_result);
                    {err[3], ALU_ctl}     = parseALU_ctl(str_ALU_ctl);
                    if (|err) begin
                        $display("testcase with wrong format: \"%s\"", line);
                        ret = 1;
                        return;
                    end else begin  // all input of ALU is connected
                        $display("[case %2d] 0x%8h %4b 0x%8h %s", i, a, ALU_ctl, b,
                                 (4 == num_scan) ? "(ignore zv)" : "");
                    end
                end else begin
                    $display("testcase with wrong format: \"%s\"", line);
                    ret = 1;
                    return;
                end

                /* check */
                #1;  // wait for 1 time unit for ALU to process combinational logic
                if (result !== ansr_result) begin
                    $display("wrong `result`: expected 0x%8h found 0x%8h", ansr_result, result);
                    ret = 1;
                    return;
                end
                if ((6 == num_scan) && (zero !== ansr_zero)) begin
                    $display("wrong `zero`: expected 0x%8h found 0x%8h", ansr_zero, zero);
                    ret = 1;
                    return;
                end
                if ((6 == num_scan) && (overflow !== ansr_overflow)) begin
                    $display("wrong `overflow`: expected 0x%8h found 0x%8h", ansr_overflow,
                             overflow);
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

    /* [3:0] is the parsed ALU_ctl, [4] is set when parse failed */
    function automatic reg [4:0] parseALU_ctl(string str);
        reg [4:0] ret = 5'b0;
        if (str == "AND") ret[3:0] = 4'b0000;
        else if (str == "OR") ret[3:0] = 4'b0001;
        else if (str == "ADD") ret[3:0] = 4'b0010;
        else if (str == "SUB") ret[3:0] = 4'b0110;
        else if (str == "SLT") ret[3:0] = 4'b0111;
        else if (str == "NOR") ret[3:0] = 4'b1100;
        else ret[4] = 1'b1;
        return ret;
    endfunction

endmodule
