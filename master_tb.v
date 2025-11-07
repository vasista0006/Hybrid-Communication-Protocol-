
module master_tb();
reg clk, data_pin_r, data_pin_f,En_raising,En_falling;
tri sbda;
wire Sr,Sf;  
master test( clk, data_pin_r, data_pin_f,En_raising,En_falling,sbda,Sr,Sf);

 // Debug
//module master_tb();
//reg clk, data_pin_r, data_pin_f,En_raising,En_falling;
//tri sbda;
//wire [3:0] P_bits_count, P_Byte, N_bits_count, N_Byte;
//wire Sr,Sf;  

//master test( clk, data_pin_r, data_pin_f,En_raising,En_falling,sbda,P_bits_count, P_Byte, N_bits_count, N_Byte,Sr,Sf);
    initial begin
        clk = 0;
        En_raising = 1'b0;
        En_falling = 1'b0;
        data_pin_r = 1'b0;
        data_pin_f = 1'b0;
        forever #10 clk = ~clk; // 10ns period clock
    end
    
    initial begin // sending the data on pose edge
        #15       
        En_raising = 1'b1;
        send_byte_P(8'b11001100);
        send_byte_P(8'b11001100);
        wait (Sr == 0);
        data_pin_r = 1'b0;
        En_raising = 1'b0;
    end

    initial begin // sending the data on neg edge
        #25       
        En_falling = 1'b1;
        send_byte_N(8'b11001100);
        send_byte_N(8'b11001100);
        send_byte_N(8'b11001100);
        wait (Sf == 0);
        data_pin_f = 1'b0;
        En_falling = 1'b0;
    end
    
    task send_byte_P_1st;
    input [7:0] byte;
    integer i;
    begin
        data_pin_r = byte[0];
        for (i = 1; i < 8; i = i + 1) begin
            wait (Sr == 0);
            #1; // Small delay to align with Sr neg edge
            data_pin_r = byte[i];
            wait (Sr == 1);
        end
    end
    endtask
    task send_byte_P;
    input [7:0] byte;
    integer i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            wait (Sr == 0);
            #1; // Small delay to align with Sr neg edge
            data_pin_r = byte[i];
            wait (Sr == 1);
        end
    end
    endtask
    
    task send_byte_N_1st;
    input [7:0] byte;
    integer j;
    begin
        data_pin_f = byte[0];
        for (j = 1; j < 8; j = j + 1) begin
            wait (Sf == 0);
            #1; // Small delay to align with Sr neg edge
            data_pin_f = byte[j];
            wait (Sf == 1);
        end
    end
    endtask
    task send_byte_N;
    input [7:0] byte;
    integer j;
    begin
        for (j = 0; j < 8; j = j + 1) begin
            wait (Sf == 0);
            #1; // Small delay to align with Sr neg edge
            data_pin_f = byte[j];
            wait (Sf == 1);
        end
    end
    endtask
endmodule
