module FSM (clk,rst_n,a,b,Y1, Y0);
    //state assignment
    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;


    //signals 
    input clk, rst_n , a, b ;
    output reg  Y1, Y0;

    reg [1:0] cs , ns;

    // state register 
    always @ (posedge clk, negedge rst_n) begin 
        if (!rst_n)
            cs <= S0;
        else 
            cs <= ns;
    end  




    //next state logic
    always @ (*) begin 
        ns = S0;
        case (cs) 

            S0: begin 
                if (!a)
                    ns = S0;
                else if (a&&b)
                    ns = S2;
                else 
                    ns = S1;
            end
            

            S1: begin 
                if (a)
                    ns = S0;
                else 
                    ns = S1;
            end 

            S2 : begin 
                ns = S0;
            end 

            default : begin
                ns = S0;
            end
        endcase 
    end 







    // output logic 
    // assign Y1 = ((cs == S0) || (cs == S1));
    // assign Y0 = ((cs == S0) && (a&&b));

    //output logic always block 
    always @ (*) begin 
        if ((cs == S0) || (cs == S1))
            Y1 = 1;
        else 
            Y1 = 0;
        
        if ((cs == S0) && (a&&b))
            Y0 = 1;
        else 
            Y0 = 0;
    end 



endmodule 



   