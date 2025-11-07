
// Guidelines for the communiction between the Microcontroller and HCP unit (Drivers) : 
// 1. Before starting the communiction
//      * set the En_raising / En_falling. 
//      * puts the 1st bit of the data on the data_pin_r / data_pin_f of HCP unit.
//      * then generate the clk
// 2. during the communication
//      * puts the data bit on the data_pin_r / data_pin_f of HCP unit after receiving the Sr and Sf signal.
// 3. Before ending the communiction.
//      * sends the last bit 
//      * after sending ask for ACK during that time it sets En_raising / En_falling to 0 
//      * after receving the Sr/Sf signal set the data_pin_r / data_pin_f to zero.
//      * generate 16 clk pulse.

//////////////////////////////////////////////////////////////////////////////////
// Pending Work:
//   it should ask for the Acknowlagement 

//////////////////////////////////////////////////////////////////////////////////

module master(     
    input clk, data_pin_r, data_pin_f, En_raising, En_falling, 
    inout wire sbda, 
    //output reg [3:0] P_bits_count, P_Byte, N_bits_count, N_Byte,
    output reg Sr,Sf  
);      
    reg [7:0] data1, data2;       
    reg R,F,RS,FS,sbda_out;           
    reg sbda_enable,P_ACK, N_ACK;   
    reg [3:0] P_bits_count,N_bits_count, P_Byte, N_Byte;
    parameter Start_frame = 8'b01111110;
    parameter Stop_frame = 8'b11111110; //01111111
    
    initial begin
        P_Byte <= 0;
        N_Byte <= 0;
        sbda_out<=0;
        sbda_enable<=0;
        N_ACK <=0;
        P_ACK <=0;
        R<=0;
        F<=0;
        RS<=0;
        FS<=0;
        P_bits_count<=0;
        N_bits_count<=0;
        Sr<=1;
        Sf<=1;
    end 
       
     // Control the direction of the inout port 
     assign sbda = sbda_enable ? sbda_out : 1'bz; //sending data or setting SBDA line as Floating
   
    // raising channel
    //1
    always @(posedge En_raising) begin // starting the communication by loading the Start frame 
        data1 <= Start_frame;
        R <= 1; 
        RS <= 0;
    end 
    
    //2
    always @(negedge En_raising) begin // about to end the communication
        RS = 1; 
        P_Byte = 5;
    end
    
    //3
    always @(posedge clk) begin //setting SBDA line as high impedance, to avoid conflicts with negedge's data ,
        sbda_enable <= 0;
    end
    
    //4
    always @( negedge clk) begin
        if(R == 1 && RS == 0 )begin // Signaling the controller for the next data bit of the raising edge channel
            Sr = 0;
            #2 Sr = 1;
        end
    end
    //5
    always @(posedge clk) begin // main process
        if (R) begin
            sbda_out <=  data1[0]; // storing LSB in the variable. [data bit that need to be send] 
            // shifting the data register to Right and stuffing new data bit from control unit into the MSB 
            // stuffing 0 after every 4 consecutives of 1 in a new data bits [Bit stuffing]
            data1 = (P_Byte == 5 && P_bits_count == 7)? Stop_frame: ((P_ACK == 0)? {data_pin_r, data1[7:1]}:data1);
            //N_ACK = (N_ACK == 2)? 1:((N_ACK == 1)? 0:0);  
            P_bits_count = P_bits_count + 1'b1;
            if(P_bits_count == 8)begin //after each Byte of data
                P_bits_count = 0;
                P_Byte = P_Byte + 1;
                 if(P_Byte == 5) begin
                    P_Byte <= 3;
                 end
                 else if(P_Byte == 2) begin
                    //N_ACK = 2;
                 end
                 else if(P_Byte > 2)begin
                    //N_ACK = 1;
                 end
            end 
            if(P_Byte == 7 && P_bits_count == 0)begin 
                    R <= 0;
                    RS <= 0;
            end
        end
    end 
    
    // 8
    always @(posedge clk ) begin
        if (R) begin      
            sbda_enable <= 1; // taking control over SBDA Line and sending the bit. 
        end
    end
    
    // falling channel
    //1
    always @(posedge En_falling) begin // starting the communication by loading the Start frame
        data2 <= Start_frame; 
        F <= 1;
        FS <= 0;
    end 
    
    //2
    always @(negedge En_falling) begin // about to end the communication
        FS = 1;
        N_Byte = 5;
    end 
    
    //3
    always @( negedge clk) begin //setting SBDA line as high impedance, to avoid conflicts with negedge's data
        sbda_enable = 0; 
    end
    
    //4
     always @(posedge clk) begin // Signaling the controller for the next data bit of the falling edge channel
        if(F == 1 && FS == 0)begin 
            Sf = 0;
            #2 Sf = 1;
        end
    end
    
    //5
    always @(negedge clk) begin // main process
        if (F) begin
            sbda_out <=  data2[0]; // storing LSB in the variable. [data bit that need to be send] 
            // shifting the data register to Right and stuffing new data bit from control unit into the MSB 
            // stuffing 0 after every 4 consecutives of 1 in a new data bits [Bit stuffing]
            data2 = (N_Byte == 5 && N_bits_count == 7)? Stop_frame: ((N_ACK == 0)? {data_pin_f, data2[7:1]}:data2);
            //N_ACK = (N_ACK == 2)? 1:((N_ACK == 1)? 0:0);  
            N_bits_count = N_bits_count + 1'b1;
            if(N_bits_count == 8)begin //after each Byte of data
                N_bits_count = 0;
                N_Byte = N_Byte + 1;
                 if(N_Byte == 5) begin
                    N_Byte <= 3;
                 end
                 else if(N_Byte == 2) begin
                    //N_ACK = 2;
                 end
                 else if(N_Byte > 2)begin
                    //N_ACK = 1;
                 end
            end 
            if(N_Byte == 7 && N_bits_count == 0)begin 
                    F <= 0;
                    FS <= 0;
            end
        end
    end
    //6
    always @(negedge clk) begin // taking control over SBDA Line and sending the bit.
        if (F) begin      
            sbda_enable <= 1; 
        end
    end

endmodule
