`timescale 1ns/10ps

module ELA(clk, rst, ready, in_data, data_rd, req, wen, addr, data_wr, done);

	input					clk;
	input					rst;
	input					ready;
	input			[7:0]	in_data;
	input			[7:0]	data_rd;

	output	reg				req;
	output	reg				wen;
	output	reg		[12:0]	addr;
	output	reg		[7:0]	data_wr;
	output	reg				done;


reg					[7:0]	S_buffer	[127:0];
reg					[7:0]	L_buffer	[2:0];
reg					[8:0]	result;

reg					[2:0]	control;
reg					[7:0]	timer_s;

wire				[8:0]	d11;
wire				[8:0]	d22;
wire				[8:0]	d33;
wire				[7:0]	d1;
wire				[7:0]	d2;
wire				[7:0]	d3;

assign 				d11 = (L_buffer[2] - S_buffer[0]);
assign				d22 = (L_buffer[1] - S_buffer[1]);
assign				d33 = (L_buffer[0] - S_buffer[2]);

assign 				d1 = d11[8] ? -d11[7:0] : d11[7:0];
assign				d2 = d22[8] ? -d22[7:0] : d22[7:0];
assign				d3 = d33[8] ? -d33[7:0] : d33[7:0];


reg					[1:0]	min;

reg         		[2:0]	state;
reg         		[2:0]	next_state;

parameter   		Rowf      	= 3'd0;
parameter   		comp      	= 3'd1;
parameter   		read       	= 3'd2;
parameter   		fish       	= 3'd3;
parameter   		stop        = 3'd4;

integer 			i;


always @(posedge clk or posedge rst)
begin
	if (rst)
	begin
		timer_s <= 8'd0;
	end

	else if ((control == 3'd0 && timer_s == 8'd130) || (control == 3'd1 && timer_s == 8'd131) ||(control == 3'd2 && timer_s == 8'd128) || control == 3'd4)
	begin
		timer_s <= 8'd0;
	end

	else
	begin
		timer_s <= timer_s + 8'd1;
	end
end

always @(posedge clk or posedge rst)
begin
	if (rst)
	begin
		req <= 1'd0;
	end

	else if (timer_s == 8'd0 && !(control == 3'd2) && !(control == 3'd4))
	begin
		req <= 1'd1;
	end

	else
	begin
		req <= 1'd0;
	end
end

always @(posedge clk or posedge rst)
begin
	if (rst)
	begin
	end

	else if ((control == 3'd0 && timer_s >= 8'd129) || (control == 3'd1 && timer_s == 8'd0) || (control == 3'd2 && timer_s == 8'd128))
	begin
	end

	else if (control == 3'd2)
	begin
		S_buffer[0] <= S_buffer[127];
		for(i=1; i<128; i=i+1)
		begin
			S_buffer[i] <= S_buffer[i-1];
		end
	end

	else if (timer_s <= 8'd128)
	begin
		S_buffer[0] <= in_data;
		for(i=1; i<128; i=i+1)
		begin
			S_buffer[i] <= S_buffer[i-1];
		end
	end
end

always @(posedge clk or posedge rst) 
begin
	if (rst) 
	begin
		L_buffer[0] <= 8'd0;
		L_buffer[2] <= 8'd0;
		L_buffer[1] <= 8'd0;
	end

	else if ((control == 3'd0 && timer_s >= 8'd129) || (control == 3'd1 && timer_s == 8'd0) || (control == 3'd2 && timer_s == 8'd128))
	begin
		L_buffer[0] <= L_buffer[0];
		L_buffer[2] <= L_buffer[2];
		L_buffer[1] <= L_buffer[1];
	end

	else if (control == 3'd2)
	begin
		L_buffer[0] <= L_buffer[2];
		L_buffer[2] <= L_buffer[1];
		L_buffer[1] <= L_buffer[0];
	end

	else if (timer_s <= 8'd128)
	begin
		L_buffer[0] <= S_buffer[127];
		L_buffer[2] <= L_buffer[1];
		L_buffer[1] <= L_buffer[0];
	end
end

always @(*)
begin
	if (timer_s == 8'd3)
	begin
		min = 2'd2;
	end

	else if ((d1 == d3) && (d2 == d3))
	begin
		min = 2'd0;
	end

	else if (d1 <= d3)
	begin
		if (d2 <= d1)
		begin
			min = 2'd2;
		end

		else 
		begin
			min = 2'd1;
		end
	end

	else 
	begin
		if (d2 <= d3)
		begin
			min = 2'd2;
		end

		else 
		begin
			min = 2'd3;
		end
	end
end

always @(posedge clk or posedge rst)
begin
	if (rst) 
	begin
		result <= 9'd0;
	end

	else if (control == 3'd1)
	begin
		if (timer_s == 8'd130)
		begin
			result <= ((S_buffer[0] + L_buffer[0]) >> 1);
		end

		else
		begin
			case(min)

			2'd0: result <= ((S_buffer[0] + (S_buffer[1] * 2) + S_buffer[2] + L_buffer[0] + (L_buffer[1] * 2) + L_buffer[2]) / 8);
			2'd1: result <= ((S_buffer[0] + L_buffer[2]) >> 1);
			2'd2: result <= ((S_buffer[1] + L_buffer[1]) >> 1);
			2'd3: result <= ((S_buffer[2] + L_buffer[0]) >> 1);

			// 2'd0: result <= 9'd0;
			// 2'd1: result <= ((S_buffer[0] + S_buffer[1] + S_buffer[2] + L_buffer[0] + L_buffer[1] + L_buffer[2]) / 6);
			// 2'd2: result <= ((S_buffer[1] + L_buffer[1]) >> 1);
			// 2'd3: result <= ((S_buffer[0] + S_buffer[1] + S_buffer[2] + L_buffer[0] + L_buffer[1] + L_buffer[2]) / 6);

			endcase
		end
	end
end

always @(posedge clk or posedge rst)
 begin
	if (rst) 
	begin
		wen <= 1'd0;
	end

	else if (control == 3'd3)
	begin
		wen <= 1'd0;
	end

	else
	begin
		wen <= 1'd1;
	end
end

always @(posedge clk or posedge rst) 
begin
	if (rst) 
	begin
		addr <= 13'd0;
	end

	else if((control == 3'd0 && timer_s <= 8'd2) || (control == 3'd1 && timer_s <= 8'd4) || control == 3'd4)
	begin
		addr <= addr;
	end

	else 
	begin
		addr <= addr + 13'd1;	
	end
end

always @(posedge clk or posedge rst) 
begin
	if (rst) 
	begin
		data_wr <= 8'd0;
	end

	else if (control == 3'd0)
	begin
		data_wr <= S_buffer[0];
	end

	else if (control == 3'd1)
	begin
		data_wr <= result;
	end

	else
	begin
		data_wr <= S_buffer[127];
	end
end

always @(posedge clk or posedge rst) 
begin
	if (rst) 
	begin
		done <= 1'd0;
	end

	else if (control == 3'd3) 
	begin
		done <= 1'd1;
	end
end

// state register
always @(posedge clk or posedge rst)
begin
    if (rst)	state <= stop;

    else 		state <= next_state;
end

// next state logic
always @(*) 
begin
    case(state)

    	stop:
    	begin
    		if(ready == 1'b0) next_state = stop;
    		else              next_state = Rowf;
    	end

    	Rowf :
    	begin
    		if(timer_s == 8'd130) next_state = comp;
    		else                 next_state = Rowf;
    	end
    	comp :
    	begin
    		if(timer_s == 8'd131) next_state = read;
    		else                 next_state = comp;
    	end
    	read :
    	begin
    		if(addr == 13'd8062)      next_state = fish;
    		else if(timer_s == 8'd128)next_state = comp;
    		else                     next_state = read;
    	end
    	fish : next_state = fish;

    endcase
end

// output logic
always @(*) 
begin
    case(state)

    	Rowf : control = 3'd0;
    	comp : control = 3'd1;
    	read : control = 3'd2;
    	fish : control = 3'd3;
    	stop : control = 3'd4;

    endcase
end

endmodule