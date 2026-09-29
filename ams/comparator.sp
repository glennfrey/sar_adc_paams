****************************************************************************
* comparator.sp — Comparator SPICE Netlist
* Behavioral comparator with propagation delay for SPICE-AMS co-simulation
*
* Ports: vin_p, vin_n (analog inputs), comp_out (digital output), en, vdd, vss
****************************************************************************

.SUBCKT comparator_spice vin_p vin_n comp_out en vdd vss
*
* Behavioral voltage-controlled voltage source
* Compares vin_p vs vin_n with 2mV hysteresis
* Output is 0V (logic 0) or 1.8V (logic 1)
*
E_comp comp_int vss VOL='(V(vin_p) > V(vin_n) + 0.002) ? 1.8 : 0.0'
*
* Propagation delay (1ns)
Rdelay comp_int comp_delay 1
Cdelay comp_delay vss 1p
*
* Output buffer (drives digital load)
E_out comp_out vss VOL='V(comp_delay)'
*
.ENDS comparator_spice
