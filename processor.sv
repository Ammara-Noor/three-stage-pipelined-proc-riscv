module processor
(
    input logic clk,
    input logic rst
);
    // wires
    logic        rf_en;
    logic        rf_en_mem;

    logic        sel_a;
    logic        sel_b;
    logic [1:0]  sel_wb;
    logic [1:0]  sel_wb_mem;
    logic        rd_en;
    logic        rd_en_mem;
    logic        wr_en;
    logic        wr_en_mem;

    logic        csr_wr;
    logic        csr_rd;
    logic        t_intr;
    logic        e_intr;
    logic        is_mret;
    logic        intr;
    logic        csr_op_sel;

    logic [31:0] pc_in;
    logic [31:0] pc_out_if;
    logic [31:0] pc_out_id;
    logic [31:0] pc_out_mem;
    logic [31:0] epc;
    logic [31:0] selected_pc;

    logic [31:0] inst_if;
    logic [31:0] inst_id;
    logic [ 4:0] rd;
    logic [ 4:0] rd_id;
    logic [ 4:0] rd_mem;
    logic [ 4:0] rs1;
    logic [ 4:0] rs1_id;
    logic [ 4:0] rs2;
    logic [ 4:0] rs2_id;
    logic [ 6:0] opcode;
    logic [ 2:0] funct3;
    logic [ 6:0] funct7;

    logic [31:0] rdata1;
    logic [31:0] rdata2;
    logic [31:0] rdata2_mem;
    logic [31:0] opr_a;
    logic [31:0] opr_b;
    logic [31:0] imm;

    logic [31:0] wdata;
    logic [31:0] alu_out;
    logic [31:0] alu_out_mem;
    logic [31:0] data_mem_out;
    logic [31:0] csr_data_out;
    logic [31:0] csr_op;

    logic [3 :0] aluop;
    logic [2:0] mem_mode;
    logic [2:0] br_type;

    logic br_taken;
    logic jump;
    logic flush;

    logic sel_a_fwd;
    logic sel_b_fwd;

    logic [31:0] rs1_fwd;
    logic [31:0] rs2_fwd;

    // --------- Fetch -----------

    // program counter
    pc pc_i
    (
        .clk(clk),
        .rst(rst),
        .pc_in(selected_pc),
        .pc_out(pc_out_if)
    );

    // instruction memory
    inst_mem inst_mem_i
    (
        .addr(pc_out_if),
        .data(inst_if)
    );

    mux_2x1 pc_sel_mux
    (
        .sel(br_taken | jump),
        .input_a(pc_out_if + 32'd4),
        .input_b(alu_out),
        .out_y(pc_in)
    );

    mux_2x1 pc_final_sel
    (
        .sel(intr),
        .input_a(pc_in),
        .input_b(epc),
        .out_y(selected_pc)
    );  

    // Fetch & Decode buffer 
    always_ff @( posedge clk ) 
    begin
        if (rst)
        begin
            inst_id <= 0;
            pc_out_id <= 0;
        end 
        else
        begin
            if (flush) 
            begin
                inst_id <= 32'h00000013; // NOP
                pc_out_id <= 'b0;
            end
            else
            begin
                inst_id <= inst_if;
                pc_out_id <= pc_out_if;
            end 
        end       
    end


    // --------- Decode -----------

    // instruction decoder
    inst_dec inst_dec_i
    (
        .inst(inst_id),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7)
    );

    // register file
    reg_file reg_file_i
    (
        .clk(clk),
        .rf_en(rf_en),
        .waddr(rd_mem),
        .rs1(rs1),
        .rs2(rs2),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .wdata(wdata)
    );

    // controller
    controller controller_i
    (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .aluop(aluop),
        .rf_en(rf_en),
        .sel_a(sel_a),
        .sel_b(sel_b),
        .sel_wb(sel_wb),
        .rd_en(rd_en),
        .wr_en(wr_en),
        .mem_mode(mem_mode),
        .br_type(br_type),
        .jump(jump),
        .csr_rd(csr_rd),
        .csr_wr(csr_wr),
        .is_mret(is_mret),
        .csr_op_sel(csr_op_sel)
    );

    //immediate generator
    imm_gen imm_gen_i
    (
        .inst(inst_id),
        .imm(imm)
    );


    // --------- Execute -----------

    // forwarding multiplexers
    mux_2x1 sel_a_fwd_mux
    (
        .sel(sel_a_fwd),
        .input_a(rdata1),
        .input_b(wdata),
        .out_y(rs1_fwd)
    );

    mux_2x1 sel_b_fwd_mux
    (
        .sel(sel_b_fwd),
        .input_a(rdata2),
        .input_b(wdata),
        .out_y(rs2_fwd)
    );

    // alu
    alu alu_i
    (
        .aluop(aluop),
        .opr_a(opr_a),
        .opr_b(opr_b),
        .opr_res(alu_out)
    );

    //branch comparator
    branch_cond branch_cond_i
    (
        .rdata1(rdata1),
        .rdata2(rdata2),
        .br_type(br_type),
        .br_taken(br_taken)
    );

    //sel_a_mux
    mux_2x1 sel_a_mux
    (
        .sel(sel_a),
        .input_a(rs1_fwd),
        .input_b(pc_out_id),
        .out_y(opr_a)
    );

    //sel_b_mux for I-type
    mux_2x1 sel_b_mux
    (
        .sel(sel_b),
        .input_a(rs2_fwd),
        .input_b(imm),
        .out_y(opr_b)
    );

    // Execute & Memory buffer
    always_ff @( posedge clk ) 
    begin
        if (rst)
        begin
            pc_out_mem <= 0;
            alu_out_mem <= 0;
            rdata2_mem <= 0;
            rf_en_mem <= 0;
            wr_en_mem <= 0;
            rd_en_mem <= 0;
            sel_wb_mem <= 0;
            rd_mem <= 0;
        end 
        else
        begin
            pc_out_mem <= pc_out_id;
            alu_out_mem <= alu_out;
            rdata2_mem <= rdata2;
            rf_en_mem <= rf_en;
            wr_en_mem <= wr_en;
            rd_en_mem <= rd_en;
            sel_wb_mem <= sel_wb;
            rd_mem <= rd;
        end       
    end

    // --------- Memory ------------

    data_mem data_mem_i
    (
        .clk(clk),
        .rd_en(rd_en_mem),
        .wr_en(wr_en_mem),
        .addr(alu_out_mem),
        .wdata(rdata2_mem),
        .mem_mode(mem_mode),
        .out_data(data_mem_out)
    );

    //csr
    csr csr_i
    (
        .clk(clk),
        .rst(rst),
        .pc_input(pc_in),
        .addr(alu_out_mem),
        .wdata(csr_op),
        .inst(inst_id),
        .csr_rd(csr_rd),
        .csr_wr(csr_wr),
        .t_intr(t_intr),
        .e_intr(e_intr),
        .is_mret(is_mret),
        .rdata(csr_data_out),
        .epc(epc),
        .intr(intr)
    );    

    mux_2x1 sel_csr_op
    (
        .sel(csr_op_sel),
        .input_a(rdata1),
        .input_b(imm),
        .out_y(csr_op)
    );

    //write back selection for load instructions
    mux_4x1 sel_wb_mux
    (
        .sel(sel_wb_mem),
        .input_a(alu_out_mem),  
        .input_b(data_mem_out),
        .input_c(pc_out_mem+4),
        .input_d(csr_data_out),
        .out_y(wdata)
    );

    // hazard unit
    hazard_unit hazard_unit_i
    (
        .rf_en(rf_en_mem),
        .brj(br_taken | jump),
        .rs1(rs1_id),
        .rs2(rs2_id),
        .rd(rd_mem),
        .sel_a_fwd(sel_a_fwd),
        .sel_b_fwd(sel_b_fwd),
        .flush(flush)
    );
    
endmodule