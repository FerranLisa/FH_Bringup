`timescale 1ns/1ps
module gmax3412_emulator #(
    parameter integer IMAGE_WIDTH=4096, IMAGE_HEIGHT=3072, LANES=16
)(
    (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 s_axi_aclk CLK", X_INTERFACE_PARAMETER="ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 120000000" *)
    input wire s_axi_aclk,
    (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 s_axi_aresetn RST", X_INTERFACE_PARAMETER="POLARITY ACTIVE_LOW" *)
    input wire s_axi_aresetn,
    input wire [7:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid, output wire s_axi_awready,
    input wire [31:0] s_axi_wdata, input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid, output wire s_axi_wready,
    output reg [1:0] s_axi_bresp, output reg s_axi_bvalid,
    input wire s_axi_bready,
    input wire [7:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid, output wire s_axi_arready,
    output reg [31:0] s_axi_rdata, output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid, input wire s_axi_rready,
    // Native commands: synchronous rising edges in the 120 MHz domain.
    input wire init_in, acquisition_start, acquisition_stop, trigger_in, readout_in,
    (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk_rxg CLK", X_INTERFACE_PARAMETER="FREQ_HZ 120000000" *)
    output wire clk_rxg,
    (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 rst_rxg RST", X_INTERFACE_PARAMETER="POLARITY ACTIVE_HIGH" *)
    output wire rst_rxg,
    output wire fvalout, lvalout, output wire [12*LANES-1:0] dataout,
    output wire initialized, armed, busy, cmos_texp1, cmos_texp2, flash_out
);
    wire seq_enabled,seq_armed,seq_exposing,seq_flash,seq_busy,seq_pending,seq_fval,seq_lval,seq_roi,seq_pass;
    wire [12*LANES-1:0] seq_data,legacy_data;
    wire [9:0] seq_seed,legacy_seed;
    wire [7:0] seq_analog;wire [15:0] seq_digital;
    wire [31:0] seq_accepted,seq_rejected,seq_skipped,seq_fault,seq_frames,seq_errors,seq_pixels,seq_lines,seq_sum,seq_rdata;
    wire legacy_armed,legacy_busy,legacy_exposing,legacy_fval,legacy_lval,legacy_pass;
    wire [31:0] legacy_accepted,legacy_rejected,legacy_frames,legacy_errors,legacy_pixels,legacy_lines,legacy_sum;
    wire seq_write_ok;
    reg readout_prev;
    reg aw_pending, w_pending;
    reg [7:0] awaddr;
    wire seq_bus_write_ok=seq_write_ok && !(awaddr==8'h70 && busy);
    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg [31:0] exposure, blanking, seed_reg;
    reg roi_mode;
    reg checked_roi;
    always @(posedge s_axi_aclk)
        if(!s_axi_aresetn) checked_roi<=0;
        else if(!busy) checked_roi<=roi_mode;
    reg [3:0] commands, native_prev;
    wire [3:0] native_now={trigger_in,acquisition_stop,acquisition_start,init_in};
    wire [3:0] cmd=commands | (native_now & ~native_prev);
    wire [31:0] accepted,rejected,frames,errors,pixels,lines,checksum;
    wire pass;
    wire [31:0] tm_seq,tm_exp,tm_lmin,tm_lmax,tm_bmin,tm_bmax,tm_frame,tm_lines;
    gmax3412_timing timing_monitor(.clk(s_axi_aclk),.resetn(s_axi_aresetn),
        .exposing(cmos_texp1),.fval(fvalout),.lval(lvalout),
        .sequence_number(tm_seq),.exposure_cycles(tm_exp),.line_min(tm_lmin),.line_max(tm_lmax),
        .blank_min(tm_bmin),.blank_max(tm_bmax),.frame_cycles(tm_frame),.line_count(tm_lines));
    wire [9:0] active_seed;
    assign clk_rxg=s_axi_aclk;
    assign rst_rxg=~s_axi_aresetn;
    assign cmos_texp2=1'b0;
    assign armed=seq_enabled?seq_armed:legacy_armed;
    assign busy=seq_enabled?(seq_busy|seq_exposing|seq_pending):legacy_busy;
    assign cmos_texp1=seq_enabled?seq_exposing:legacy_exposing;
    assign flash_out=seq_enabled && seq_flash;
    assign fvalout=seq_enabled?seq_fval:legacy_fval;
    assign lvalout=seq_enabled?seq_lval:legacy_lval;
    assign dataout=seq_enabled?seq_data:legacy_data;
    assign active_seed=seq_enabled?seq_seed:legacy_seed;
    assign accepted=seq_enabled?seq_accepted:legacy_accepted;
    assign rejected=seq_enabled?seq_rejected:legacy_rejected;
    assign frames=seq_enabled?seq_frames:legacy_frames;
    assign errors=seq_enabled?seq_errors:legacy_errors;
    assign pixels=seq_enabled?seq_pixels:legacy_pixels;
    assign lines=seq_enabled?seq_lines:legacy_lines;
    assign checksum=seq_enabled?seq_sum:legacy_sum;
    assign pass=seq_enabled?seq_pass:legacy_pass;
    always @(posedge s_axi_aclk) if(!s_axi_aresetn) readout_prev<=0;else readout_prev<=readout_in;
    gmax3412_sequence #(.WIDTH(IMAGE_WIDTH),.HEIGHT(IMAGE_HEIGHT),.LANES(LANES)) sequence_controller(
      .clk(s_axi_aclk),.resetn(s_axi_aresetn),.init_cmd(cmd[0]),.start_cmd(cmd[1]),.stop_cmd(cmd[2]),
      .trigger_cmd(cmd[3]),.readout_cmd(readout_in && !readout_prev),
      .wr(aw_pending && w_pending && !s_axi_bvalid && &wstrb && seq_bus_write_ok && awaddr>=8'h70 && awaddr<=8'h9c),
      .addr(awaddr),.raddr(s_axi_araddr),.wdata(wdata),.rdata(seq_rdata),.write_ok(seq_write_ok),
      .blank_cycles(blanking),.enabled(seq_enabled),.armed(seq_armed),.exposing(seq_exposing),.flash(seq_flash),
      .read_busy(seq_busy),.pending(seq_pending),.fval(seq_fval),.lval(seq_lval),.pixels(seq_data),
      .active_seed(seq_seed),.active_roi(seq_roi),.analog_gain(seq_analog),.digital_gain(seq_digital),
      .accepted(seq_accepted),.rejected(seq_rejected),.skipped(seq_skipped),.fault(seq_fault),
      .checked(seq_frames),.check_errors(seq_errors),.last_pixels(seq_pixels),.last_lines(seq_lines),
      .checksum(seq_sum),.last_pass(seq_pass));
    assign s_axi_awready=!aw_pending && !s_axi_bvalid;
    assign s_axi_wready=!w_pending && !s_axi_bvalid;
    assign s_axi_arready=!s_axi_rvalid;
    integer b;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            aw_pending<=0; w_pending<=0; awaddr<=0; wdata<=0; wstrb<=0;
            s_axi_bresp<=0; s_axi_bvalid<=0; s_axi_rdata<=0;
            s_axi_rresp<=0; s_axi_rvalid<=0;
            exposure<=120000; blanking<=16; seed_reg<=0; roi_mode<=0;
            commands<=0; native_prev<=0;
        end else begin
            commands<=0; native_prev<=native_now;
            if (s_axi_awvalid && s_axi_awready) begin
                aw_pending<=1; awaddr<=s_axi_awaddr;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_pending<=1; wdata<=s_axi_wdata; wstrb<=s_axi_wstrb;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid<=0;
            if (aw_pending && w_pending && !s_axi_bvalid) begin
                aw_pending<=0; w_pending<=0; s_axi_bvalid<=1; s_axi_bresp<=0;
                case (awaddr)
                    8'h64: if(wstrb[0]) roi_mode<=wdata[0];
                    8'h04: if (wstrb[0]) commands<=wdata[3:0];
                    8'h0c: for(b=0;b<4;b=b+1) if(wstrb[b]) exposure[b*8 +: 8]<=wdata[b*8 +: 8];
                    8'h10: for(b=0;b<4;b=b+1) if(wstrb[b]) blanking[b*8 +: 8]<=wdata[b*8 +: 8];
                    8'h14: for(b=0;b<4;b=b+1) if(wstrb[b]) seed_reg[b*8 +: 8]<=wdata[b*8 +: 8];
                    default: if(!(awaddr>=8'h70 && awaddr<=8'h9c && (&wstrb) && seq_bus_write_ok)) s_axi_bresp<=2'b10;
                endcase
            end
            if(s_axi_rvalid && s_axi_rready) s_axi_rvalid<=0;
            if(s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid<=1; s_axi_rresp<=0;
                case(s_axi_araddr)
                    8'h00: s_axi_rdata<=32'h34120025;
                    8'h04: s_axi_rdata<=0;
                    8'h08: s_axi_rdata<={27'b0,pass,cmos_texp1,busy,armed,initialized};
                    8'h0c: s_axi_rdata<=exposure;
                    8'h10: s_axi_rdata<=blanking;
                    8'h14: s_axi_rdata<=seed_reg;
                    8'h18: s_axi_rdata<=IMAGE_WIDTH;
                    8'h1c: s_axi_rdata<=IMAGE_HEIGHT;
                    8'h20: s_axi_rdata<=accepted;
                    8'h24: s_axi_rdata<=rejected;
                    8'h28: s_axi_rdata<=frames;
                    8'h2c: s_axi_rdata<=errors;
                    8'h30: s_axi_rdata<=pixels;
                    8'h34: s_axi_rdata<=lines;
                    8'h38: s_axi_rdata<=checksum;
                    8'h3c: s_axi_rdata<=120000000;
                    8'h40: s_axi_rdata<=32'h544d0001;
                    8'h44: s_axi_rdata<=tm_seq;
                    8'h48: s_axi_rdata<=tm_exp;
                    8'h4c: s_axi_rdata<=tm_lmin;
                    8'h50: s_axi_rdata<=tm_lmax;
                    8'h54: s_axi_rdata<=tm_bmin;
                    8'h58: s_axi_rdata<=tm_bmax;
                    8'h5c: s_axi_rdata<=tm_frame;
                    8'h60: s_axi_rdata<=tm_lines;
                    8'h64: s_axi_rdata<={31'b0,roi_mode};
                    8'h68: s_axi_rdata<=32'h44530030;
                    default: if(s_axi_araddr>=8'h70 && s_axi_araddr<=8'hb8) s_axi_rdata<=seq_rdata; else begin s_axi_rdata<=0; s_axi_rresp<=2'b10; end
                endcase
            end
        end
    end
    gmax3412_pattern #(.WIDTH(IMAGE_WIDTH),.HEIGHT(IMAGE_HEIGHT),.DYNAMIC_ROI(1),.LANES(LANES)) source (
        .clk(s_axi_aclk),.resetn(s_axi_aresetn),
        .init_cmd(cmd[0]),.start_cmd(cmd[1] && !seq_enabled),.stop_cmd(cmd[2]),.trigger_cmd(cmd[3] && !seq_enabled),
        .roi_mode(roi_mode),.exposure_cycles(exposure),.blank_cycles(blanking),.seed(seed_reg[9:0]),
        .initialized(initialized),.armed(legacy_armed),.busy(legacy_busy),.exposing(legacy_exposing),
        .fval(legacy_fval),.lval(legacy_lval),.data(legacy_data),.active_seed(legacy_seed),
        .accepted(legacy_accepted),.rejected(legacy_rejected));
    gmax3412_checker #(.WIDTH(IMAGE_WIDTH),.HEIGHT(IMAGE_HEIGHT),.DYNAMIC_ROI(1),.LANES(LANES)) checker_inst (
        .clk(s_axi_aclk),.resetn(s_axi_aresetn),.fval(legacy_fval),.lval(legacy_lval),
        .data(legacy_data),.roi_mode(checked_roi),.seed(legacy_seed),.frames(legacy_frames),.errors(legacy_errors),
        .last_pixels(legacy_pixels),.last_lines(legacy_lines),.checksum(legacy_sum),.last_pass(legacy_pass));
endmodule
