`timescale 1ns/1ns

module dual_port_ram_tb;

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 8;

reg clk;
reg rst_n;

// Port A
reg                     en_a;
reg                     we_a;
reg [ADDR_WIDTH-1:0]    addr_a;
reg [DATA_WIDTH-1:0]    din_a;
wire [DATA_WIDTH-1:0]   dout_a;

// Port B
reg                     en_b;
reg                     we_b;
reg [ADDR_WIDTH-1:0]    addr_b;
reg [DATA_WIDTH-1:0]    din_b;
wire [DATA_WIDTH-1:0]   dout_b;

dual_port_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dut (
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

// Clock (10 ns period)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Reset
    rst_n  = 0;
    en_a   = 0;
    we_a   = 0;
    addr_a = 0;
    din_a  = 0;
    en_b   = 0;
    we_b   = 0;
    addr_b = 0;
    din_b  = 0;

    #20;
    rst_n = 1;

    // Port A Write
    #5;
    en_a   = 1;
    we_a   = 1;
    addr_a = 8'h10;
    din_a  = 32'h11111111;

    #10;
    we_a = 0;

    // Port B Write
    #10;
    en_a = 0;

    en_b   = 1;
    we_b   = 1;
    addr_b = 8'h20;
    din_b  = 32'h22222222;

    #10;
    we_b = 0;

    // Same Address Write
    #10;
    en_a   = 1;
    we_a   = 1;
    addr_a = 8'h30;
    din_a  = 32'hAAAAAAAA;

    en_b   = 1;
    we_b   = 1;
    addr_b = 8'h30;
    din_b  = 32'h55555555;

    #10;
    en_a = 0;
    we_a = 0;
    en_b = 0;
    we_b = 0;

    #20;
    $finish;

end

initial begin
    $monitor(
        "T=%0t | A:(en=%b we=%b addr=%h din=%h dout=%h) | B:(en=%b we=%b addr=%h din=%h dout=%h)",
        $time,
        en_a, we_a, addr_a, din_a, dout_a,
        en_b, we_b, addr_b, din_b, dout_b
    );
end

endmodule