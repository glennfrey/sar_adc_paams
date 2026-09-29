****************************************************************************
* sampl_hold.sp — Sample-and-Hold SPICE Netlist
* Ideal switch + capacitor model for VCS-AD / Xcelium SPICE-AMS co-simulation
* 
* Ports: vin (analog input), vout (analog output), sample_en (digital control)
* 
* SPICE-AMS concept: digital Verilog drives sample_en; SPICE solver simulates
* the analog network (switch + capacitor) each timestep.
****************************************************************************

.SUBCKT sampl_hold_spice vin vout sample_en vdd vss
*
* Ideal voltage-controlled switch
* sample_en high (1.8V) = switch closed (sample mode)
* sample_en low  (0V)   = switch open  (hold mode)
*
S1 vin vout sample_en vss SWITCH
.MODEL SWITCH VSWITCH(RON=1 ROFF=1E12 VON=1.5 VOFF=0.5)
*
* Hold capacitor
C1 vout vss 1pF
*
.ENDS sampl_hold_spice
