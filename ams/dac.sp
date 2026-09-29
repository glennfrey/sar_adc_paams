****************************************************************************
* dac.sp — 8-bit R-2R Ladder DAC SPICE Netlist
* Binary-weighted resistor ladder for SPICE-AMS co-simulation
*
* Ports: b7..b0 (digital inputs, 1.8V=1, 0V=0), vout (analog), vref, vss
****************************************************************************

.SUBCKT dac_spice b7 b6 b5 b4 b3 b2 b1 b0 vout vref vss
*
* R-2R ladder network
* Each bit controls a switch connecting to vref (1) or vss (0)
*
R0  vref n0  2K
R1  n0   n1  2K
R2  n1   n2  2K
R3  n2   n3  2K
R4  n3   n4  2K
R5  n4   n5  2K
R6  n5   n6  2K
R7  n6   vout 2K
*
* Shunt resistors (2R to ground)
Rsh0 n0 vss 2K
Rsh1 n1 vss 2K
Rsh2 n2 vss 2K
Rsh3 n3 vss 2K
Rsh4 n4 vss 2K
Rsh5 n5 vss 2K
Rsh6 n6 vss 2K
*
* Bit-controlled switches (ideal)
S_b7 vref n0 b7 vss DACSW
S_b6 vref n1 b6 vss DACSW
S_b5 vref n2 b5 vss DACSW
S_b4 vref n3 b4 vss DACSW
S_b3 vref n4 b3 vss DACSW
S_b2 vref n5 b2 vss DACSW
S_b1 vref n6 b1 vss DACSW
S_b0 vref vout b0 vss DACSW
*
.MODEL DACSW VSWITCH(RON=10 ROFF=1E9 VON=1.5 VOFF=0.5)
*
.ENDS dac_spice
