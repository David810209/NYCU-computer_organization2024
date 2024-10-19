`timescale 1ns / 1ps

module tb_pipelined #(
    parameter integer NUM_TEST   = 1,           // # of test file to run
    parameter integer TIMEOUT    = 200,         // maximum cycles (time limit) for each test
    parameter integer TEXT_BYTES = 1024,        // size in bytes of instruction memory
    parameter integer TEXT_START = 'h00400000,  // start address of instruction memory
    parameter integer DATA_BYTES = 1024,        // size in bytes of data memory
    parameter integer DATA_START = 'h10008000   // start address of data memory
);

    reg clk = 1;  // swapped compared to Lab 2 since we need negedge
    reg rstn = 1;

    pipelined #(
        .TEXT_BYTES(TEXT_BYTES),
        .TEXT_START(TEXT_START),
        .DATA_BYTES(DATA_BYTES),
        .DATA_START(DATA_START)
    ) pipelined (
        .clk (clk),
        .rstn(rstn)
    );

    /* the correct state after instruction execution */
    reg  [31:0] ans_reg_file   [                                  32];
    reg  [ 7:0] ans_data_memory[DATA_START:(DATA_START+DATA_BYTES-1)];

    /* ports for observation */
    wire [31:0] reg_file       [                                  32];
    wire [ 7:0] instr_memory   [TEXT_START:(TEXT_START+TEXT_BYTES-1)];
    wire [ 7:0] data_memory    [DATA_START:(DATA_START+DATA_BYTES-1)];
    assign reg_file     = pipelined.reg_file.registers;
    assign instr_memory = pipelined.instr_mem.memory;
    assign data_memory  = pipelined.data_mem.memory;

    /* entry of the testbench & record results */
    initial begin
        automatic integer passed_cnt = 0;
        automatic integer failed_cnt = 0;
        automatic integer ret = 1;
        automatic integer rets           [NUM_TEST];
        $display("#### tb_pipelined.sv ####");
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
        input integer test_id,  // test to process
        output integer ret  // return value (0: EXIT_SUCCESS, 1: EXIT_FAILURE)
    );
        reg [31:0] exit_address;  // exit when pc equals to this address
        int        cycles;
        reg        memory_equal;

        /* reset processor */
        #1 rstn = 0;
        #1 rstn = 1;

        /* load memory */
        exit_address = load_memory(test_id);
        if (exit_address == TEXT_START) begin
            $display("load_memory failed");
            ret = 3;
            return;
        end
        exit_address += 4 * 4;  // 5-stage pipeline need 4 more cycle to finish

        /* processor runs until pc points to exit address */
        for (cycles = 0; (cycles < TIMEOUT) && (pipelined.pc !== exit_address); cycles++) begin
            #2 clk = 0;  // negedge  // swapped compared to Lab 2 since we need negedge
            #2 clk = 1;  // posedge
        end
        #1 $display("run %0d cycles", cycles);

        if (cycles >= TIMEOUT) begin  /* TLE */
            $display("(Time Limit Exceeded)");
            ret = 1;
        end else begin  /* judge by memory and register equality */
            ret = check_memory();
        end
        return;
    endtask

    // count lines in file
    function automatic integer count_lines(string filename);
        int    cnt = 0;
        string line;
        int    fd = $fopen(filename, "r");
        if (fd) for (; $fgets(line, fd); cnt++);
        return cnt;
    endfunction

    // load .mem files and return exit address
    function automatic reg [31:0] load_memory(integer id);
        int        num_instr = 0;
        reg [31:0] exit_address = TEXT_START;
        pipelined.instr_mem.memory = '{default: 0};  // clear
        pipelined.data_mem.memory  = '{default: 0};
        ans_data_memory            = '{default: 0};
        ans_reg_file               = '{default: 0};
        $readmemh($sformatf("%0d.reg.mem", id), pipelined.reg_file.registers);  // initial reg
        $readmemh($sformatf("%0d.text.mem", id), pipelined.instr_mem.memory);  // instr memory
        $readmemh($sformatf("%0d.data.mem", id), pipelined.data_mem.memory);  // data memory
        $readmemh($sformatf("%0d.ans_reg.mem", id), ans_reg_file);  // ans register file memory
        $readmemh($sformatf("%0d.ans_data.mem", id), ans_data_memory);  // ans data memory
        num_instr    = count_lines($sformatf("%0d.text.mem", id));
        exit_address = TEXT_START + (num_instr * 4);
        $display("number of instructions: %0d , exit @ 0x%8h", num_instr, exit_address);
        return exit_address;
    endfunction

    function automatic integer check_memory();
        integer reg_equal = (pipelined.reg_file.registers === ans_reg_file);
        integer data_equal = (pipelined.data_mem.memory === ans_data_memory);
        if (!reg_equal)
            for (int i = 0; i < 32; i++)
            if (reg_file[i] !== ans_reg_file[i]) begin
                $display("$%0d expect 0x%8h found 0x%8h", i, ans_reg_file[i], reg_file[i]);
            end
        if (!data_equal)
            for (int i = DATA_START; i < (DATA_START + DATA_BYTES); i += 4)
            if (data_memory[i+:4] !== ans_data_memory[i+:4]) begin
                $display("0x%8h expect 0x%8h found 0x%8h", i, ans_data_memory[i+:4],
                         data_memory[i+:4]);
            end
        return !(reg_equal && data_equal);
    endfunction

endmodule
