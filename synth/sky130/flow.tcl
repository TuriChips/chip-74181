# Leo: OpenROAD floorplan -> place -> route for top. Env: PDK_ROOT, OUT (dir), NETLIST, LIB (filtered tt lib)
set S $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
set OUT $::env(OUT)
read_lef $S/techlef/sky130_fd_sc_hd__nom.tlef
read_lef $S/lef/sky130_fd_sc_hd.lef
read_liberty $::env(LIB)
read_verilog $::env(NETLIST)
link_design top
initialize_floorplan -utilization 40 -aspect_ratio 1 -core_space 5 -site unithd
make_tracks
puts "== die/core"
puts "die [ord::get_die_area] core [ord::get_core_area]"
place_pins -hor_layers met3 -ver_layers met2
global_placement -density 0.6
detailed_placement
write_def $OUT/placed.def
puts "== power rails (met1 rails + met4 straps)"
add_global_connection -net VPWR -pin_pattern {^VPWR$} -power
add_global_connection -net VGND -pin_pattern {^VGND$} -ground
add_global_connection -net VPWR -pin_pattern {^VPB$} -power
add_global_connection -net VGND -pin_pattern {^VNB$} -ground
set_voltage_domain -name CORE -power VPWR -ground VGND
define_pdn_grid -name grid -voltage_domains CORE
add_pdn_stripe -layer met1 -width 0.48 -followpins -grid grid
add_pdn_stripe -layer met4 -width 1.6 -pitch 20 -offset 4 -grid grid
add_pdn_connect -layers {met1 met4} -grid grid
pdngen
puts "== route"
set_routing_layers -signal met1-met4
global_route -guide_file $OUT/route.guide -congestion_iterations 30
detailed_route -output_drc $OUT/route_drc.rpt -verbose 1
write_def $OUT/top.def
write_db $OUT/top.odb
puts "== timing (unconstrained comb, typical corner)"

report_checks -unconstrained -path_delay max -format full -digits 3
report_design_area
