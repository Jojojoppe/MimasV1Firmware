.SILENT:

TARGET_FAMILY					:= spartan6
TARGET_DEVICE					:= xc6slx9
TARGET_PACKAGE					:= tqg144
TARGET_SPEEDGRADE				:= -2

IP_DIR							:= IP
IP_SOURCES						:= 
#$(IP_DIR)/blk_mem.xco

OUT_DIR							:= OUT

# -------------
# SYNTH targets
# -------------

SYN_TOTAL_VHDL_SOURCES			:= RTL/input_sync.vhd RTL/HF_interface.vhd RTL/toplevel.vhd
SYN_TOTAL_VERILOG_SOURCES		:=
SYN_TOTAL_IPS					:=
SYN_TOTAL_CONSTRAINTS			:= CONSTRAINTS/toplevel.ucf
SYN_TOTAL_TOPLEVEL				:= toplevel
SYN_TOTAL_XST_OPTIONS			:= -glob_opt max_delay -opt_mode speed
SYN_TOTAL_NETGEN_OPTIONS		:= -ism
SYN_TOTAL_NGD_OPTIONS			:=
SYN_TOTAL_MAP_OPTIONS			:= -ol high -xe n
SYN_TOTAL_PAR_OPTIONS			:= -ol high -xe n
SYN_TOTAL_BITGEN_OPTIONS		:= 
SYN_TOTAL_TRCE_OPTIONS			:= -v 3 -s 2 -n 3 -fastpaths

# -------------

# ------------------
# SIMULATION targets
# ------------------

SIM_PRESIM_VHDL_SOURCES			:= RTL/input_sync.vhd RTL/HF_interface.vhd RTL/toplevel.vhd SIM/tb_toplevel.vhd
SIM_PRESIM_VERILOG_SOURCES		:= 
SIM_PRESIM_IPS					:=
SIM_PRESIM_OTHER_SOURCES		:= 
SIM_PRESIM_TOPLEVEL				:= tb_toplevel
SIM_PRESIM_RUNTIME				:= all
SIM_PRESIM_LEVELS				:= 10

SIM_POSTSIM_VHDL_SOURCES		:=
SIM_POSTSIM_VHDL_SOURCES		:= SIM/tb_toplevel.vhd
SIM_POSTSIM_VERILOG_SOURCES		:= OUT/total/total.map.v
SIM_POSTSIM_IPS					:=
SIM_POSTSIM_OTHER_SOURCES		:= OUT/total/total.map.sdf
SIM_POSTSIM_TOPLEVEL			:= tb_toplevel
SIM_POSTSIM_RUNTIME				:= all
SIM_POSTSIM_LEVELS				:= 10

# ---------------------------
# Remote compile server stuff
# ---------------------------
REMOTEFILES_TO					:= Makefile remote_makefile 
REMOTEFILES_TO_IP				:= $(IP_SOURCES) 
REMOTEFILES_TO_SYN_TOTAL		:= $(SYN_TOTAL_CONSTRAINTS) $(SYN_TOTAL_VHDL_SOURCES) $(SYN_TOTAL_VERILOG_SOURCES)
REMOTEFILES_TO_SIM_PRESIM		:= $(SIM_PRESIM_VHDL_SOURCES) $(SIM_PRESIM_VERILOG_SOURCES) $(SIM_PRESIM_IPS) $(SIM_PRESIM_OTHER_SOURCES)
REMOTEFILES_TO_SIM_POSTSIM		:= $(SIM_POSTSIM_VHDL_SOURCES) $(SIM_POSTSIM_VERILOG_SOURCES) $(SIM_POSTSIM_IPS) $(SIM_POSTSIM_OTHER_SOURCES)

REMOTEACTIONS					:= ip syn_total impl_total out_total sim_presim sim_postsim
REMOTE_HOST						:= 84.245.11.17
REMOTE_PORT						:= 40022
REMOTE_USER						:= remotecompile
REMOTE_DIR						:= ~/HW-FW-connection
# ---------------------------

ifneq ($(REMOTECOMPILE), TRUE)
# -------------
# Local targets
# -------------

all: ip syn_total impl_total out_total

