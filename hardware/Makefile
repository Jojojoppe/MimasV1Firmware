.SILENT:

# ----------------
# Project settings
# ----------------
TARGET_FAMILY					:= spartan6
TARGET_DEVICE					:= xc6slx9
TARGET_PACKAGE					:= tqg144
TARGET_SPEEDGRADE				:= -2

OUT_DIR							:= OUT
BUILD_DIR						:= BUILD
IP_DIR							:= IP

# -----------
# IP settings
# -----------
IP_SOURCES						:= 

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

# ------------------
# SIMULATION targets
# ------------------
SIM_PRESIM_VHDL_SOURCES			:= RTL/toplevel.vhd SIM/tb_toplevel.vhd
SIM_PRESIM_VERILOG_SOURCES		:= 
SIM_PRESIM_IPS					:=
SIM_PRESIM_OTHER_SOURCES		:= 
SIM_PRESIM_TOPLEVEL				:= tb_toplevel
SIM_PRESIM_RUNTIME				:= all
SIM_PRESIM_LEVELS				:= 10

SIM_POSTSIM_VHDL_SOURCES		:=
SIM_POSTSIM_VHDL_SOURCES		:= SIM/tb_toplevel.vhd
SIM_POSTSIM_VERILOG_SOURCES		:= OUT/total.map.v
SIM_POSTSIM_IPS					:=
SIM_POSTSIM_OTHER_SOURCES		:= OUT/total.map.sdf
SIM_POSTSIM_TOPLEVEL			:= tb_toplevel
SIM_POSTSIM_RUNTIME				:= all
SIM_POSTSIM_LEVELS				:= 10

# -------------
# BASIC TARGETS
# -------------
.PHONY: all
all: ip syn impl bit

.PHONY: clean
clean:
	-rm -rf $(BUILD_DIR)

