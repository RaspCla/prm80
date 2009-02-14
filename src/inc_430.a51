;    Copyright (c) 2007, 2008 Florian MAZEN and Pierre COL
;    
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.

CONFIG_CHAN_COUNT       EQU    031h
CONFIG_SHIFT_LO         EQU    080h
CONFIG_SHIFT_HI         EQU    000h
CONFIG_PLL_DIV_LO       EQU    090h
CONFIG_PLL_DIV_HI       EQU    020h
CONFIG_SCAN_DURATION	EQU    008h

freq_list:
        ; Channel : 0 Frequency : 430.025000
        DB      086h
        DB      062h
        ; Channel : 1 Frequency : 430.050000
        DB      086h
        DB      064h
        ; Channel : 2 Frequency : 430.075000
        DB      086h
        DB      066h
        ; Channel : 3 Frequency : 430.100000
        DB      086h
        DB      068h
        ; Channel : 4 Frequency : 430.125000
        DB      086h
        DB      06ah
        ; Channel : 5 Frequency : 430.150000
        DB      086h
        DB      06ch
        ; Channel : 6 Frequency : 430.175000
        DB      086h
        DB      06eh
        ; Channel : 7 Frequency : 430.200000
        DB      086h
        DB      070h
        ; Channel : 8 Frequency : 430.225000
        DB      086h
        DB      072h
        ; Channel : 9 Frequency : 430.250000
        DB      086h
        DB      074h
        ; Channel : 10 Frequency : 430.275000
        DB      086h
        DB      076h
        ; Channel : 11 Frequency : 430.300000
        DB      086h
        DB      078h
        ; Channel : 12 Frequency : 430.325000
        DB      086h
        DB      07ah
        ; Channel : 13 Frequency : 430.350000
        DB      086h
        DB      07ch
        ; Channel : 14 Frequency : 430.375000
        DB      086h
        DB      07eh
        ; Channel : 15 Frequency : 434.600000
        DB      087h
        DB      0d0h
        ; Channel : 16 Frequency : 434.625000
        DB      087h
        DB      0d2h
        ; Channel : 17 Frequency : 434.650000
        DB      087h
        DB      0d4h
        ; Channel : 18 Frequency : 434.675000
        DB      087h
        DB      0d6h
        ; Channel : 19 Frequency : 434.700000
        DB      087h
        DB      0d8h
        ; Channel : 20 Frequency : 434.725000
        DB      087h
        DB      0dah
        ; Channel : 21 Frequency : 434.750000
        DB      087h
        DB      0dch
        ; Channel : 22 Frequency : 434.775000
        DB      087h
        DB      0deh
        ; Channel : 23 Frequency : 434.800000
        DB      087h
        DB      0e0h
        ; Channel : 24 Frequency : 434.825000
        DB      087h
        DB      0e2h
        ; Channel : 25 Frequency : 434.850000
        DB      087h
        DB      0e4h
        ; Channel : 26 Frequency : 434.875000
        DB      087h
        DB      0e6h
        ; Channel : 27 Frequency : 434.900000
        DB      087h
        DB      0e8h
        ; Channel : 28 Frequency : 434.925000
        DB      087h
        DB      0eah
        ; Channel : 29 Frequency : 434.950000
        DB      087h
        DB      0ech
        ; Channel : 30 Frequency : 434.975000
        DB      087h
        DB      0eeh
        ; Channel : 31 Frequency : 433.500000
        DB      087h
        DB      078h

chan_state_table:
        DB      05h    ; Channel : 0
        DB      05h    ; Channel : 1
        DB      05h    ; Channel : 2
        DB      05h    ; Channel : 3
        DB      05h    ; Channel : 4
        DB      05h    ; Channel : 5
        DB      05h    ; Channel : 6
        DB      05h    ; Channel : 7
        DB      05h    ; Channel : 8
        DB      05h    ; Channel : 9
        DB      05h    ; Channel : 10
        DB      05h    ; Channel : 11
        DB      05h    ; Channel : 12
        DB      05h    ; Channel : 13
        DB      05h    ; Channel : 14
        DB      01h    ; Channel : 15
        DB      01h    ; Channel : 16
        DB      01h    ; Channel : 17
        DB      01h    ; Channel : 18
        DB      01h    ; Channel : 19
        DB      01h    ; Channel : 20
        DB      01h    ; Channel : 21
        DB      01h    ; Channel : 22
        DB      01h    ; Channel : 23
        DB      01h    ; Channel : 24
        DB      01h    ; Channel : 25
        DB      01h    ; Channel : 26
        DB      01h    ; Channel : 27
        DB      01h    ; Channel : 28
        DB      01h    ; Channel : 29
        DB      01h    ; Channel : 30
        DB      00h    ; Channel : 31