$(IP_SOURCES:%.xco=%.vhd): $(IP_SOURCES)
	$(call getfile,$@,$@)
ip : $(REMOTEFILES_TO_IP:%=.remote/%.remote) ip.remote $(IP_SOURCES:%.xco=%.vhd)

syn_total: $(REMOTEFILES_TO_SYN_TOTAL:%=.remote/%.remote) syn_total.remote
	-mkdir -p $(OUT_DIR)/total
	$(call getfile,total.v,$(OUT_DIR)/total/netlist.v)
	$(call getfile,total.srp,$(OUT_DIR)/total/synth.log)

impl_total: impl_total.remote
	-mkdir -p $(OUT_DIR)/total
	$(call getfile,total.map.v,$(OUT_DIR)/total/total.map.v)
	$(call getfile,total.map.sdf,$(OUT_DIR)/total/total.map.sdf)
	$(call getfile,total.par.log,$(OUT_DIR)/total/par.log)
	$(call getfile,total.map.mrp,$(OUT_DIR)/total/map.log)

out_total: out_total.remote
	-mkdir -p $(OUT_DIR)/total
	$(call getfile,total.bin,$(OUT_DIR)/total/out.bin)
	$(call getfile,total.bit,$(OUT_DIR)/total/out.bit)
	$(call getfile,total.twr,$(OUT_DIR)/total/timing.log)

presim: $(REMOTEFILES_TO_SIM_PRESIM:%=.remote/%.remote) sim_presim.remote
	-mkdir -p $(OUT_DIR)/presim
	$(call getfile,presim.vcd,$(OUT_DIR)/presim/out.vcd)

postsim: $(REMOTEFILES_TO_SIM_POSTSIM:%=.remote/%.remote) sim_postsim.remote
	-mkdir -p $(OUT_DIR)/postsim
	$(call getfile,postsim.vcd,$(OUT_DIR)/postsim/out.vcd)

