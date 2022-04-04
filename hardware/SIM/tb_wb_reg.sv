`timescale 1ns / 1ps

module tb_wb_reg;

    reg CLK_O;
    reg RST_O;
    reg [31:0] ADR_O;
    reg [31:0] DAT_O;
    wire [31:0] DAT_I;
    reg WE_O;
    reg [3:0] SEL_O;
    reg STB_O;
    wire ACK_I;
    reg CYC_O;
    wire STALL_I;

    wire [31:0] reg_output;

    reg [31:0] outstanding;

    task wb_write(input reg [31:0] data_i, addr);
    begin
        @(posedge CLK_O) CYC_O = 1'b1;
        STB_O = 1'b1;
        WE_O = 1'b1;
        DAT_O = data_i;
        ADR_O = addr;
        outstanding = outstanding + 1;
        @(posedge CLK_O);
        STB_O = 1'b0;
        WE_O = 1'b0;
        DAT_O = 32'h00000000;
        ADR_O = 32'h00000000;
        @(posedge CLK_O);
        CYC_O = 1'b0;
    end
    endtask

    initial
    begin
        CLK_O = 1'b0;
        RST_O = 1'b1;
        ADR_O = 32'h00000000;
        DAT_O = 32'h00000000;
        WE_O = 1'b0;
        STB_O = 1'b0;
        CYC_O = 1'b0;
        SEL_O = 4'b0000;
        outstanding = 0;
        repeat(4)@(posedge CLK_O);
        RST_O = 1'b0;
        repeat(2)@(posedge CLK_O);

        wb_write(32'hdeadbeef, 32'h00000000);
        wb_write(32'habcdef01, 32'h00000000);
        wb_write(32'habababab, 32'h00000000);
        wb_write(32'h00000000, 32'h00000000);
    end

    always #5 CLK_O = !CLK_O;

    wb_reg dut(
        .CLK_I(CLK_O), .RST_I(RST_O),
        .ADR_I(ADR_O[0:0]), .DAT_I(DAT_O), .DAT_O(DAT_I),
        .WE_I(WE_O), .SEL_I(SEL_O), .STB_I(STB_O),
        .ACK_O(ACK_I), .CYC_I(CYC_O), .STALL_O(STALL_I),
        .reg_output(reg_output)
    );

endmodule