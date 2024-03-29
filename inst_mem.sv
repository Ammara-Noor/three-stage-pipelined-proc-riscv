module inst_mem
(
    input  logic [31:0] addr,
    output logic [31:0] data
);
    // memory of row width 32 bits and there total 100 rows (32x100)
    logic [31:0] mem [100];

    always_comb
    begin
        // $display("pc:%b", addr);
        // $display("inst:%b", mem[addr[31:2]]);
        data = mem[addr[31:2]];
    end

endmodule