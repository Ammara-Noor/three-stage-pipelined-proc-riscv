module tb_processor();

    logic clk;
    logic rst;

    processor dut
    (
        .clk ( clk ),
        .rst ( rst )
    );

    // clock generator
    initial
    begin
        clk = 0;
        forever
        begin
            #5 clk = 1;
            #5 clk = 0;
        end
    end

    // reset generator
    initial
    begin
        rst = 1;
        #10;
        rst = 0;
        #300;
        $display("Processor is running");
        $display("x1: %b", dut.reg_file_i.reg_mem[1]);
        $display("x2: %b", dut.reg_file_i.reg_mem[2]);
        $display("x3: %b", dut.reg_file_i.reg_mem[3]);
        $display("x4: %b", dut.reg_file_i.reg_mem[4]);
        //$display("x5: %b", dut.reg_file_i.reg_mem[5]);
        // $display("x6: %b", dut.reg_file_i.reg_mem[6]);
        // $display("x7: %b", dut.reg_file_i.reg_mem[7]);
        
        $finish;
    end

    // initialize memory
    initial
    begin
        $readmemh("inst.mem", dut.inst_mem_i.mem);
        $readmemb("rf.mem", dut.reg_file_i.reg_mem);
    end

    // dumping the waveform
    initial
    begin
        $dumpfile("processor.vcd");
        $dumpvars(0, dut);
    end

endmodule