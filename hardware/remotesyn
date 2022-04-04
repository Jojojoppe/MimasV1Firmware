#!/usr/bin/env python3
from concurrent.futures import thread
from re import sub
import sys
import os
import shutil
import configparser
import subprocess
import paramiko
import socket
import threading
import struct
import base64
import time
import glob

# ------------------------------------------------------------

class exec_ISE:
    def __init__(self, config, builddir):
        self.config = config
        self.builddir = builddir
        self.create_builddir()

    def create_outdir(self, target):
        self.outdir = self.config.get('project', 'out_dir', fallback='OUT')
        if not os.path.exists(self.outdir):
            os.mkdir(self.outdir)
        if not os.path.exists(f'{self.outdir}/{target}'):
            os.mkdir(f'{self.outdir}/{target}')

    def create_builddir(self):
        if not os.path.exists(self.builddir):
            os.mkdir(self.builddir)

    def enter_builddir(self):
        self.curdir = os.getcwd()
        os.chdir(self.builddir)

    def leave_builddir(self):
        os.chdir(self.curdir)

    def do_ip_gen(self, target):
        # get used IP's for target
        ips = config.get(target, 'src_ip', fallback='').split()
        self.create_outdir(target)

        print("+ Generate IPs")

        for i, ip in enumerate(ips):
            # Create cgp file
            with open(f'{self.builddir}/coregen_{i}.cgp', 'w') as f:
                f.write(f'SET busformat = BusFormatAngleBracketNotRipped\n')
                f.write(f'SET designentry = VHDL\n')
                f.write(f'SET device = {config.get("target", "device")}\n')
                f.write(f'SET devicefamily = {config.get("target", "family")}\n')
                f.write(f'SET package = {config.get("target", "package")}\n')
                f.write(f'SET speedgrade = {config.get("target", "speedgrade")}\n')
                f.write(f'SET flowvendor = Other\n')
                f.write(f'SET verilogsim = true\n')
                f.write(f'SET vhdlsim = true\n')
            # crete xco file
            with open(f'{self.builddir}/coregen_{i}.xco', 'w') as f:
                ipsec = 'ip_%s'%ip
                f.write(f'SELECT {ip} {config.get(ipsec, ipsec)}\n')
                for s in config[ipsec]:
                    if s==ipsec:
                        continue
                    f.write(f'CSET {s}={config.get(ipsec, s)}\n')
                f.write('GENERATE')
            # Clear log
            if os.path.exists(f'{self.builddir}/coregen.log'):
                os.remove(f'{self.builddir}/coregen.log')
            # Run coregen
            pid = subprocess.Popen(f'coregen -p coregen_{i}.cgp -b coregen_{i}.xco', shell=True, cwd=self.builddir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            while pid.poll() is None:
                print('.', end='', flush=True)
                time.sleep(2)
            res = pid.returncode
            print('')

            if not os.path.exists(f'{self.outdir}/{target}/{ip}'):
                os.mkdir(f'{self.outdir}/{target}/{ip}')
            # Copy files to output directory if succeeded
            if res == 0:
                shutil.copyfile(f'{self.builddir}/{ip}.vhd', f'{self.outdir}/{target}/{ip}/{ip}.vhd')
                shutil.copyfile(f'{self.builddir}/{ip}.v', f'{self.outdir}/{target}/{ip}/{ip}.v')
                shutil.copyfile(f'{self.builddir}/{ip}.ngc', f'{self.outdir}/{target}/{ip}/{ip}.ngc')
            # Copy log
            shutil.copyfile(f'{self.builddir}/coregen.log', f'{self.outdir}/{target}/{ip}/{ip}.log')
            
            if res!=0:
                exit(res)

    def do_synthesize(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Synthesize')

        extra_opts = self.config.get(target, 'extra_options').split('\n')
        opts = {}
        for o in extra_opts:
            tp = o.split()[0]
            op = ' '.join(o.split()[1:])
            opts[tp] = op

        if 'xst' not in opts:
            opts['xst'] = ''

        if 'netgen' not in opts:
            opts['netgen'] = ''
 
        with open('syn.prj', 'w') as f:
            src = self.config.get(target, 'src_vhdl', fallback='').split()
            for s in src:
                f.write(f'vhdl work "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_verilog', fallback='').split()
            for s in src:
                f.write(f'verilog work "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_sysverilog', fallback='').split()
            for s in src:
                f.write(f'verilog work "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_ip', fallback='').split()
            for s in src:
                f.write(f'vhdl work "{self.curdir}/{self.outdir}/{target}/{s}/{s}.vhd"\n')
        with open('prj.scr', 'w') as f:
            f.write('run\n-ifn syn.prj\n-ofn syn.ngc\n-ifmt mixed\n')
            f.write(f"-top {self.config.get(target, 'toplevel', fallback='_top_')}\n")
            f.write(f"-p {self.config.get('target', 'device', fallback='_d_')}")
            f.write(self.config.get('target', 'speedgrade', fallback='_s_'))
            f.write(f"-{self.config.get('target', 'package', fallback='_p_')}")
            f.write(f"\n{opts['xst']}\n")

        pid = subprocess.Popen(f'xst -intstyle xflow -ifn prj.scr', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        if res!=0:
            self.leave_builddir()
            exit(res)

        success = True
        pid = subprocess.Popen(f"netgen -intstyle xflow -sim -ofmt verilog -w -insert_glbl true {opts['netgen']} syn.ngc", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        if res!=0:
            success = False
            exit(res)

        self.leave_builddir()

        if success:
            if not os.path.exists(f'{self.outdir}/{target}'):
                os.mkdir(f'{self.outdir}/{target}')
            # Copy files to output directory if succeeded
            shutil.copyfile(f'{self.builddir}/syn.ngc', f'{self.outdir}/{target}/{target}.ngc')
            shutil.copyfile(f'{self.builddir}/syn.v', f'{self.outdir}/{target}/{target}.v')
        shutil.copyfile(f'{self.builddir}/prj.srp', f'{self.outdir}/{target}/syn.log')
        
    def do_implement(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Implement')

        extra_opts = self.config.get(target, 'extra_options').split('\n')
        opts = {}
        for o in extra_opts:
            tp = o.split()[0]
            op = ' '.join(o.split()[1:])
            opts[tp] = op

        if 'ngd' not in opts:
            opts['ngd'] = ''

        if 'map' not in opts:
            opts['map'] = ''

        if 'par' not in opts:
            opts['par'] = ''

        part = f"{self.config.get('target', 'device', fallback='_d_')}{self.config.get('target', 'speedgrade', fallback='_s_')}-{self.config.get('target', 'package', fallback='_p_')}"
        cons = self.config.get(target, 'src_constraints', fallback='__con__')
        pid = subprocess.Popen(f"ngdbuild -intstyle xflow -p {part} -uc {self.curdir}/{cons} {opts['ngd']} {self.curdir}/{self.outdir}/{target}/{target}.ngc impl.ngd", shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        shutil.copyfile(f'impl.bld', f'{self.curdir}/{self.outdir}/{target}/impl-ngd.log')
        if res!=0:
            self.leave_builddir()
            exit(res)

        pid = subprocess.Popen(f"map -intstyle xflow -detail -p {part} {opts['map']} -w impl.ngd -o impl.map.ncd impl.pcf", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        shutil.copyfile(f'impl.map.mrp', f'{self.curdir}/{self.outdir}/{target}/impl-map.log')
        if res!=0:
            self.leave_builddir()
            exit(res)

        pid = subprocess.Popen(f"par -intstyle xflow {opts['par']} -w impl.map.ncd impl.pcf | tee impl.par.log", shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        shutil.copyfile(f'impl.par.log', f'{self.curdir}/{self.outdir}/{target}/impl-par.log')
        if res!=0:
            self.leave_builddir()
            exit(res)

        pid = subprocess.Popen(f"netgen -intstyle xflow -sim -ofmt verilog -w -insert_glbl true -sdf_anno true {opts['netgen']} impl.map.ncd", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        if res!=0:
            self.leave_builddir()
            exit(res)

        self.leave_builddir()

        shutil.copyfile(f'{self.builddir}/impl.map.v', f'{self.outdir}/{target}/{target}.map.v')
        shutil.copyfile(f'{self.builddir}/impl.map.sdf', f'{self.outdir}/{target}/{target}.map.sdf')
        shutil.copyfile(f'{self.builddir}/impl.pcf.ncd', f'{self.outdir}/{target}/{target}.ncd')
        shutil.copyfile(f'{self.builddir}/impl.pcf', f'{self.outdir}/{target}/{target}.pcf')

    def do_bit(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Generate output files')

        extra_opts = self.config.get(target, 'extra_options').split('\n')
        opts = {}
        for o in extra_opts:
            tp = o.split()[0]
            op = ' '.join(o.split()[1:])
            opts[tp] = op

        if 'bitgen' not in opts:
            opts['bitgen'] = ''

        if 'trce' not in opts:
            opts['trce'] = ''

        pid = subprocess.Popen(f"bitgen -intstyle xflow -g Binary:Yes -w {opts['bitgen']} {self.curdir}/{self.outdir}/{target}/{target}.ncd bit.bit {self.curdir}/{self.outdir}/{target}/{target}.pcf", shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        self.leave_builddir()
        shutil.copyfile(f'{self.builddir}/bit.bit', f'{self.outdir}/{target}/{target}.bit')
        shutil.copyfile(f'{self.builddir}/bit.bin', f'{self.outdir}/{target}/{target}.bin')
        if res!=0:
            exit(res)

        self.enter_builddir()
        pid = subprocess.Popen(f"trce -intstyle xflow {opts['trce']} {self.curdir}/{self.outdir}/{target}/{target}.ncd {self.curdir}/{self.outdir}/{target}/{target}.pcf", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        self.leave_builddir()
        shutil.copyfile(f'{self.builddir}/{target}.twr', f'{self.outdir}/{target}/timing.log')
        if res!=0:
            exit(res)

    def do_floorplan(self, target):
        self.create_outdir(target)
        self.enter_builddir()
        part = f"{self.config.get('target', 'device', fallback='_d_')}{self.config.get('target', 'package', fallback='_p_')}{self.config.get('target', 'speedgrade', fallback='_s_')}"
        cons = self.config.get(target, 'src_constraints', fallback='__con__')
        with open('paproj.tcl', 'w') as f:
            f.write(f'create_project -name paproj -dir paproj -part {part}\n')
            f.write('set_property design_mode GateLvl [get_property srcset [current_run -impl]]\n')
            f.write(f"set_property edif_top_file {self.curdir}/{self.outdir}/{target}/{target}.ngc [get_property srcset [current_run]]\n")
            f.write(f"add_files [list {{{cons}}}] -fileset [get_property constrset [current_run]]\n")
            f.write(f"set_property target_constrs_file {cons} [current_fileset -constrset]\n")
            f.write(f"link_design\nread_xdl -file {self.curdir}/{self.outdir}/{target}/{target}.ncd\n")
        pid = subprocess.Popen('planAhead -source paproj.tcl', shell=True, stdout=subprocess.DEVNULL, stder=None)
        res = pid.wait()
        self.leave_builddir()

    def do_sim(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Simulate')

        if os.path.exists('isim'):
            shutil.rmtree('isim')

        with open('sim.prj', 'w') as f:
            src = self.config.get(target, 'src_vhdl', fallback='').split()
            for s in src:
                f.write(f'vhdl work "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_verilog', fallback='').split()
            for s in src:
                f.write(f'verilog work "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_sysverilog', fallback='').split()
            for s in src:
                f.write(f'verilog work "{self.curdir}/{s}"\n')
            # TODO add IP

        extras = ''
        if self.config.get(target, 'simtype', fallback='presim') == 'postsim':
            extras = f"--{self.config.get(target, 'delay', fallback='typ')}delay work.glbl"

        pid = subprocess.Popen(f"fuse {extras} work.{self.config.get(target, 'toplevel', fallback='toplevel')} -prj sim.prj -o sim", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        if res!=0:
            exit(res)

        with open('sim.tcl', 'w') as f:
            f.write("onerror {resume}\n")
            f.write("vcd dumpfile sim.vcd\n")
            f.write(f"vcd dumpvars -m {self.config.get(target, 'toplevel', fallback='toplevel')} -l {config.get(target, 'levels', fallback='10')}\n")
            f.write("vcd dumpon\n")
            f.write(f"run {self.config.get(target, 'runtime', fallback='100 ns')}\n")
            f.write("vcd dumpflush\nquit\n")
        
        extras = ''
        if self.config.get(target, 'simtype', fallback='presim') == 'postsim':
            extras = f"-sdf{self.config.get(target, 'delay', fallback='typ')} {self.config.get(target, 'sdfroot', fallback='dut')}={self.curdir}/{self.config.get(target, 'src_sdf', fallback='_s_')}"

        pid = subprocess.Popen(f'./sim -tclbatch sim.tcl {extras} > sim.log', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        res = pid.returncode
        print('')
        if res!=0:
            exit(res)

        self.leave_builddir()

        if not os.path.exists(f'{self.outdir}/{target}'):
            os.mkdir(f'{self.outdir}/{target}')
        shutil.copyfile(f'{self.builddir}/sim.vcd', f'{self.outdir}/{target}/output.vcd')
        shutil.copyfile(f'{self.builddir}/fuse.log', f'{self.outdir}/{target}/synth.log')
        shutil.copyfile(f'{self.builddir}/sim.log', f'{self.outdir}/{target}/output.log')

class exec_VIVADO:
    def __init__(self, config, builddir):
        self.config = config
        self.builddir = builddir
        self.create_builddir()

    def create_outdir(self, target):
        self.outdir = self.config.get('project', 'out_dir', fallback='OUT')
        if not os.path.exists(self.outdir):
            os.mkdir(self.outdir)
        if not os.path.exists(f'{self.outdir}/{target}'):
            os.mkdir(f'{self.outdir}/{target}')

    def create_builddir(self):
        if not os.path.exists(self.builddir):
            os.mkdir(self.builddir)

    def enter_builddir(self):
        self.curdir = os.getcwd()
        os.chdir(self.builddir)

    def leave_builddir(self):
        os.chdir(self.curdir)

    def do_ip_gen(self, target):
        # get used IP's for target
        ips = config.get(target, 'src_ip', fallback='').split()
        self.create_outdir(target)

        print("+ Generate IPs")

        dev = self.config.get('target', 'device', fallback='_d_')
        sgrade = self.config.get('target', 'speedgrade', fallback='_s_')
        pkg = self.config.get('target', 'package', fallback='_p_')

        for i, ip in enumerate(ips):
            self.enter_builddir()
            ipsec = 'ip_%s'%ip
            ipname = self.config.get(ipsec, ipsec)

            ipconfig = '[ list \\\n'
            for s in self.config[ipsec]:
                if s==ipsec:
                    continue
                ipconfig += f'    CONFIG.{s.upper()} {{{self.config.get(ipsec, s)}}}\\\n'
            ipconfig += '  ]'

            with open('do.tcl', 'w') as f:
                f.write(f"file mkdir {ip}\ncreate_project -in_memory\nset_property part {dev}{pkg}{sgrade} [current_project]\n")
                f.write(f"create_ip -name {ipname.split(':')[2]} -vendor {ipname.split(':')[1]} -library {ipname.split(':')[0 ]} -module_name {ip} -dir {ip}\n")
                f.write(f"set_property -dict {ipconfig} [ get_ips {ip} ]\n")
                f.write(f"export_ip_user_files -of_objects [get_files {ip}/{ip}/{ip}.xci ] -no_script -sync -force -quiet\n")
                f.write(f"upgrade_ip [get_ips]\ngenerate_target all [get_ips]\n#synth_ip [get_ips]\n")
                # f.write(f"export_simulation -directory {ip} -simulator xsim -absolute_path -export_source_files -of_objects [get_files {ip}/{ip}/{ip}.xci]")

            pid = subprocess.Popen('vivado -mode batch -source do.tcl', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            while pid.poll() is None:
                print('.', end='', flush=True)
                time.sleep(2)
            ret = pid.returncode
            print('')

            if ret != 0:
                self.leave_builddir()
                if not os.path.exists(f'{self.outdir}/{target}/{ip}'):
                    os.mkdir(f'{self.outdir}/{target}/{ip}')
                shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/{ip}/log.log')
                exit(ret)

            self.leave_builddir()
            if not os.path.exists(f'{self.outdir}/{target}/{ip}'):
                os.mkdir(f'{self.outdir}/{target}/{ip}')
            shutil.copyfile(f"{self.builddir}/{ip}/{ip}/{ip}.vho", f'{self.outdir}/{target}/{ip}/{ip}.vho')
            shutil.copyfile(f"{self.builddir}/{ip}/{ip}/{ip}.veo", f'{self.outdir}/{target}/{ip}/{ip}.veo')
            shutil.copyfile(f"{self.builddir}/{ip}/{ip}/{ip}.xci", f'{self.outdir}/{target}/{ip}/{ip}.xci')
            shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/{ip}/log.log')

            for f in glob.glob(f"{self.builddir}/{ip}/{ip}/*.c"):
                shutil.copy(f, f'{self.outdir}/{target}/{ip}/')
            for f in glob.glob(f"{self.builddir}/{ip}/{ip}/*.h"):
                shutil.copy(f, f'{self.outdir}/{target}/{ip}/')

    def do_synthesize(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Synthesize')

        extra_opts = self.config.get(target, 'extra_options').split('\n')
        opts = {}
        for o in extra_opts:
            tp = o.split()[0]
            op = ' '.join(o.split()[1:])
            opts[tp] = op

        if 'syn' not in opts:
            opts['syn'] = ''

        if 'netlist_top' not in opts:
            opts['netlist_top'] = self.config.get(target, 'toplevel', fallback='toplevel')

        dev = self.config.get('target', 'device', fallback='_d_')
        sgrade = self.config.get('target', 'speedgrade', fallback='_s_')
        pkg = self.config.get('target', 'package', fallback='_p_')

        with open('do.tcl', 'w') as f:
            src = self.config.get(target, 'src_vhdl', fallback='').split()
            for s in src:
                f.write(f'read_vhdl "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_verilog', fallback='').split()
            for s in src:
                f.write(f'read_verilog "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_sysverilog', fallback='').split()
            for s in src:
                f.write(f'read_verilog -sv "{self.curdir}/{s}"\n')
            src = self.config.get(target, 'src_constraints', fallback='')
            f.write(f'read_xdc "{self.curdir}/{src}"\n')
            src = self.config.get(target, 'src_ip', fallback='').split()
            for s in src:
                if os.path.exists(s):
                    shutil.rmtree(s)
                os.mkdir(s)
                shutil.copyfile(f'{self.curdir}/{self.outdir}/{target}/{s}/{s}.xci', f'{s}/{s}.xci')
                f.write(f'read_ip "{s}/{s}.xci"\n')

            f.write(f"set_property part {dev}{pkg}{sgrade} [current_project]\n")
            f.write(f"upgrade_ip [get_ips]\ngenerate_target all [get_ips]\nsynth_ip [get_ips]\n")
            f.write(f"synth_design -top {self.config.get(target, 'toplevel', fallback='toplevel')} -part {dev}{pkg}{sgrade} {opts['syn']}\n")

            f.write(f"write_checkpoint -force post_synth.dcp\nwrite_verilog -force -mode timesim -cell {opts['netlist_top']} -sdf_anno true -nolib netlist.v\n")
            f.write(f"write_sdf -force -cell {opts['netlist_top']} -mode timesim netlist.sdf\n")

        pid = subprocess.Popen('vivado -mode batch -source do.tcl', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')

        if ret != 0:
            self.leave_builddir()
            shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/synth.log')
            exit(ret)

        self.leave_builddir()
        shutil.copyfile(f'{self.builddir}/netlist.v', f'{self.outdir}/{target}/synth_netlist.v')
        shutil.copyfile(f'{self.builddir}/netlist.sdf', f'{self.outdir}/{target}/synth_netlist.sdf')
        shutil.copyfile(f'{self.builddir}/post_synth.dcp', f'{self.outdir}/{target}/post_synth.dcp')
        shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/synth.log')

    def do_implement(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Implement')

        extra_opts = self.config.get(target, 'extra_options').split('\n')
        opts = {}
        for o in extra_opts:
            tp = o.split()[0]
            op = ' '.join(o.split()[1:])
            opts[tp] = op

        if 'opt' not in opts:
            opts['opt'] = ''
        if 'place' not in opts:
            opts['place'] = ''
        if 'route' not in opts:
            opts['route'] = ''

        with open('do.tcl', 'w') as f:
            f.write(f"open_checkpoint {self.curdir}/{self.outdir}/{target}/post_synth.dcp\n")
            f.write(f"opt_design {opts['opt']}\nplace_design {opts['place']}\nroute_design {opts['route']}\n")
            f.write(f"write_checkpoint -force {self.curdir}/{self.outdir}/{target}/post_impl.dcp\n")

        pid = subprocess.Popen('vivado -mode batch -source do.tcl', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')

        if ret != 0:
            self.leave_builddir()
            shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/impl.log')
            exit(ret)

        self.leave_builddir()
        shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/impl.log')

    def do_bit(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Generate output files')

        extra_opts = self.config.get(target, 'extra_options').split('\n')
        opts = {}
        for o in extra_opts:
            tp = o.split()[0]
            op = ' '.join(o.split()[1:])
            opts[tp] = op

        if 'netlist_top' not in opts:
            opts['netlist_top'] = self.config.get(target, 'toplevel', fallback='toplevel')

        with open('do.tcl', 'w') as f:
            f.write(f"open_checkpoint {self.curdir}/{self.outdir}/{target}/post_impl.dcp\n")
            f.write(f"set_property SEVERITY {{Warning}} [get_drc_checks NSTD-1]\nset_property SEVERITY {{Warning}} [get_drc_checks UCIO-1]\n")
            f.write(f"set_property BITSTREAM.General.UnconstrainedPins {{Allow}} [current_design]\n")
            f.write(f"write_debug_probes -force out.ltx\nwrite_bitstream -force -bin_file out.bit\nreport_timing_summary -file timing.log\nreport_power -file power.log\n")
            f.write(f"report_utilization -file util.log\n")
            f.write(f"write_checkpoint -force {self.curdir}/{self.outdir}/{target}/total.dcp\n")
            f.write(f"open_checkpoint {self.curdir}/{self.outdir}/{target}/total.dcp\n")
            f.write(f"write_hw_platform -fixed -force -file {self.curdir}/{self.outdir}/{target}/system.xsa\n")
            f.write(f"write_verilog -force -mode timesim -cell {opts['netlist_top']} -rename_top {opts['netlist_top']} -sdf_anno true netlist.v\n") # -nolib
            f.write(f"write_sdf -force -cell {opts['netlist_top']} -rename_top {opts['netlist_top']} -mode timesim netlist.sdf\n")

        pid = subprocess.Popen('vivado -mode batch -source do.tcl', shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')

        if ret != 0:
            self.leave_builddir()
            shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/bit.log')
            exit(ret)

        self.leave_builddir()

        shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/bit.log')
        shutil.copyfile(f"{self.builddir}/timing.log", f'{self.outdir}/{target}/timing.log')
        shutil.copyfile(f"{self.builddir}/util.log", f'{self.outdir}/{target}/util.log')
        shutil.copyfile(f"{self.builddir}/power.log", f'{self.outdir}/{target}/power.log')
        shutil.copyfile(f"{self.builddir}/out.bit", f'{self.outdir}/{target}/out.bit')
        shutil.copyfile(f"{self.builddir}/out.bin", f'{self.outdir}/{target}/out.bin')
        shutil.copyfile(f"{self.builddir}/netlist.v", f'{self.outdir}/{target}/impl_netlist.v')
        shutil.copyfile(f"{self.builddir}/netlist.sdf", f'{self.outdir}/{target}/impl_netlist.sdf')

    def do_floorplan(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Open floorplan viewer')

        with open('do.tcl', 'w') as f:
            f.write(f"open_checkpoint {self.curdir}/{self.outdir}/{target}/post_impl.dcp\n")
            f.write(f"start_gui")

        pid = subprocess.Popen('vivado -mode batch -source do.tcl', shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')

        self.leave_builddir()

        if ret != 0:
            exit(ret)

    def do_sim(self, target):
        self.create_outdir(target)
        self.enter_builddir()

        print('+ Simulate')

        if os.path.exists('sim'):
            shutil.rmtree('sim')

        dev = self.config.get('target', 'device', fallback='_d_')
        sgrade = self.config.get('target', 'speedgrade', fallback='_s_')
        pkg = self.config.get('target', 'package', fallback='_p_')

        with open('do.tcl', 'w') as f:
            f.write(f"create_project -force -part {dev}{pkg}{sgrade} sim sim\n")
            src = self.config.get(target, 'src_vhdl', fallback='').split()
            for s in src:
                f.write(f'add_files -norecurse -scan_for_includes {self.curdir}/{s}\n')
                f.write(f'import_files -norecurse {self.curdir}/{s}\n')
            src = self.config.get(target, 'src_verilog', fallback='').split()
            for s in src:
                f.write(f'add_files -norecurse -scan_for_includes {self.curdir}/{s}\n')
                f.write(f'import_files -norecurse {self.curdir}/{s}\n')
            src = self.config.get(target, 'src_sysverilog', fallback='').split()
            for s in src:
                f.write(f'add_files -norecurse -scan_for_includes {self.curdir}/{s}\n')
                f.write(f'import_files -norecurse {self.curdir}/{s}\n')
            src = self.config.get(target, 'src_ip', fallback='').split()
            for s in src:
                f.write(f'add_files -norecurse {self.curdir}/{self.outdir}/{s}/{s}.xci\n')
            src = self.config.get(target, 'src_c', fallback='').split()
            for s in src:
                if s.endswith('.h'):
                    continue
                f.write(f'add_files -norecurse -scan_for_includes {self.curdir}/{s}\n')
                f.write(f'import_files -norecurse {self.curdir}/{s}\n')

            if self.config.get(target, 'src_sdf', fallback='__sdf__') != '__sdf__':
                s = self.config.get(target, 'src_sdf', fallback='__sdf__')
                f.write(f'add_files -norecurse -scan_for_includes {self.curdir}/{s}\n')
                f.write(f'import_files -norecurse {self.curdir}/{s}\n')
                f.write(f"file mkdir sim/sim.sim/sim_1/behav/xsim\nfile copy -force {self.curdir}/{s} {self.curdir}/{self.builddir}/sim/sim.sim/sim_1/behav/xsim/netlist.sdf\n")
                # f.write(f"file mkdir sim/sim.sim/sim_1/behav/xsim\nfile copy -force {self.curdir}/{s} {self.curdir}/{self.builddir}/sim/sim.sim/sim_1/behav/xsim/{os.path.split(s)[1]}\n")

            f.write(f"set_property top {self.config.get(target, 'toplevel', fallback='toplevel')} [get_filesets sim_1]\n")
            f.write("set_property top_lib xil_defaultlib [get_filesets sim_1]\n")
            f.write("launch_simulation -noclean_dir -scripts_only -absolute_path\n")

        pid = subprocess.Popen('vivado -mode batch -source do.tcl', shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')

        if ret != 0:
            self.leave_builddir()
            print("Something went wrong...")
            shutil.copyfile(f"{self.builddir}/vivado.log", f'{self.outdir}/{target}/prepare.log')
            exit(ret)

        shutil.copyfile(f"vivado.log", f'{self.curdir}/{self.outdir}/{target}/prepare.log')

        extras = ''
        if self.config.get(target, 'simtype', fallback='presim') == 'postsim':
            extras = f"-{self.config.get(target, 'delay', fallback='typ')}delay -transport_int_delays -pulse_r 0 -pulse_int_r 0 -L simprims_ver"

        pid = subprocess.Popen(f'sed -i "s/xelab/xelab {extras}/g" elaborate.sh', shell=True, cwd='sim/sim.sim/sim_1/behav/xsim', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')
        if ret!=0:
            print("Something went wrong with editing elaborate stage...")
            exit(ret)

        if self.config.get(target, 'simtype', fallback='presim') == 'postsim':
            pid = subprocess.Popen(f"sed -i '/ \/I /d' netlist.sdf && sed -i '/glbl.v/d' *.prj", shell=True, cwd='sim/sim.sim/sim_1/behav/xsim', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            # pid = subprocess.Popen(f"sed -i '/glbl.v/d' *.prj", shell=True, cwd='sim/sim.sim/sim_1/behav/xsim', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            while pid.poll() is None:
                print('.', end='', flush=True)
                time.sleep(2)
            ret = pid.returncode
            print('')
            if ret!=0:
                print("Something went wrong with editing project files...")
                exit(ret)

        pid = subprocess.Popen(f'bash compile.sh', shell=True, cwd='sim/sim.sim/sim_1/behav/xsim', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')
        if ret!=0:
            self.leave_builddir()
            print("Compile error")
            shutil.copyfile(f"{self.builddir}/sim/sim.sim/sim_1/behav/xsim/compile.log", f'{self.outdir}/{target}/compile.log')
            exit(ret)
        shutil.copyfile(f"{self.curdir}/{self.builddir}/sim/sim.sim/sim_1/behav/xsim/compile.log", f'{self.curdir}/{self.outdir}/{target}/compile.log')

        pid = subprocess.Popen(f'bash elaborate.sh', shell=True, cwd='sim/sim.sim/sim_1/behav/xsim', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')
        if ret!=0:
            self.leave_builddir()
            print("Elaborate error")
            shutil.copyfile(f"{self.builddir}/sim/sim.sim/sim_1/behav/xsim/elaborate.log", f'{self.outdir}/{target}/elaborate.log')
            exit(ret)
        shutil.copyfile(f"{self.curdir}/{self.builddir}/sim/sim.sim/sim_1/behav/xsim/elaborate.log", f'{self.curdir}/{self.outdir}/{target}/elaborate.log')

        with open(f"sim/sim.sim/sim_1/behav/xsim/{self.config.get(target, 'toplevel', fallback='toplevel')}.tcl", 'w') as f:
            f.write(f"open_vcd out.vcd\nlog_vcd\nrun {self.config.get(target, 'runtime', fallback='100 ns')}\nclose_vcd\nquit\n")

        pid = subprocess.Popen(f'bash simulate.sh', shell=True, cwd='sim/sim.sim/sim_1/behav/xsim', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while pid.poll() is None:
            print('.', end='', flush=True)
            time.sleep(2)
        ret = pid.returncode
        print('')
        if ret!=0:
            self.leave_builddir()
            print("Simulation error")
            shutil.copyfile(f"{self.builddir}/sim/sim.sim/sim_1/behav/xsim/simulate.log", f'{self.outdir}/{target}/simulate.log')
            exit(ret)
        shutil.copyfile(f"{self.curdir}/{self.builddir}/sim/sim.sim/sim_1/behav/xsim/simulate.log", f'{self.curdir}/{self.outdir}/{target}/simulate.log')

        self.leave_builddir()
        shutil.copyfile(f'{self.builddir}/sim/sim.sim/sim_1/behav/xsim/out.vcd', f'{self.outdir}/{target}/output.vcd')

# ------------------------------------------------------------

class Heartbeat(threading.Thread):
    def __init__(self, channel):
        threading.Thread.__init__(self)
        self.channel = channel
        self.running = True
        self.printing = False
    def stop(self):
        self.running = False
    def run(self):
        while self.running:
            if self.printing:
                print('.', end='', flush=True)
            self.channel.exec_command(base64.encodebytes(b'hb'))
            time.sleep(2)

class exec_REMOTE:
    def __init__(self, config, configfile):
        self.config = config
        self.configfile = configfile

        self.privkey = self.config.get('server', 'privkey', fallback='__privkey__')
        self.pubkey = self.config.get('server', 'pubkey', fallback='__pubkey__')
        self.hostname = self.config.get('server', 'hostname', fallback='__hostname__')
        self.port = self.config.get('server', 'port', fallback='__port__')

        self.tc = self.config.get('project', 'toolchain', fallback='ISE')

        if self.privkey=='__privkey__' or self.pubkey=='__pubkey__' or self.hostname=='__hostname__' or self.port=='__port__':
            print("Not enough server information in the config file")
            exit(1)

        self.host_key = paramiko.RSAKey(filename=self.privkey)
        client = paramiko.SSHClient()
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        trans = paramiko.Transport((self.hostname, int(self.port)))
        trans.connect(None, pkey=self.host_key)

        self.channel = trans.open_channel('session')
        self.hbchannel = trans.open_channel('session')

        self.heartbeat = Heartbeat(self.hbchannel)
        self.heartbeat.start()

        # Send project identification
        cmd = b'id' + struct.pack('>q', hash(self.host_key.get_base64()))
        self.channel.exec_command(base64.encodebytes(cmd))

    def __del__(self):
        self.heartbeat.stop()
        self.channel.exec_command(base64.encodebytes(b'ex'))

    def cmd(self, cmd):
        self.channel.exec_command(base64.encodebytes(cmd))

    def sstr(self, s):
        return struct.pack('>I', len(s)) + s.encode('utf-8')

    def rstr(self):
        l = struct.unpack('>I', self.channel.recv(4))[0]
        return bytes.decode(self.channel.recv(l), 'utf-8')

    def recv_dir(self, dr):
        self.cmd(b'ls'+self.sstr(dr))
        status = self.channel.recv(2)
        if status!=b'OK':
            msg = self.channel.recv(1024)
            print("Error:", bytes.decode(msg, 'ascii'))
            exit(1)
        ls = self.rstr()
        for p in ls.split('\n'):
            tp = p[0]
            name = p[1:]
            if tp=='d':
                self.recv_dir(f'{dr}/{name}')
            else:
                self.recv_file(f'{dr}/{name}')

    def send_file(self, file, othername=None):
        print(f"> {file}")
        if not os.path.exists(file):
            print(f"Error: {file} does not exists")
        with open(file, 'rb') as f:
            stat = os.fstat(f.fileno())
            print('  -> fsize', stat.st_size)
            if othername is None:
                othername = file
            fsize = struct.pack('>q', stat.st_size)

            self.cmd(b'sf'+self.sstr(othername)+fsize)

            status = self.channel.recv(3)
            if status!=b'OK\n':
                print('Something went wrong...')
                exit(1)

            i = stat.st_size
            while i>0:
                fdata = f.read(1024)
                i -= 1024
                self.channel.sendall(fdata)

    def recv_file(self, file):
        print(f"< {file}")
        if os.path.dirname(file) != '':
            os.makedirs(os.path.dirname(file), exist_ok=True)
        with open(file, 'wb') as f:
            self.cmd(b'rf'+self.sstr(file))
            status = self.channel.recv(2)
            if status!=b'OK':
                msg = self.channel.recv(1024)
                print("Error:", bytes.decode(msg, 'ascii'))
                exit(1)
            fsize = self.channel.recv(8)
            fsize = struct.unpack('>q', fsize)[0]
            print('  -> fsize', fsize)
            while fsize>0:
                f.write(self.channel.recv(1024))
                fsize -= 1024

    def do_ip_gen(self, target):
        print("+ Generate IPs")
        self.send_file(self.configfile, 'project.cfg')
        self.heartbeat.printing = True
        self.cmd(b'do'+self.sstr(f'ip {target}'))
        res = struct.unpack('>I', self.channel.recv(4))[0]
        self.heartbeat.printing = False
        print(f' [{res}]')

        # get used IP's for target
        ips = config.get(target, 'src_ip', fallback='').split()
        for i, ip in enumerate(ips):
            self.recv_dir(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{ip}")

        if res != 0:
            print("Some error occured...")
            exit(1)

    def do_synthesize(self, target):
        print("+ Synthesize")

        self.send_file(self.configfile, 'project.cfg')
        src = self.config.get(target, 'src_vhdl', fallback='').split()
        for s in src:
            self.send_file(s)
        src = self.config.get(target, 'src_verilog', fallback='').split()
        for s in src:
            self.send_file(s)
        src = self.config.get(target, 'src_sysverilog', fallback='').split()
        for s in src:
            self.send_file(s)
        src = self.config.get(target, 'src_ip', fallback='').split()
        for s in src:
            if self.tc=='ISE':
                self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{s}/{s}.vhd")
            elif self.tc=="VIVADO":
                self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{s}/{s}.xci")
        if self.tc=="VIVADO":
            self.send_file(f"{self.config.get(target, 'src_constraints', fallback='__con__')}")

        self.heartbeat.printing = True
        self.cmd(b'do'+self.sstr(f'syn {target}'))
        res = struct.unpack('>I', self.channel.recv(4))[0]
        self.heartbeat.printing = False
        print(f' [{res}]')

        if res != 0:
            print("Some error occured...")
            if self.tc=='ISE':
                self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/syn.log")
            elif self.tc=="VIVADO":
                self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/synth.log")
            exit(1)

        if self.tc=='ISE':
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.ngc")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.v")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/syn.log")
        elif self.tc=="VIVADO":
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/synth.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/post_synth.dcp")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/synth_netlist.v")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/synth_netlist.sdf")

    def do_implement(self, target):
        print("+ Implement")

        self.send_file(self.configfile, 'project.cfg')
        if self.tc=='ISE':
            self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.ngc")
            self.send_file(f"{self.config.get(target, 'src_constraints', fallback='__con__')}")
        elif self.tc=="VIVADO":
            self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/post_synth.dcp")

        self.heartbeat.printing = True
        self.cmd(b'do'+self.sstr(f'impl {target}'))
        res = struct.unpack('>I', self.channel.recv(4))[0]
        self.heartbeat.printing = False
        print(f' [{res}]')

        if res != 0:
            print("Some error occured...")
            if self.tc=='ISE':
                # FIXME possible that not all are there
                self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl-ngd.log")
                self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl-map.log")
                self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl-par.log")
            elif self.tc=="VIVADO":
                self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl.log")
            exit(1)

        if self.tc=='ISE':
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl-ngd.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl-map.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl-par.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.map.v")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.map.sdf")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.ncd")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.pcf")
        elif self.tc=="VIVADO":
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/post_impl.dcp")

    def do_bit(self, target):
        print("+ Generate output files")

        self.send_file(self.configfile, 'project.cfg')
        if self.tc=='ISE':
            self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.ncd")
            self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.pcf")
        elif self.tc=="VIVADO":
            self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/post_impl.dcp")

        self.heartbeat.printing = True
        self.cmd(b'do'+self.sstr(f'bit {target}'))
        res = struct.unpack('>I', self.channel.recv(4))[0]
        self.heartbeat.printing = False
        print(f' [{res}]')

        if res != 0:
            print("Some error occured...")
            if self.tc=='ISE':
                # TODO what to send?
                pass
            elif self.tc=="VIVADO":
                self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/bit.log")
            exit(1)

        if self.tc=='ISE':
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/timing.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.bit")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{target}.bin")
        elif self.tc=="VIVADO":
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/bit.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/out.bit")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/out.bin")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/power.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/timing.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/util.log")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/system.xsa")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/total.dcp")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl_netlist.sdf")
            self.recv_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/impl_netlist.v")

    def do_floorplan(self, target):
        print("Error: floorplan editing not implemented for remote execution")
        exit(1)

    def do_sim(self, target):
        print("+ Simulate")

        self.send_file(self.configfile, 'project.cfg')

        src = self.config.get(target, 'src_vhdl', fallback='').split()
        for s in src:
            self.send_file(s)
        src = self.config.get(target, 'src_verilog', fallback='').split()
        for s in src:
            self.send_file(s)
        src = self.config.get(target, 'src_sysverilog', fallback='').split()
        for s in src:
            self.send_file(s)
        src = self.config.get(target, 'src_sdf', fallback='')
        if src!='':
            self.send_file(src)
        src = self.config.get(target, 'src_ip', fallback='').split()
        for s in src:
            if self.tc=='ISE':
                self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{s}/{s}.vhd")
            elif self.tc=="VIVADO":
                self.send_file(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}/{s}/{s}.xci")
        if self.tc=="VIVADO":
            src = self.config.get(target, 'src_c', fallback='').split()
            for s in src:
                self.send_file(s)

        self.heartbeat.printing = True
        self.cmd(b'do'+self.sstr(f'sim {target}'))
        res = struct.unpack('>I', self.channel.recv(4))[0]
        self.heartbeat.printing = False
        print(f' [{res}]')

        self.recv_dir(f"{self.config.get('project', 'out_dir', fallback='OUT')}/{target}")

# ------------------------------------------------------------

class HeartbeatChecker(threading.Thread):
    def __init__(self, server):
        threading.Thread.__init__(self)
        self.server = server
        self.running = True
        self.hb = True
    def stop(self):
        self.running = False
    def run(self):
        while self.running:
            if not self.hb:
                self.server.active = False
                self.server.event.set()
            self.hb = False
            time.sleep(5)

class Executer(threading.Thread):
    def __init__(self, args, channel, identifier):
        threading.Thread.__init__(self)
        self.args = args
        self.channel = channel
        self.identifier = identifier
        self.pid = None
    def run(self):
        self.pid = subprocess.Popen(f"../{sys.argv[0]} -l -c project.cfg {self.args}", shell=True, cwd=f'{self.identifier}', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        res = self.pid.wait()
        self.pid = None
        self.channel.sendall(struct.pack('>I', res))

class FileTransferSF(threading.Thread):
    def __init__(self, channel, fname, identifier, fsize):
        threading.Thread.__init__(self)
        self.channel = channel
        self.fname = fname
        self.identifier = identifier
        self.fsize = fsize
    def run(self):
        with open(f"{self.identifier}/{self.fname}", 'wb') as f:
            fsize = self.fsize
            while fsize>0:
                fdata = self.channel.recv(1024)
                f.write(fdata)
                fsize -= 1024

class FileTransferRF(threading.Thread):
    def __init__(self, channel, fname, identifier):
        threading.Thread.__init__(self)
        self.channel = channel
        self.fname = fname
        self.identifier = identifier
    def run(self):
        with open(f"{self.identifier}/{self.fname}", 'rb') as f:
            stat = os.fstat(f.fileno())
            print('  -> fsize', stat.st_size)
            fsize = struct.pack('>q', stat.st_size)
            i = stat.st_size
            self.channel.sendall(b'OK'+fsize)
            while i>0:
                fdata = f.read(1024)
                self.channel.sendall(fdata)
                i -= 1024

class Server(paramiko.ServerInterface):
    def __init__(self, authorized):
        self.event = threading.Event()
        self.authorized = authorized
        self.active = True
        self.hbchecker = HeartbeatChecker(self)
        self.hbchecker.start()
        self.processes = []

    def stopall(self):
        print("Stop all running processes")
        for p in self.processes:
            if p.pid is not None:
                p.pid.terminate()

    def check_channel_request(self, kind, chanid):
        if kind == 'session':
            return paramiko.OPEN_SUCCEEDED

    def check_auth_publickey(self, username, key):
        keyascii = key.get_base64()
        for auth in self.authorized:
            authascii = auth.split(' ')[1]
            if authascii==keyascii:
                return paramiko.AUTH_SUCCESSFUL
        return paramiko.AUTH_FAILED

    def get_allowed_auths(self, username):
        return 'publickey'

    def rstr(self, b):
        l = struct.unpack('>I', b[:4])[0]
        return (bytes.decode(b[4:4+l], 'utf-8'), b[4+l:])

    def sstr(self, s):
        return struct.pack('>I', len(s)) + s.encode('utf-8')

    def check_channel_exec_request(self, channel, command):
        # self.event.set()
        command = base64.decodebytes(command)
        cmd = command[:2]
        data = command[2:]

        if cmd==b'id':
            identifier = struct.unpack('>q', data[:8])[0]
            self.identifier = str(identifier)
            print('>', identifier)
            # Create directory
            if os.path.exists(str(identifier)):
                shutil.rmtree(str(identifier))
            os.mkdir(str(identifier))

        elif cmd==b'ex':
            print('<', self.identifier)
            #shutil.rmtree(str(self.identifier))
            self.active = False
            self.hbchecker.stop()
            self.event.set()

        elif cmd==b'hb':
            self.hbchecker.hb = True

        # List files
        elif cmd==b'ls':
            dr, data = self.rstr(data)
            print('ls', dr)
            if not os.path.exists(f"{self.identifier}/{dr}"):
                channel.sendall(b'ERFile not found')
            es = []
            for f in os.listdir(f'{self.identifier}/{dr}'):
                if os.path.isfile(f'{self.identifier}/{dr}/{f}'):
                    df = 'f'
                else:
                    df = 'd'
                es.append(f'{df}{f}')
            channel.sendall(b'OK' + self.sstr('\n'.join(es)))

        # Send file
        elif cmd==b'sf':
            fname, data = self.rstr(data)
            fsize = struct.unpack('>q', data)[0]
            print('>>', fname, fsize)
            os.makedirs(os.path.dirname(f"{self.identifier}/{fname}"), exist_ok=True)
            channel.sendall(b'OK\n')
            FileTransferSF(channel, fname, self.identifier, fsize).start()

        # Receive file
        elif cmd==b'rf':
            fname, data = self.rstr(data)
            print('<<', fname)
            if not os.path.exists(f"{self.identifier}/{fname}"):
                channel.sendall(b'ERFile not found')
            else:
                FileTransferRF(channel, fname, self.identifier).start()

        # Execute synth
        elif cmd==b'do':
            args, data = self.rstr(data)
            print('[]', args)
            executer = Executer(args, channel, self.identifier)
            executer.start()
            self.processes.append(executer)

        return True

class Connection(threading.Thread):
    def __init__(self, client, addr, host_key, authorized):
        threading.Thread.__init__(self)
        self.client = client
        self.addr = addr
        self.host_key = host_key
        self.running = True
        self.authorized = authorized
        print(f"Connection from {addr}")

    def stop(self):
        self.running = False
        self.server.event.set()

    def run(self):
        self.running = True
        t = paramiko.Transport(self.client)
        t.set_gss_host(socket.getfqdn(""))
        t.load_server_moduli()
        t.add_server_key(self.host_key)
        server = Server(self.authorized)
        t.start_server(server=server)
        self.server = server

        # Wait for the event
        while server.active:
            server.event.wait(10)

        server.stopall()
        shutil.rmtree(server.identifier)

        t.close()
        print('connection closed')

def server(accidentals, positionals):
    addr = accidentals['server'].split(':')
    if len(addr)!=2:
        print("Host address must be in form hostname:port")
        exit(1)
    host_key = paramiko.RSAKey(filename=accidentals['privkey'])
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((addr[0], int(addr[1])))
    sock.listen(100)

    # Get authorized hosts
    with open(accidentals['authorized'], 'r') as f:
        authorized = f.read().split('\n')

    running = True
    threads = []
    try:
        while running:
            client, addr = sock.accept()
            conn = Connection(client, addr, host_key, authorized)
            conn.start()
            threads.append(conn)
    except KeyboardInterrupt:
        print("Stopping server")
        running = False
        for t in threads:
            t.stop()
    finally:
        sock.close()

def main(accidentals, positionals):
    if 'server' in accidentals:
        return server(accidentals, positionals)
    elif 'local' in accidentals:
        config = accidentals['config']
        if config.get('project', 'toolchain') == 'ISE':
            execInterface = exec_ISE(config, accidentals['builddir'])
        else:
            execInterface = exec_VIVADO(config, accidentals['builddir'])
    else:
        config = accidentals['config']
        execInterface = exec_REMOTE(config, accidentals['configname'])

    i = 0
    while i< len(positionals):
        action = positionals[i]
        i += 1

        if action == 'ip':
            if i>=len(positionals):
                print("Unexpected end of input")
                exit(1)
            target = positionals[i]
            i += 1
            execInterface.do_ip_gen(target)

        elif action == 'syn':
            if i>=len(positionals):
                print("Unexpected end of input")
                exit(1)
            target = positionals[i]
            i += 1
            execInterface.do_synthesize(target)

        elif action == 'impl':
            if i>=len(positionals):
                print("Unexpected end of input")
                exit(1)
            target = positionals[i]
            i += 1
            execInterface.do_implement(target)

        elif action == 'bit':
            if i>=len(positionals):
                print("Unexpected end of input")
                exit(1)
            target = positionals[i]
            i += 1
            execInterface.do_bit(target)

        elif action == 'all':
            if i>=len(positionals):
                print("Unexpected end of input")
                exit(1)
            target = positionals[i]
            i += 1
            execInterface.do_synthesize(target)
            execInterface.do_implement(target)
            execInterface.do_bit(target)

        elif action == 'floorplan':
            if i>=len(positionals):
                print("Unexpected end of input")
                exit(1)
            target = positionals[i]
            i += 1
            execInterface.do_floorplan(target)

        elif action == 'sim':
            if i>=len(positionals):
                print("Unexpected end of input")
                exit(1)
            target = positionals[i]
            i += 1
            execInterface.do_sim(target)

        else:
            print("Unknown action...")
            exit(1)

# ------------------------------------------------------------

def print_help():
    print("Unified FPGA synthesizer frontend\r\n(c) Joppe Blondel - 2022\r\n")
    print(f"Usage: {sys.argv[0]} [ OPTIONS ] action [ target ] ...")
    print("where OPTIONS := { -h | -l | -s host:post privkey pubkey authorized | -c config | -b build_dir }")
    print("      action  := { ip | syn | impl | bit | all | floorplan | sim }")

if __name__=="__main__":
    accidentals = {}
    positionals = []

    if len(sys.argv)==1:
        print_help()
        exit(1)

    i = 1
    while i<len(sys.argv):
        if sys.argv[i].startswith('-'):
            if sys.argv[i] == '-h':
                print_help()
                exit(0)
            elif sys.argv[i] == '-l':
                accidentals['local'] = True
            elif sys.argv[i] == '-s':
                if i+1>=len(sys.argv):
                    print("Unexpected end of input")
                    exit(1)
                accidentals['server'] = sys.argv[i+1]
                i += 1
                if i+1>=len(sys.argv):
                    print("Unexpected end of input")
                    exit(1)
                accidentals['privkey'] = sys.argv[i+1]
                i += 1
                if i+1>=len(sys.argv):
                    print("Unexpected end of input")
                    exit(1)
                accidentals['pubkey'] = sys.argv[i+1]
                i += 1
                if i+1>=len(sys.argv):
                    print("Unexpected end of input")
                    exit(1)
                accidentals['authorized'] = sys.argv[i+1]
                i += 1
            elif sys.argv[i] == '-c':
                if i+1>=len(sys.argv):
                    print("Unexpected end of input")
                    exit(1)
                accidentals['config'] = sys.argv[i+1]
                i += 1
            elif sys.argv[i] == '-b':
                if i+1>=len(sys.argv):
                    print("Unexpected end of input")
                    exit(1)
                accidentals['builddir'] = sys.argv[i+1]
                i += 1

        else:
            if sys.argv[i] == 'init':
                print("+ Generate example configuration file")
                with open('example.cfg', 'w') as f:
                    f.write("# PROJECT SETTINGS\n")
                    f.write("# ----------------\n")
                    f.write("[server]\nhostname = localhost\nport = 8080\nprivkey = keys/id_rsa\npubkey = keys/id_rsa.pub\n\n")
                    f.write("[project]\n# Toolchain selection. choose between [ISE, VIVADO]\ntoolchain = ISE\nout_dir = OUT\n\n")
                    f.write("[target]\nfamily = spartan6\ndevice = xc6lsx9\npackage = tgq144\nspeedgrade = -2\n\n")
                    f.write("# HARDWARE TARGETS\n")
                    f.write("# ----------------\n")
                    f.write("src_vhdl = RTL/toplevel.vhd\nsrc_verilog = \nsrc_sysverilog = \n")
                    f.write("src_constraints = CON/toplevel.ucf\nsrc_ip = \ntoplevel = toplevel\nextra_options = ")
                exit(1)

            positionals.append(sys.argv[i])
        i += 1

    if 'config' not in accidentals and 'server' not in accidentals:
        # Running in client mode and no config file specified -> pick default
        accidentals['config'] = 'project.cfg'

    if 'config' in accidentals and 'server' not in accidentals:
        if os.path.exists(accidentals['config']):
            accidentals['configname'] = accidentals['config']
            config = configparser.ConfigParser()
            config.read(accidentals['config'])
            accidentals['config'] = config
        else:
            print(f"Config file \'{accidentals['config']}\' not found")
            exit(1)

    if ('server' in accidentals or 'local' in accidentals) and 'builddir' not in accidentals:
        accidentals['builddir'] = '.build'

    main(accidentals, positionals)
    exit(0)