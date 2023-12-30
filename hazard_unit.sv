module hazard_unit (
    input logic rf_en,
    input logic brj, // branch and jump
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    output logic sel_a_fwd,
    output logic sel_b_fwd,
    output logic flush

);

always_comb 
begin
    sel_a_fwd = 0;
    sel_b_fwd = 0;
    flush = brj;
    if (rf_en) 
    begin
        if (rs1==rd & rs1==5'b0) 
        begin
            sel_a_fwd = 1;
        end
        if (rs2==rd & rs2==5'b0) 
        begin
            sel_b_fwd = 1;
        end 
    end
end
    
endmodule