clean: remove.remote
	-rm -rf $(OUT_DIR)
	-rm $(IP_DIR)/*.vhd

else
# --------------
# Remote targetmaps
# --------------

$(IP_SOURCES:%.xco=%.vhd): $(IP_SOURCES)
	echo "SET busformat = BusFormatAngleBracketNotRipped" > $(IP_DIR)/coregen.cgp
	echo "SET designentry = VHDL" >> $(IP_DIR)/coregen.cgp
	echo "SET device = $(TARGET_DEVICE)" >> $(IP_DIR)/coregen.cgp
	echo "SET devicefamily = $(TARGET_FAMILY)" >> $(IP_DIR)/coregen.cgp
	echo "SET flowvendor = Other" >> $(IP_DIR)/coregen.cgp
	echo "SET package = $(TARGET_PACKAGE)" >> $(IP_DIR)/coregen.cgp
	echo "SET speedgrade = $(TARGET_SPEEDGRADE)" >> $(IP_DIR)/coregen.cgp
	echo "SET verilogsim = true" >> $(IP_DIR)/coregen.cgp
	echo "SET vhdlsim = true" >> $(IP_DIR)/coregen.cgp
	cd $(IP_DIR) && coregen -p coregen.cgp -b ../$<
ip: $(IP_SOURCES:%.xco=%.vhd)


total.ngc: $(SYN_TOTAL_VHDL_SOURCES) $(SYN_TOTAL_VERILOG_SOURCES)
	-rm total.prj
	$(foreach file,$(SYN_TOTAL_VERILOG_SOURCES),echo "verilog work \"$(file)\"" >> total.prj;)
	$(foreach file,$(SYN_TOTAL_VHDL_SOURCES),echo "vhdl work \"$(file)\"" >> total.prj;)
	$(foreach file,$(SYN_TOTAL_IPS),echo "vhdl work \"$(file)\"" >> total.prj;)
	echo "run" > total.scr
	echo "-ifn total.prj" >> total.scr
	echo "-ofn total.ngc" >> total.scr
	echo "-ifmt mixed" >> total.scr
	echo "-top $(SYN_TOTAL_TOPLEVEL)" >> total.scr
	echo "-p $(TARGET_DEVICE)$(TARGET_SPEEDGRADE)-$(TARGET_PACKAGE)" >> total.scr
	echo "$(SYN_TOTAL_XST_OPTIONS)" >> total.scr
	xst -intstyle xflow -ifn total.scr
	netgen -intstyle xflow -sim -ofmt verilog -w -insert_glbl true $(SYN_TOTAL_NETGEN_OPTIONS) total.ngc
syn_total: total.ngc

total.ncd: total.ngc $(SYN_TOTAL_CONSTRAINTS)
	ngdbuild -intstyle xflow -p $(TARGET_DEVICE)$(TARGET_SPEEDGRADE)-$(TARGET_PACKAGE) -uc $(SYN_TOTAL_CONSTRAINTS) $(SYN_TOTAL_NGD_OPTIONS) total.ngc total.ngd
	map -intstyle xflow $(SYN_TOTAL_MAP_OPTIONS) -p $(TARGET_DEVICE)$(TARGET_SPEEDGRADE)-$(TARGET_PACKAGE) -w total.ngd -o total.map.ncd total.pcf
	par -intstyle xflow $(SYN_TOTAL_PAR_OPTIONS) -w total.map.ncd total.ncd total.pcf | tee total.par.log
	netgen -intstyle xflow -sim -ofmt verilog -w -insert_glbl true -sdf_anno true $(SYN_TOTAL_NETGEN_OPTIONS) total.map.ncd
impl_total: total.ncd

total.bit: total.ncd
	bitgen -intstyle xflow -g Binary:Yes -w $(SYN_TOTAL_BITGEN_OPTIONS) total.ncd total.bit
	trce -intstyle xflow $(SYN_TOTAL_TRCE_OPTIONS) total.ncd total.pcf
out_total: total.bit

sim_presim:
	-rm presim.prj
	-rm -rf isim
	$(foreach file,$(SIM_PRESIM_VERILOG_SOURCES),echo "verilog work \"$(file)\"" >> presim.prj;)
	$(foreach file,$(SIM_PRESIM_VHDL_SOURCES),echo "vhdl work \"$(file)\"" >> presim.prj;)
	$(foreach file,$(SIM_PRESIM_IPS),echo "vhdl work \"$(file)\"" >> presim.prj;)
	fuse work.$(SIM_PRESIM_TOPLEVEL) -prj presim.prj -o presim
	-rm presim.tcl
	echo "onerror {resume}" >> presim.tcl
	echo "vcd dumpfile presim.vcd" >> presim.tcl
	echo "vcd dumpvars -m $(SIM_PRESIM_TOPLEVEL) -l $(SIM_PRESIM_LEVELS)" >> presim.tcl
	echo "vcd dumpon" >> presim.tcl
	echo "run $(SIM_PRESIM_RUNTIME)" >> presim.tcl
	echo "vcd dumpflush" >> presim.tcl
	echo "quit" >> presim.tcl
	./presim -tclbatch presim.tcl

sim_postsim:
	-rm postsim.prj
	-rm -rf isim
	$(foreach file,$(SIM_POSTSIM_VERILOG_SOURCES),echo "verilog work \"$(file)\"" >> postsim.prj;)
	$(foreach file,$(SIM_POSTSIM_VHDL_SOURCES),echo "vhdl work \"$(file)\"" >> postsim.prj;)
	$(foreach file,$(SIM_POSTSIM_IPS),echo "vhdl work \"$(file)\"" >> postsim.prj;)
	fuse work.$(SIM_POSTSIM_TOPLEVEL) work.glbl -prj postsim.prj -o postsim
	-rm postsim.tcl
	echo "onerror {resume}" >> postsim.tcl
	echo "vcd dumpfile postsim.vcd" >> postsim.tcl
	echo "vcd dumpvars -m $(SIM_POSTSIM_TOPLEVEL) -l $(SIM_POSTSIM_LEVELS)" >> postsim.tcl
	echo "vcd dumpon" >> postsim.tcl
	echo "run $(SIM_POSTSIM_RUNTIME)" >> postsim.tcl
	echo "vcd dumpflush" >> postsim.tcl
	echo "quit" >> postsim.tcl
	./postsim -tclbatch postsim.tcl

endif
# Include remote functions
include remote_makefile