.PHONY: distclean
distclean: clean
	-rm -rf $(OUT_DIR)/*

# ------------------------------
# NEEDED VARIABLES AND CONSTANTS
# ------------------------------
CURDIR := $(shell pwd)

# -------------
# IP GENERATION
# -------------
$(IP_SOURCES:$(IP_DIR)/%.xco=$(OUT_DIR)/%.vhd): $(IP_SOURCES)
	-mkdir $(BUILD_DIR)
	-mkdir $(OUT_DIR)
	echo "SET busformat = BusFormatAngleBracketNotRipped" > $(BUILD_DIR)/coregen.cgp
	echo "SET designentry = VHDL" >> $(BUILD_DIR)/coregen.cgp
	echo "SET device = $(TARGET_DEVICE)" >> $(BUILD_DIR)/coregen.cgp
	echo "SET devicefamily = $(TARGET_FAMILY)" >> $(BUILD_DIR)/coregen.cgp
	echo "SET flowvendor = Other" >> $(BUILD_DIR)/coregen.cgp
	echo "SET package = $(TARGET_PACKAGE)" >> $(BUILD_DIR)/coregen.cgp
	echo "SET speedgrade = $(TARGET_SPEEDGRADE)" >> $(BUILD_DIR)/coregen.cgp
	echo "SET verilogsim = true" >> $(BUILD_DIR)/coregen.cgp
	echo "SET vhdlsim = true" >> $(BUILD_DIR)/coregen.cgp
	cd $(BUILD_DIR) && coregen -p coregen.cgp -b $(CURDIR)/$<
	cp $(<:$(IP_DIR)/%.xco=$(BUILD_DIR)/%.vhd) $(OUT_DIR)
	# Copy extra files
	cp $(<:$(IP_DIR)/%.xco=$(BUILD_DIR)/%.vho) $(OUT_DIR)
	cp $(<:$(IP_DIR)/%.xco=$(BUILD_DIR)/%.v) $(OUT_DIR)
	cp $(<:$(IP_DIR)/%.xco=$(BUILD_DIR)/%.veo) $(OUT_DIR)
.PNONY: ip
ip: $(IP_SOURCES:$(IP_DIR)/%.xco=$(OUT_DIR)/%.vhd)

# ----------
# SYNTHESIZE
# ----------
$(BUILD_DIR)/total.ngc: $(SYN_TOTAL_VHDL_SOURCES) $(SYN_TOTAL_VERILOG_SOURCES)
	-mkdir $(BUILD_DIR)
	-mkdir $(OUT_DIR)
	-rm $(BUILD_DIR)/total.prj
	$(foreach file,$(SYN_TOTAL_VERILOG_SOURCES),echo "verilog work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/total.prj;)
	$(foreach file,$(SYN_TOTAL_VHDL_SOURCES),echo "vhdl work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/total.prj;)
	$(foreach file,$(SYN_TOTAL_IPS),echo "vhdl work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/total.prj;)
	echo "run" > $(BUILD_DIR)/total.scr
	echo "-ifn total.prj" >> $(BUILD_DIR)/total.scr
	echo "-ofn total.ngc" >> $(BUILD_DIR)/total.scr
	echo "-ifmt mixed" >> $(BUILD_DIR)/total.scr
	echo "-top $(SYN_TOTAL_TOPLEVEL)" >> $(BUILD_DIR)/total.scr
	echo "-p $(TARGET_DEVICE)$(TARGET_SPEEDGRADE)-$(TARGET_PACKAGE)" >> $(BUILD_DIR)/total.scr
	echo "$(SYN_TOTAL_XST_OPTIONS)" >> $(BUILD_DIR)/total.scr
	cd $(BUILD_DIR) && xst -intstyle xflow -ifn total.scr
	cd $(BUILD_DIR) && netgen -intstyle xflow -sim -ofmt verilog -w -insert_glbl true $(SYN_TOTAL_NETGEN_OPTIONS) total.ngc
	# Copy extra files
	cp $(BUILD_DIR)/total.v $(OUT_DIR)/netlist.v
	cp $(BUILD_DIR)/total.srp $(OUT_DIR)/synth.log
.PHONY: syn fsyn
syn: $(BUILD_DIR)/total.ngc
fsyn:
	-rm $(BUILD_DIR)/total.ngc
	${MAKE} ${MFLAGS} syn

# ---------
# IMPLEMENT
# ---------
$(BUILD_DIR)/total.ncd: $(BUILD_DIR)/total.ngc $(SYN_TOTAL_CONSTRAINTS)
	-mkdir $(BUILD_DIR)
	-mkdir $(OUT_DIR)
	cd $(BUILD_DIR) && \
		ngdbuild -intstyle xflow -p $(TARGET_DEVICE)$(TARGET_SPEEDGRADE)-$(TARGET_PACKAGE) -uc $(CURDIR)/$(SYN_TOTAL_CONSTRAINTS) $(SYN_TOTAL_NGD_OPTIONS) total.ngc total.ngd && \
		map -intstyle xflow $(SYN_TOTAL_MAP_OPTIONS) -p $(TARGET_DEVICE)$(TARGET_SPEEDGRADE)-$(TARGET_PACKAGE) -w total.ngd -o total.map.ncd total.pcf && \
		par -intstyle xflow $(SYN_TOTAL_PAR_OPTIONS) -w total.map.ncd total.ncd total.pcf | tee total.par.log && \
		netgen -intstyle xflow -sim -ofmt verilog -w -insert_glbl true -sdf_anno true $(SYN_TOTAL_NETGEN_OPTIONS) total.map.ncd
	# Copy extra files
	cp $(BUILD_DIR)/total.map.v $(OUT_DIR)/total.map.v
	cp $(BUILD_DIR)/total.map.sdf $(OUT_DIR)/total.map.sdf
	cp $(BUILD_DIR)/total.par.log $(OUT_DIR)/par.log
	cp $(BUILD_DIR)/total.map.mrp $(OUT_DIR)/map.log
.PHONY: impl fimpl
impl: $(BUILD_DIR)/total.ncd
fimpl:
	-rm $(BUILD_DIR)/total.ncd
	${MAKE} ${MFLAGS} impl

# ------------------
# BITFILE GENERATION
# ------------------
$(OUT_DIR)/total.bit: $(BUILD_DIR)/total.ncd
	-mkdir $(BUILD_DIR)
	-mkdir $(OUT_DIR)
	cd $(BUILD_DIR) && bitgen -intstyle xflow -g Binary:Yes -w $(SYN_TOTAL_BITGEN_OPTIONS) total.ncd total.bit
	cd $(BUILD_DIR) && trce -intstyle xflow $(SYN_TOTAL_TRCE_OPTIONS) total.ncd total.pcf
	cp $(BUILD_DIR)/total.bit $(OUT_DIR)/total.bit
	# Copy extra files
	cp $(BUILD_DIR)/total.bin $(OUT_DIR)/total.bin
	cp $(BUILD_DIR)/total.twr $(OUT_DIR)/timing.log
.PHONY: bit fbit
bit: $(OUT_DIR)/total.bit
fbit:
	-rm $(OUT_DIR)/total.bit
	${MAKE} ${MFLAGS} bit

# -----------
# SIMULATIONS
# -----------
.PHONY: presim
presim:
	-mkdir $(BUILD_DIR)
	-mkdir $(OUT_DIR)
	-rm $(BUILD_DIR)/presim.prj
	-rm -rf $(BUILD_DIR)/isim
	$(foreach file,$(SIM_PRESIM_VERILOG_SOURCES),echo "verilog work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/presim.prj;)
	$(foreach file,$(SIM_PRESIM_VHDL_SOURCES),echo "vhdl work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/presim.prj;)
	$(foreach file,$(SIM_PRESIM_IPS),echo "vhdl work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/presim.prj;)
	cd $(BUILD_DIR) && fuse work.$(SIM_PRESIM_TOPLEVEL) -prj presim.prj -o presim
	-rm $(BUILD_DIR)/presim.tcl
	echo "onerror {resume}" >> $(BUILD_DIR)/presim.tcl
	echo "vcd dumpfile presim.vcd" >> $(BUILD_DIR)/presim.tcl
	echo "vcd dumpvars -m $(SIM_PRESIM_TOPLEVEL) -l $(SIM_PRESIM_LEVELS)" >> $(BUILD_DIR)/presim.tcl
	echo "vcd dumpon" >> $(BUILD_DIR)/presim.tcl
	echo "run $(SIM_PRESIM_RUNTIME)" >> $(BUILD_DIR)/presim.tcl
	echo "vcd dumpflush" >> $(BUILD_DIR)/presim.tcl
	echo "quit" >> $(BUILD_DIR)/presim.tcl
	cd $(BUILD_DIR) && ./presim -tclbatch presim.tcl
	cp $(BUILD_DIR)/presim.vcd $(OUT_DIR)/presim.vcd

.PHONY: postsim
postsim:
	-mkdir $(BUILD_DIR)
	-mkdir $(OUT_DIR)
	-rm $(BUILD_DIR)/postsim.prj
	-rm -rf $(BUILD_DIR)/isim
	$(foreach file,$(SIM_POSTSIM_VERILOG_SOURCES),echo "verilog work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/postsim.prj;)
	$(foreach file,$(SIM_POSTSIM_VHDL_SOURCES),echo "vhdl work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/postsim.prj;)
	$(foreach file,$(SIM_POSTSIM_IPS),echo "vhdl work \"$(CURDIR)/$(file)\"" >> $(BUILD_DIR)/postsim.prj;)
	cd $(BUILD_DIR) && fuse work.$(SIM_POSTSIM_TOPLEVEL) work.glbl -prj postsim.prj -o postsim
	-rm $(BUILD_DIR)/postsim.tcl
	echo "onerror {resume}" >> $(BUILD_DIR)/postsim.tcl
	echo "vcd dumpfile postsim.vcd" >> $(BUILD_DIR)/postsim.tcl
	echo "vcd dumpvars -m $(SIM_POSTSIM_TOPLEVEL) -l $(SIM_POSTSIM_LEVELS)" >> $(BUILD_DIR)/postsim.tcl
	echo "vcd dumpon" >> $(BUILD_DIR)/postsim.tcl
	echo "run $(SIM_POSTSIM_RUNTIME)" >> $(BUILD_DIR)/postsim.tcl
	echo "vcd dumpflush" >> $(BUILD_DIR)/postsim.tcl
	echo "quit" >> $(BUILD_DIR)/postsim.tcl
	cd $(BUILD_DIR) && ./postsim -tclbatch postsim.tcl
	cp $(BUILD_DIR)/postsim.vcd $(OUT_DIR)/postsim.vcd

# -----------
# PROGRAMMING
# -----------
.PHONY: prog_mimas
prog_mimas: $(OUT_DIR)/total.bin
	sudo mimasprog -p $(OUT_DIR)/total.bin

# ---------
# FLOORPLAN
# ---------
.PHONY: floorplan
floorplan: impl
	-mkdir $(BUILD_DIR)
	-rm -rf $(BUILD_DIR)/paproj
	echo "create_project -name paproj -dir $(BUILD_DIR)/paproj -part $(TARGET_DEVICE)$(TARGET_PACKAGE)$(TARGET_SPEEDGRADE)" > $(BUILD_DIR)/paproj.tcl
	echo "set_property design_mode GateLvl [get_property srcset [current_run -impl]]" >> $(BUILD_DIR)/paproj.tcl
	echo "set_property edif_top_file $(BUILD_DIR)/total.ngc [ get_property srcset [ current_run ] ]" >> $(BUILD_DIR)/paproj.tcl
	echo "add_files [list {$(SYN_TOTAL_CONSTRAINTS)}] -fileset [get_property constrset [current_run]]" >> $(BUILD_DIR)/paproj.tcl
	echo "set_property target_constrs_file $(SYN_TOTAL_CONSTRAINTS) [current_fileset -constrset]" >> $(BUILD_DIR)/paproj.tcl
	echo "link_design" >> $(BUILD_DIR)/paproj.tcl
	echo "read_xdl -file $(BUILD_DIR)/total.ncd" >> $(BUILD_DIR)/paproj.tcl
	echo "" >> $(BUILD_DIR)/paproj.tcl
	planAhead -source $(BUILD_DIR)/paproj.tcl
	rm planAhead*jou
	rm planAhead*log
	rm -rf _xmsgs