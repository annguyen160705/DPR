module dual_port_ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter DEPTH      = (1 << ADDR_WIDTH)
)(
    input                       clk,
    input                       rst_n,
    
    input                       en_a,
    input                       we_a,
    input  [ADDR_WIDTH-1:0]     addr_a,
    input  [DATA_WIDTH-1:0]     din_a,
    output reg [DATA_WIDTH-1:0] dout_a,

    input                       en_b,
    input                       we_b,
    input  [ADDR_WIDTH-1:0]     addr_b,
    input  [DATA_WIDTH-1:0]     din_b,
    output reg [DATA_WIDTH-1:0] dout_b
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1]; 

    wire wr_a       = en_a && we_a; 
    wire wr_b       = en_b && we_b;
    wire rd_a       = en_a && !we_a;
    wire rd_b       = en_b && !we_b;
    wire addr_match = (addr_a == addr_b);
    wire conflict   = wr_a && wr_b && addr_match;  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            dout_b <= {DATA_WIDTH{1'b0}};
        end
        else begin

            if (conflict)
                mem[addr_a] <= din_a;      
            else begin
                if (wr_a) mem[addr_a] <= din_a;
                if (wr_b) mem[addr_b] <= din_b;
            end

            if (rd_a)
                dout_a <= (wr_b && addr_match) ? din_b : mem[addr_a];

            if (rd_b)
                dout_b <= (wr_a && addr_match) ? din_a : mem[addr_b];

        end
    end

endmodule