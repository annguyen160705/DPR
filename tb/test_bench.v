`timescale 1ns/1ps

module test_bench;

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 8;
parameter DEPTH      = (1 << ADDR_WIDTH);

reg clk;
reg rst_n;

reg                     en_a;
reg                     we_a;
reg [ADDR_WIDTH-1:0]    addr_a;
reg [DATA_WIDTH-1:0]    din_a;
wire [DATA_WIDTH-1:0]   dout_a;

reg                     en_b;
reg                     we_b;
reg [ADDR_WIDTH-1:0]    addr_b;
reg [DATA_WIDTH-1:0]    din_b;
wire [DATA_WIDTH-1:0]   dout_b;

integer pass_cnt;
integer fail_cnt;

reg [DATA_WIDTH-1:0] rd_data;

dual_port_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
dut(
    .clk(clk),
    .rst_n(rst_n),

    .en_a(en_a),
    .we_a(we_a),
    .addr_a(addr_a),
    .din_a(din_a),
    .dout_a(dout_a),

    .en_b(en_b),
    .we_b(we_b),
    .addr_b(addr_b),
    .din_b(din_b),
    .dout_b(dout_b)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

task reset_dut;
begin

    rst_n = 0;

    en_a = 0;
    we_a = 0;
    addr_a = 0;
    din_a = 0;

    en_b = 0;
    we_b = 0;
    addr_b = 0;
    din_b = 0;

    repeat(2) @(posedge clk);

    rst_n = 1;

    @(posedge clk);

end
endtask

task check_data;

input [255:0] test_name;
input [31:0] expected;
input [31:0] actual;

begin

    if(actual === expected) begin
        pass_cnt = pass_cnt + 1;
        $display("[PASS] %-38s Expected=%h Actual=%h",
                    test_name, expected, actual);
    end
    else begin
        fail_cnt = fail_cnt + 1;
        $display("[FAIL] %-38s Expected=%h Actual=%h",
                    test_name, expected, actual);
    end

end

endtask

task portA_write;
input [ADDR_WIDTH-1:0] addr;
input [DATA_WIDTH-1:0] data;
begin
    @(negedge clk);
    en_a   = 1;
    we_a   = 1;
    addr_a = addr;
    din_a  = data;
    @(posedge clk);
    @(negedge clk);
    en_a = 0;
    we_a = 0;
end
endtask

task portA_read;
input  [ADDR_WIDTH-1:0] addr;
output [DATA_WIDTH-1:0] data;
begin
    @(negedge clk);
    en_a   = 1;
    we_a   = 0;
    addr_a = addr;
    @(posedge clk);
    #1;
    data = dout_a;
    @(negedge clk);
    en_a = 0;
end
endtask

task portB_write;
input [ADDR_WIDTH-1:0] addr;
input [DATA_WIDTH-1:0] data;
begin
    @(negedge clk);
    en_b   = 1;
    we_b   = 1;
    addr_b = addr;
    din_b  = data;
    @(posedge clk);
    @(negedge clk);
    en_b = 0;
    we_b = 0;
end
endtask

task portB_read;
input  [ADDR_WIDTH-1:0] addr;
output [DATA_WIDTH-1:0] data;
begin
    @(negedge clk);
    en_b   = 1;
    we_b   = 0;
    addr_b = addr;
    @(posedge clk);
    #1;
    data = dout_b;
    @(negedge clk);
    en_b = 0;
end
endtask

initial begin

    reset_dut();
    pass_cnt = 0;
    fail_cnt = 0;

    
    // TC1: Reset
    check_data("TC1 Reset PortA",             32'h00000000, dout_a);
    check_data("TC1 Reset PortB",              32'h00000000, dout_b);

    
    // TC2: Port A Write/Read
    portA_write(8'h10, 32'h11111111);
    portA_read (8'h10, rd_data);
    check_data("TC2 PortA Write/Read",         32'h11111111, rd_data);

    
    // TC3: Port B Write/Read
    portB_write(8'h20, 32'h22222222);
    portB_read (8'h20, rd_data);
    check_data("TC3 PortB Write/Read",         32'h22222222, rd_data);

    // TC4: Same address write, Port A priority
    @(negedge clk);
    en_a = 1; we_a = 1; addr_a = 8'h40; din_a = 32'hAAAAAAAA;
    en_b = 1; we_b = 1; addr_b = 8'h40; din_b = 32'hCCCCCCCC;
    @(posedge clk);
    @(negedge clk);
    en_a = 0; we_a = 0; en_b = 0; we_b = 0;

    portA_read(8'h40, rd_data);
    check_data("TC4 PortA Priority (dout)",    32'hAAAAAAAA, rd_data);

    
    // TC5: Write-first A -> B
    @(negedge clk);
    en_a = 1; we_a = 1; addr_a = 8'h50; din_a = 32'h12345678;
    en_b = 1; we_b = 0; addr_b = 8'h50;
    @(posedge clk);
    #1;
    check_data("TC5 WriteFirst A->B",          32'h12345678, dout_b);
    @(negedge clk);
    en_a = 0; we_a = 0; en_b = 0;

    
    // TC6: Write-first B -> A
    @(negedge clk);
    en_b = 1; we_b = 1; addr_b = 8'h60; din_b = 32'h87654321;
    en_a = 1; we_a = 0; addr_a = 8'h60;
    @(posedge clk);
    #1;
    check_data("TC6 WriteFirst B->A",          32'h87654321, dout_a);
    @(negedge clk);
    en_a = 0; en_b = 0; we_b = 0;

    
    // TC7: Overwrite
    portA_write(8'h70, 32'h11111111);
    portA_write(8'h70, 32'hAAAAAAAA);
    portA_read (8'h70, rd_data);
    check_data("TC7 Overwrite",                32'hAAAAAAAA, rd_data);


    $display("\n==========================================");
    $display("          SIMULATION SUMMARY");
    $display("==========================================");
    $display("PASS = %0d", pass_cnt);
    $display("FAIL = %0d", fail_cnt);
    $display("==========================================\n");

    #20;
    $finish;

end

initial begin
    $monitor(
        "T=%0t | A:(en=%b we=%b addr=%h din=%h dout=%h) | B:(en=%b we=%b addr=%h din=%h dout=%h)",
        $time, en_a, we_a, addr_a, din_a, dout_a,
        en_b, we_b, addr_b, din_b, dout_b
    );
end

endmodule