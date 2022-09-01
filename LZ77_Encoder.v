module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);

input 				clk;
input 				reset;
input 		[7:0] 	chardata;
output  			valid;
output  			encode;
output  			finish;
output  	[4:0] 	offset;
output  	[4:0] 	match_len;
output  	[7:0] 	char_nxt;


reg  					valid;
reg  					encode;
reg  					finish;
reg 		[4:0] 		offset;
reg 		[4:0] 		match_len;
reg 	 	[7:0] 		char_nxt;

reg			[3:0]		Total 	[8192:0];
reg			[3:0]		B		[54:0];
reg			[13:0]		timer;
reg			[23:0]		compare;


reg         [2:0]		state;
reg         [2:0]		next_state;

parameter   memory	 	= 3'd0;
parameter   shift      	= 3'd1;
parameter   enc      	= 3'd2;
parameter   val       	= 3'd3;
parameter   fin       	= 3'd4;

reg			[4:0]		i;
reg			[4:0]		max_L;
reg			[4:0]		max_L_C;
reg			[4:0]		step_C;
reg			[4:0]		step_E;
reg			[4:0]		I_step;
reg						money;

integer 	j;

wire 		[4:0]		i_modified;
assign i_modified = (i>8217-timer) ? 8217-timer : i;


// Timer
always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		timer <= 14'd0;
	end

	else
	begin

		case(state)

			memory:
			begin
				if(timer == 14'd8192)
				begin
					timer <= 14'd0;						
				end

				else 
				begin
					timer <= timer + 14'd1;					
				end
		
			end

			shift:
			begin
				timer <= timer + 14'd1;			
			end

			default:
			begin
				timer <= timer;
			end
		endcase

	end
end

// Shifter
always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		step_C <= 5'd0;
		step_E <= 5'd0;
		max_L <= 5'd24;
		for(j=0; j<8193;j=j+1)
		begin
			Total[j] <= 4'd0;
		end
		// for(j=0; j<56;j=j+1)
		// begin
		// 	B[j] <= 4'd3;
		// end
	end

	else
	begin

		case(state)
			memory:
			begin
				Total[8192] <= chardata[3:0];
				for(j=0; j<8192;j=j+1)
				begin
					Total[j] <= Total[j+1];
				end
			end 

			shift:
			begin
				if (step_C <= max_L)
				begin
					B[54] <= Total[0];
					for(j=0; j<8192;j=j+1)
					begin
						Total[j] <= Total[j+1];
					end
					for(j=0; j<54; j=j+1)
					begin
						B[j] <= B[j+1];			
					end
					step_C <= step_C + 5'd1;
				end

				else
				begin
					step_C <= 5'd0;
				end

			end

			enc:
			begin
				if(step_E < 5'd29)
				begin
					step_E <= step_E + 5'd1;
				end

				else
				begin
					step_E <= 5'd0;
				end

			end

			val:
			begin
				step_C <= 5'd0;
				max_L <= max_L_C;
			end

		endcase

	end
end

always @(*)
begin
	case(state)

		enc:
		begin
			if(step_E < 5'd30)
			begin
				for(j=0; j<24; j=j+1)
				begin
					compare[j] = |(B[30+j] ^ B[(29-step_E)+j]);
				end

				casez(compare)
					24'b000000000000000000000000: i = 5'd24;
					24'b?00000000000000000000000: i = 5'd23;
					24'b??0000000000000000000000: i = 5'd22;
					24'b???000000000000000000000: i = 5'd21;
					24'b????00000000000000000000: i = 5'd20;
					24'b?????0000000000000000000: i = 5'd19;
					24'b??????000000000000000000: i = 5'd18;
					24'b???????00000000000000000: i = 5'd17;
					24'b????????0000000000000000: i = 5'd16;
					24'b?????????000000000000000: i = 5'd15;
					24'b??????????00000000000000: i = 5'd14;
					24'b???????????0000000000000: i = 5'd13;
					24'b????????????000000000000: i = 5'd12;
					24'b?????????????00000000000: i = 5'd11;
					24'b??????????????0000000000: i = 5'd10;
					24'b???????????????000000000: i = 5'd9;
					24'b????????????????00000000: i = 5'd8;
					24'b?????????????????0000000: i = 5'd7;
					24'b??????????????????000000: i = 5'd6;
					24'b???????????????????00000: i = 5'd5;
					24'b????????????????????0000: i = 5'd4;
					24'b?????????????????????000: i = 5'd3;
					24'b??????????????????????00: i = 5'd2;
					24'b???????????????????????0: i = 5'd1;
					default: 				 	  i = 5'd0;
				endcase

			end

			else
			begin
				compare = 25'd0;
				i = 5'd0;
			end
		end

		default:
		begin
			compare = 25'd0;
			i = 5'd0;
		end
	endcase
end

always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		max_L_C <= 5'd0;
		I_step <= 5'd0;
	end

	else
	begin

		case(state)
			enc:
			begin
				if(i_modified>=max_L_C && i_modified!=5'b0)
				begin
					max_L_C <= i_modified;
					I_step <= step_E;
				end

				else 
				begin
					max_L_C <= max_L_C;
					I_step <= I_step;
				end
			end

			val:
			begin
				I_step <= 5'd0;
				max_L_C <= 5'd0;
			end
		endcase

	end

end

// for money
always @(posedge clk or posedge reset) 
begin
	if (reset)
	begin
		money <= 1'b0;
	end

	else if (timer+max_L_C == 14'd8217)
	begin
		money <= 1'b1;
	end
end


// valider
always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		valid <= 1'b0;
		offset <= 5'b0;
		match_len <= 5'b0;
		char_nxt <= 8'b0;
	end

	else
	begin
		case(state)

			shift:
			begin
				valid <= 1'b0;
				offset <= 5'b0;
				match_len <= 5'b0;
				char_nxt <= 8'b0;
			end

			enc:
			begin
				valid <= 1'b0;
				offset <= 5'b0;
				match_len <= 5'b0;
				char_nxt <= 8'b0;
			end

			val:
			begin
				valid <= 1'b1;
				offset <= I_step;
				match_len <= max_L_C;

				if(money)
				begin
					char_nxt <= 8'h24;					
				end

				else
				begin
					char_nxt <= B[30+max_L_C];			
				end
				
			end

			fin:
			begin
				valid <= 1'b0;
				offset <= 5'b0;
				match_len <= 5'b0;
				char_nxt <= 8'b0;
			end

		endcase
	end
end

// state register
always @(posedge clk or posedge reset)
begin
    if (reset)	state <= memory;

    else 		state <= next_state;
end

// next state logic
always @(*) 
begin
    case(state)

        memory : 
        begin
        	if (chardata ^ 8'h24) next_state = memory;
        	else 				  next_state = shift;
        end	


        shift : 
        begin
        	if (char_nxt == 8'h24)      next_state = fin;
        	else if (step_C == max_L)   next_state = enc;
        	else 				   		next_state = shift;
        end	

        enc :
        begin
        	if (step_E < 5'd29)    next_state = enc;
        	else 				  next_state = val;
        end

        val : next_state = shift;

        fin : next_state = fin;

        default : next_state = shift;

    endcase
end

// output logic
always @(*) 
begin
    case(state)

        memory :
	        begin	   
	        	encode = 1'b0;
				finish = 1'b0;
	        end

        shift :
	        begin	   
	        	encode = 1'b1;
				finish = 1'b0;
	        end

        enc :
	        begin
				encode = 1'b1;
				finish = 1'b0;
	        end

        val :
	        begin	   
	        	encode = 1'b1;
				finish = 1'b0;
	        end

        fin :
	        begin	   
	        	encode = 1'b0;
				finish = 1'b1;
	        end

        default :
            begin
				encode = 1'b1;
				finish = 1'b0;
            end

    endcase
end

endmodule