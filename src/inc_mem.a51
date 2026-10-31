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

; Memory Handling, initialization...


;--------------------------------------------------------------------------
; Chargement des registre de frequence a partir du canal
; Loading the frequency registers from the channel
;--------------------------------------------------------------------------
get_freq:
	call	wdt_reset
	; Recuperation du canal / channel recovery
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CHAN
	movx	a, @dptr
	mov	r1, a                                   ; r1 memorizes channel number
get_freq_r1:	
	; Recuperation du chan_state
	mov	dph, #RAM_AREA_STATE
	mov	dpl, r1
	movx	a, @dptr
	mov	chan_state, a
	jnb	rev_toggle, gf_no_toggle	; Claude!: V5.2: reverse toggled for the
	cpl	chan_state.1			; Claude!: current channel (not stored)
gf_no_toggle:					; Claude!:
	

get_freq2:
	; Claude!: no jump to get_freq_reverse any more, reverse is handled at the
	; Claude!: end of the shift calculation (gfn_reverse) for the same channel r1
	
get_freq_normal:
	; Recuperation de la frequence
	mov	a, r1
	mov	dph, #RAM_AREA_FREQ
	rl	a
	mov	dpl, a
	movx	a, @dptr
	mov	tx_freq_hi, a
	
	inc	dpl
	movx	a, @dptr
	mov	tx_freq_lo, a

IF FREQ EQ 144
	mov	a, #fi_lo
	add	a, tx_freq_lo
	mov	rx_freq_lo, a
	mov	a, #fi_hi
	addc	a, tx_freq_hi
	mov	rx_freq_hi, a
ELSEIF FREQ EQ 430
	mov	a, tx_freq_lo
	clr	c
	subb	a, #fi_lo
	mov	rx_freq_lo, a
	mov	a, tx_freq_hi
	subb	a, #fi_hi
	mov	rx_freq_hi, a
ENDIF


	; Activation du shift au besoin
	; Shift activation as needed (add shift to Tx freq.)
	;
	; 2021-02: New feature channel specific shift by DC0CM
	; If channel specific shift is available (!= 0) 
	; use channel specific shift instead of global shift
	



	jnb	chan_state.0, gfn_end0			
	
get_ch_shift:
	; Is there a channel specific shift stored?
	clr 	b.0	                            ; will remember if ch_shift high byte != 0 

	mov 	dph, # High Ch0_Shift_freq
	mov		a, r1
	rl		a
	mov		dpl, a
	movx	a, @dptr
	mov		r0,a
	jnz 	ch_shift_hi_nz
	setb 	b.0	                            ; chx_shift high = 0!
ch_shift_hi_nz:	
	inc		dptr
	movx	a, @dptr
	jnz		ch_shift_nz					    ; if channel specific shift (lo and hi) are zero 
	jnb		b.0, ch_shift_nz 	

	mov		dph, #RAM_AREA_CONFIG		    ; ->  no channel specific shift !
	mov		dpl, #RAM_SHIFT_HI			    ;
	movx	a, @dptr					
	mov		r0, a
	inc		dptr
	movx	a, @dptr

ch_shift_nz:                                ; ->  channel specific shift !
	mov		shift_hi, r0
	mov		shift_lo, a
ch_shift_end:


	jnb	chan_state.2, gnf_shift_n           ; Test si shift - ou +
gnf_shift_p:                                ; Shift positif
	mov	r0, shift_lo
	mov	a, tx_freq_lo
	add	a, r0
	mov	tx_freq_lo, a
	mov	a, shift_hi
	addc	a, tx_freq_hi
	mov	tx_freq_hi, a
	jmp	gfn_reverse				; Claude!: was jmp gfn_end0 (reverse test added)
gnf_shift_n:                                ; Shift negatif
	clr	c
	mov	r0, shift_lo
	mov	a, tx_freq_lo
	subb	a, r0
	mov	tx_freq_lo, a
	mov	a, tx_freq_hi 
	subb	a, shift_hi
	mov	tx_freq_hi, a

gfn_reverse:
	; Claude!: Reverse mode (only with shift enabled): TX on the channel
	; Claude!: frequency, RX on the frequency with shift. Uses the channel in
	; Claude!: RAM (r1, also while scanning) and its own shift. The old
	; Claude!: get_freq_reverse took the frequency from freq_list in the program
	; Claude!: memory (factory channels), always RAM_CHAN and the shift of the
	; Claude!: channel tuned before.
	; Claude!: Here: tx_freq = channel +/- shift, rx_freq = channel +/- IF.
	jnb	chan_state.1, gfn_end0			; Claude!: no reverse
	mov	r0, tx_freq_lo				; Claude!: r0/r1 = frequency with shift
	mov	r1, tx_freq_hi				; Claude!: (r1 channel no longer needed)
IF FREQ EQ 144
	clr	c					; Claude!: TX = RX - IF = channel frequency
	mov	a, rx_freq_lo
	subb	a, #fi_lo
	mov	tx_freq_lo, a
	mov	a, rx_freq_hi
	subb	a, #fi_hi
	mov	tx_freq_hi, a
	mov	a, r0					; Claude!: RX = frequency with shift + IF
	add	a, #fi_lo
	mov	rx_freq_lo, a
	mov	a, r1
	addc	a, #fi_hi
	mov	rx_freq_hi, a
ELSEIF FREQ EQ 430
	mov	a, rx_freq_lo				; Claude!: TX = RX + IF = channel frequency
	add	a, #fi_lo
	mov	tx_freq_lo, a
	mov	a, rx_freq_hi
	addc	a, #fi_hi
	mov	tx_freq_hi, a
	clr	c					; Claude!: RX = frequency with shift - IF
	mov	a, r0
	subb	a, #fi_lo
	mov	rx_freq_lo, a
	mov	a, r1
	subb	a, #fi_hi
	mov	rx_freq_hi, a
ENDIF

gfn_end0:
IF TARGET EQ 8070
	call 	shift_dsp                       ; write shift value to dez. storage and display (PRM8070 only)
	setb	ForceLCDrefresh	                ;
ENDIF

gfn_end:
	ret

; Claude!: get_freq_reverse removed (see gfn_reverse above). It read the
; Claude!: frequency from freq_list (program memory) instead of the RAM, always
; Claude!: for RAM_CHAN (wrong while scanning) and with the shift of the
; Claude!: channel tuned before; it also worked without shift enabled.

;----------------------------------------
; Recuperation des parametres
; Verification des checksum de la RAM
;----------------------------------------
load_parameters:
	call	test_checksums		;Test si la ram est valide
	jz	lp_load		
	call	bip
	call	read_eeprom			; Si RAM invalide charger eeprom et retester
	call	test_checksums		; If RAM is invalid load eeprom and retest
	jz	lp_load
	call	load_ram_default	; Si eeprom invalide egalement alors reinit usine
	call	bip					; If the eeprom is also invalid, then it is reset to factory defaults.
lp_load:
	;Charger les donnees de la ram / Load data from the ram
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_MODE
	movx	a, @dptr
	mov	mode, a

	
	mov	dpl, #RAM_SHIFT_LO
	movx	a, @dptr
	mov	shift_lo, a
	mov	dpl, #RAM_SHIFT_HI
	movx	a, @dptr
	mov	shift_hi, a
	
	mov	dpl, #RAM_SCAN_DURATION
	movx	a, @dptr
	mov	scan_duration, a
	ret

;----------------------------------------
; Claude!: new: take over configuration values changed in the RAM (commands
; Claude!: M and S): default shift and scan duration, all checksums new.
; Claude!: Before, a value written with "M" was only used after a restart and
; Claude!: the RAM checksums were wrong (RAM thrown away at the next start).
;----------------------------------------
reload_ram_config:					; Claude!: new routine
	call	update_all_checksums			; Claude!:
reload_config_values:					; Claude!: (command S: RAM read from the EEPROM)
	mov	dph, #RAM_AREA_CONFIG			; Claude!:
	mov	dpl, #RAM_SHIFT_LO			; Claude!:
	movx	a, @dptr				; Claude!:
	mov	shift_lo, a				; Claude!:
	mov	dpl, #RAM_SHIFT_HI			; Claude!:
	movx	a, @dptr				; Claude!:
	mov	shift_hi, a				; Claude!:
	mov	dpl, #RAM_SCAN_DURATION			; Claude!:
	movx	a, @dptr				; Claude!:
	jnz	rrc_scan				; Claude!: 0 would mean 256 * 50 ms
	inc	a					; Claude!:
rrc_scan:						; Claude!:
	mov	scan_duration, a			; Claude!:
	ret						; Claude!:

;----------------------------------------
; Claude!: new: calculate and store the checksums of all four RAM areas
;----------------------------------------
update_all_checksums:					; Claude!: new routine
	call	load_config_area_checksum		; Claude!:
	mov	dph, #RAM_AREA_CONFIG			; Claude!:
	mov	dpl, #RAM_CONFIG_SUM			; Claude!:
	movx	@dptr, a				; Claude!:
	call	load_freq_area_checksum			; Claude!:
	mov	dph, #RAM_AREA_CONFIG			; Claude!:
	mov	dpl, #RAM_FREQ_SUM			; Claude!:
	movx	@dptr, a				; Claude!:
	call	load_shift_area_checksum		; Claude!:
	mov	dph, #RAM_AREA_CONFIG			; Claude!:
	mov	dpl, #RAM_SHIFT_SUM			; Claude!:
	movx	@dptr, a				; Claude!:
	call	load_state_area_checksum		; Claude!:
	mov	dph, #RAM_AREA_CONFIG			; Claude!:
	mov	dpl, #RAM_STATE_SUM			; Claude!:
	movx	@dptr, a				; Claude!:
	ret						; Claude!:

;----------------------------------------
; Test checksum
; Verifi les checksums de 3 zones ainsi
; que l'octet d'identification
; Retourne 0 dans a si OK
;----------------------------------------
test_checksums:
	mov	r7, #0
	
	; Verifier l'octet de controle
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_ID_CODE
	movx	a, @dptr
	clr	c
	subb	a, #ID_CODE
	jz	tc_check_sum0
	inc	r7
	
tc_check_sum0:	
	; Verfication checksum de la zone config
	call	load_config_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CONFIG_SUM
	movx	a, @dptr
	clr	c
	subb	a, r0
	jz	tc_check_sum1
	inc	r7
tc_check_sum1:	
	; Verfication checksum de la zone freq
	call	load_freq_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_FREQ_SUM
	movx	a, @dptr
	clr	c
	subb	a, r0
	jz	tc_check_sum1a
	inc	r7
tc_check_sum1a:	
	; Verfication checksum de la zone shift
	call	load_shift_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_SHIFT_SUM
	movx	a, @dptr
	clr	c
	subb	a, r0
	jz	tc_check_sum2
	inc	r7
tc_check_sum2:
	; Verfication checksum de la zone state
	call	load_state_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_STATE_SUM
	movx	a, @dptr
	clr	c
	subb	a, r0
	jz	tc_check_sum_end
	inc	r7
tc_check_sum_end:
	mov	a, r7
	ret
;----------------------------------------
; Chargement de tous les parametres 
;  par defaut + reinit eeprom
;----------------------------------------
load_ram_default:
	call	load_ram_default_config
	call	load_ram_default_freq
	call	load_ram_default_shift
	call	load_ram_default_state
	call	prog_eeprom
	ret

;----------------------------------------
; Chargement des parametres generaux
; par defaut
; Loading Default general parameters 
;----------------------------------------
load_ram_default_config:
	call	wdt_reset
	mov	dph, #RAM_AREA_CONFIG
	mov	shift_lo, #CONFIG_SHIFT_LO
	mov	shift_hi, #CONFIG_SHIFT_HI
	mov	mode, #00h

	mov	dpl, #RAM_CHAN
	mov	a, #0
	movx	@dptr, a
	mov	dpl, #RAM_MODE
	mov	a, #0
	movx	@dptr, a
	mov	dpl, #RAM_SQUELCH
	mov	a, #05h
	movx	@dptr, a
	mov	dpl, #RAM_MAX_CHAN
	mov	a, #CONFIG_CHAN_COUNT
	movx	@dptr, a
	mov	dpl, #RAM_SHIFT_LO
	mov	a, #CONFIG_SHIFT_LO
	movx	@dptr, a
	mov	dpl, #RAM_SHIFT_HI
	mov	a, #CONFIG_SHIFT_HI
	movx	@dptr, a
	mov	dpl, #RAM_ID_CODE
	mov	a, #ID_CODE
	movx	@dptr, a
	mov	dpl, #RAM_PLL_DIV_HI
	mov	a, #CONFIG_PLL_DIV_HI
	movx	@dptr, a
	mov	dpl, #RAM_PLL_DIV_LO
	mov	a, #CONFIG_PLL_DIV_LO
	movx	@dptr, a
	mov	dpl, #RAM_SCAN_DURATION
	mov	a, #CONFIG_SCAN_DURATION
	movx	@dptr, a
	
	; Calcul de la checksum
	call	load_config_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CONFIG_SUM
	movx	@dptr, a
	ret

;----------------------------------------
; Chargement de la liste des cannaux par defaut
;  
;Load channels frequencies from program EPROM to RAM
;----------------------------------------
load_ram_default_freq:	
	
	call	wdt_reset
	mov	dph, #RAM_AREA_CONFIG	; Load max chan value in r0
	mov	dpl, #RAM_MAX_CHAN
	movx	a, @dptr
	mov	r0, a
lrd_copyloop1:
	mov	dptr,	#freq_list	; Load channel value
	mov	a, r0
	rl	a
	movc	a, @a+dptr
	mov	r1, a			; r1 : freq_lo
	mov	a, r0
	rl	a
	inc	a
	movc	a, @a+dptr
	mov	r2, a			; r2 : freq_hi
	mov	dph, #RAM_AREA_FREQ	; Copy to RAM
	mov	a, r0
	rl	a
	mov	dpl, a
	mov	a, r1
	movx	@dptr, a
	inc	dpl
	mov	a, r2
	movx	@dptr, a
	dec	r0
	cjne	r0, #0ffh, lrd_copyloop1
	
	call	load_freq_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_FREQ_SUM
	movx	@dptr, a
	ret

;----------------------------------------------
;Load channels shift from program EPROM to RAM
;----------------------------------------------
load_ram_default_shift:	
	
	call	wdt_reset
	mov	dph, #RAM_AREA_CONFIG	; Load max chan value in r0
	mov	dpl, #RAM_MAX_CHAN
	movx	a, @dptr
	mov	r0, a
lrds_copyloop1:
	mov	dptr,	#shift_list		; Load shift value
	mov	a, r0
	rl	a
	movc	a, @a+dptr
	mov	r1, a					; r1 : shift_hi
	mov	a, r0
	rl	a
	inc	a
	movc	a, @a+dptr
	mov	r2, a					; r2 : freq_lo
	mov	dph, #RAM_AREA_SHIFT	; Copy to RAM
	mov	a, r0
	rl	a
	mov	dpl, a
	mov	a, r1
	movx	@dptr, a
	inc	dpl
	mov	a, r2
	movx	@dptr, a
	dec	r0
	cjne	r0, #0ffh, lrds_copyloop1
	
	call	load_shift_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_SHIFT_SUM
	movx	@dptr, a
	ret


;----------------------------------------
; Chargement des etats des cannaux
;  par defaut
;----------------------------------------
load_ram_default_state:	
	;Load channels states from program EPROM to RAM
	call	wdt_reset
	mov	dph, #RAM_AREA_CONFIG	; Load max chan value in r0
	mov	dpl, #RAM_MAX_CHAN
	movx	a, @dptr
	mov	r0, a
lrd_copyloop2:
	mov	dptr,	#chan_state_table	; Load channel value
	mov	a, r0
	movc	a, @a+dptr
	mov	r1, a			; r1 : state

	mov	dph, #RAM_AREA_STATE	; Copy to RAM
	mov	a, r0
	mov	dpl, a
	mov	a, r1
	movx	@dptr, a
	dec	r0
	cjne	r0, #0ffh, lrd_copyloop2
	
	; Calcul de la checksum
	call	load_state_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_STATE_SUM
	movx	@dptr, a
	
	ret

;----------------------------------------
; Sauvegarde du mode
;----------------------------------------	
save_mode:
	mov	a, #0ah
	anl	a, mode
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_MODE
	movx	@dptr, a
	
	; Calcul de la checksum
	call	load_config_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CONFIG_SUM
	movx	@dptr, a
	ret

;----------------------------------------
; Activation / desactivation du shift
;----------------------------------------
switch_shift_mode:
	jnb	mode2.0, switch_shift_load	; Test if scanning, channel is not saved in the same place
	mov	r0, chan_scan
	jmp	switch_shift_update
switch_shift_load:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CHAN
	movx	a, @dptr
	mov	r0, a
switch_shift_update:
	clr	chan_state.1
	clr	rev_toggle			; Claude!: V5.2: reverse off (as before)
	
	mov	a, chan_state
	cpl	acc.0
	mov	chan_state, a
	
	mov	dph, #RAM_AREA_STATE
	mov	dpl, r0
	movx	@dptr, a
	
	; Calcul de la checksum
	call	load_state_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_STATE_SUM
	movx	@dptr, a
	
	call	get_freq
	mov	r0, rx_freq_lo
	mov	r1, rx_freq_hi
	call	load_synth

IF TARGET EQ 8070
	call 	shift_dsp						; write shift value to dez. storage and display (PRM8070 only)
	setb	ForceLCDrefresh
ENDIF

	ret

;----------------------------------------
; Shift activation / desactivation 
; and switch positive / negative
;----------------------------------------
switch_shift_mode2:
	jnb	mode2.0, switch_shift2_load			; Test if scanning, channel is not saved in the same place
	mov	r0, chan_scan
	jmp	switch_shift2_update
switch_shift2_load:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CHAN
	movx	a, @dptr
	mov	r0, a
switch_shift2_update:
	clr	chan_state.1
	clr	rev_toggle			; Claude!: V5.2: reverse off (as before)
	
	mov	a, chan_state
	jb	Acc.0, ssm2_shift_enable
	setb	Acc.0					; Shift disable : enable it
	clr	Acc.2
	jmp	ssm2_cont
ssm2_shift_enable:
	jb	Acc.2, ssm2_shift_pos
	setb	Acc.2
	jmp	ssm2_cont
ssm2_shift_pos:
	clr	Acc.0
	clr	Acc.2
ssm2_cont:
	mov	chan_state, a
	
	mov	dph, #RAM_AREA_STATE
	mov	dpl, r0
	movx	@dptr, a
	
	; Calcul de la checksum
	call	load_state_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_STATE_SUM
	movx	@dptr, a
	
	call	get_freq
	mov	r0, rx_freq_lo
	mov	r1, rx_freq_hi
	call	load_synth
	
IF TARGET EQ 8070
	call 	shift_dsp						; write shift value to dez. storage and display (PRM8070 only)
	setb	ForceLCDrefresh
ENDIF
	
	ret

;----------------------------------------
; Passage en mode reverse
;----------------------------------------
switch_reverse:
	call	wdt_reset
	jnb	chan_state.0, sr_end

	; Claude!: V5.2: the key only toggles reverse for the current channel
	; Claude!: (flag rev_toggle), the reverse bit stored in the channel is not
	; Claude!: changed any more; leaving the channel switches reverse back.
	; Claude!: While scanning a key press only stops the scan (see buttons),
	; Claude!: so the scanned channel (chan_scan) is not needed here any more.
	cpl	rev_toggle			; Claude!:

	setb	mode.7
	call	get_freq
	mov	r0, rx_freq_lo
	mov	r1, rx_freq_hi
	call	load_synth
sr_end:
	ret

;----------------------------------------
; Calcul de la checksum de la zone state
;----------------------------------------
load_state_area_checksum:
	mov	dph, #RAM_AREA_STATE
	mov	dpl, #0
	mov	r0, #0
	mov	a, #0
lsac_loop:
	call	wdt_reset
	movx	a, @dptr
	add	a, r0
	mov	r0, a
	inc	dpl
	mov	r1, dpl
	cjne	r1, #0, lsac_loop
	ret

;----------------------------------------
; Calcul de la checksum de la zone freq
;----------------------------------------	
load_freq_area_checksum:	
	mov	dph, #RAM_AREA_FREQ
	mov	dpl, #0
	mov	r0, #0
	mov	a, #0
lfac_loop:
	call	wdt_reset
	movx	a, @dptr
	add	a, r0
	mov	r0, a
	inc	dpl
	mov	r1, dpl
	cjne	r1, #0, lfac_loop
	ret

;----------------------------------------
; Calcul de la checksum de la zone shift
;----------------------------------------	
load_shift_area_checksum:	
	mov	dph, #RAM_AREA_SHIFT
	mov	dpl, #0
	mov	r0, #0
	mov	a, #0
lshac_loop:
	call	wdt_reset
	movx	a, @dptr
	add	a, r0
	mov	r0, a
	inc	dpl
	mov	r1, dpl
	cjne	r1, #0, lshac_loop
	ret

;----------------------------------------
; Calcul de la checksum de la zone config
;----------------------------------------
load_config_area_checksum:	
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #10
	mov	r0, #0
	mov	a, #0
lcac_loop:
	call	wdt_reset
	movx	a, @dptr
	add	a, r0
	mov	r0, a
	inc	dpl
	mov	r1, dpl
	cjne	r1, #0, lcac_loop
	ret

;----------------------------------------
; Changement de mode (Canal / Squelch)
;----------------------------------------
switch_mode:
	cpl	mode.0
	call	update_lcd
	ret

IF TARGET EQ 8070
;------------------------------------------
; Inc / Dec Left 3 Segments (for Test only)
;------------------------------------------
L_Disp_inc:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_L_Disp
	movx	a, @dptr
	inc	a
	movx	@dptr, a
	mov	b, a
	jmp	L_Disp_update

L_Disp_dec:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_L_Disp
	movx	a, @dptr
	dec	a
	movx	@dptr, a 

L_Disp_update:
	; Calcul de la checksum
	call	load_config_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CONFIG_SUM
	movx	@dptr, a
	
	call	update_L_lcd

	ret
ENDIF

;----------------------------------------
; Inc / Dec canal ou squelch
;----------------------------------------
;*** Incrementation de la fonction courante (Canal / Squelch)
chan_inc:
	jb	mode.0, sql_inc
	jnb	mode2.0, chan_inc_load		; Test if scanning, channel is not saved in the same place
	mov	dph, #RAM_AREA_CONFIG		; Claude!: DPTR was not set here: the channel
	mov	dpl, #RAM_CHAN			; Claude!: was written to a random RAM address
	mov	a, chan_scan
	jmp	chan_inc_inc
chan_inc_load:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CHAN
	movx	a, @dptr
chan_inc_inc:
	inc	a
	movx	@dptr, a
	mov	b, a
	
	mov	dpl, #RAM_MAX_CHAN
	movx	a, @dptr
	inc	a
	cjne	a, b, chan_update
	mov	a, #0
	mov	dpl, #RAM_CHAN
	movx	@dptr, a
	jmp	chan_update
chan_dec:
	jb	mode.0, sql_dec
	jnb	mode2.0, chan_dec_load		; Test if scanning, channel is not saved in the same place
	mov	dph, #RAM_AREA_CONFIG		; Claude!: DPTR was not set here: the channel
	mov	dpl, #RAM_CHAN			; Claude!: was written to a random RAM address
	mov	a, chan_scan
	jmp	chan_dec_dec
chan_dec_load:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CHAN
	movx	a, @dptr
chan_dec_dec:
	dec	a
	movx	@dptr, a 
	
	mov	b, #0ffh
	cjne	a, b, chan_update
	mov	dpl, #RAM_MAX_CHAN
	movx	a, @dptr
	mov	dpl, #RAM_CHAN
	movx	@dptr, a
chan_update:
	clr	rev_toggle			; Claude!: V5.2: new channel, stored reverse
	; Calcul de la checksum
	call	load_config_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CONFIG_SUM
	movx	@dptr, a
	
	call	get_freq
	mov	r0, rx_freq_lo
	mov	r1, rx_freq_hi
	call	load_synth

	call	update_lcd

	ret

;*** Incrementation squelch
sql_inc:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_SQUELCH
	movx	a, @dptr
	inc	a
	anl	a, #0fh
	movx	@dptr, a
	jmp	sql_update

;*** Decrementation squelch
sql_dec:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_SQUELCH
	movx	a, @dptr
	dec	a
	anl	a, #0fh
	movx	@dptr, a

sql_update:
	; Calcul de la checksum
	call	load_config_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CONFIG_SUM
	movx	@dptr, a

	mov	dpl, #RAM_SQUELCH
	movx	a, @dptr
	mov	r0, a
	swap	a
	mov	pwm0, a
	
	call	update_lcd
	ret

;----------------------------------------	
; "PROG_EEPROM" : Programme les 2048 octets du debut de la RAM 
;                 externe ($0000 a $07FF) dans l'EEPROM I2C AT24C16. 
;                 "I2C_err" renvoie 0 si OK ; sinon, le code d'erreur. 
;                 En cas d'erreur, "Page" contient le numero de la page
;                 ou s'est produite l'erreur (0 a 127), sinon Page=128.
;                 La programmation dure environ 2 secondes (elle prend
;                 en charge la remise a zero du "Watchdog Timer"). 
 
PROG_EEPROM:     PUSH       ACC            ; 
                 PUSH       DPH            ; 
                 PUSH       DPL            ; 
                 MOV        Page,#0        ; 
                 MOV        DPTR,#0        ; 
                 MOV        A,Page         ; 
wr_page:
                 CALL       I2C_WR_Page    ; 
                 MOV        A,I2C_err      ; 
                 JNZ        fin_wr_all     ; 
                 INC        Page           ; 
                 MOV        A,Page         ; 
                 CJNE       A,#128,wr_page ; 
fin_wr_all:      POP        DPL            ; 
                 POP        DPH            ; 
                 POP        ACC            ; 
                 RET                       ; 

;----------------------------------------	
; "READ_EEPROM" : Lit les 2048 octets de l'EEPROM I2C AT24C16 et place
;                 les donnees au debut de la RAM externe, de l'adresse
;                 $0000 a l'adresse $07FF. 
;                 "I2C_err" renvoie 0 si OK ; sinon, le code d'erreur. 
;                 En cas d'erreur, "Page" contient le numero de la page
;                 ou s'est produite l'erreur (0 a 127), sinon Page=128.
 
READ_EEPROM:     PUSH       ACC            ; 
                 PUSH       DPH            ; 
                 PUSH       DPL            ; 
                 MOV        Page,#0        ; 
                 MOV        DPTR,#0        ; 
                 MOV        A,Page         ; 
rd_page:
                 CALL       I2C_RD_Page    ; 
                 MOV        A,I2C_err      ; 
                 JNZ        fin_rd_all     ; 
                 INC        Page           ; 
                 MOV        A,Page         ; 
                 CJNE       A,#128,rd_page ; 
fin_rd_all:      POP        DPL            ; 
                 POP        DPH            ; 
                 POP        ACC            ; 
                 RET

IF TARGET EQ 8070
;----------------------------------------
; Update left 3 digits of LCD
;----------------------------------------
update_L_lcd:
		call	wdt_reset
		mov	dph, #RAM_AREA_CONFIG		; Test Value currently only
		mov	dpl, #RAM_L_Disp
		movx	a, @dptr
		mov	r0, a

		setb	mode.7

		ret		 
ENDIF

;---------------------------------------------
; Mise a jour du lcd /  Update of the lcd
; Update Channel/Squelch if no RSSI to display
;----------------------------------------------
update_lcd:

		jb	mode2.2, ul_end					; RSSI to display? -> done
		call	wdt_reset
		jb	mode.0, ul_sql					; Si mode sql aller plus loin  / If sql mode go further
		jnb	mode2.0, update_lcd_load		; Test if scanning, channel is not saved in the same place
		mov	a, chan_scan
		jmp	update_lcd_update
update_lcd_load:
		mov	dph, #RAM_AREA_CONFIG			; sinon charger canal
		mov	dpl, #RAM_CHAN
		movx	a, @dptr
update_lcd_update:
		mov	r0, a
		jmp	ul_update
ul_sql:
		mov	dph, #RAM_AREA_CONFIG
		mov	dpl, #RAM_SQUELCH
		movx	a, @dptr
		mov	r0, a
ul_update:
		call	lcd_clear_digits_r
		call	lcd_print_dec
		setb	mode.7
ul_end:
		ret		 

;----------------------------------------
; Recharger l'etat du poste :
;  - Frequence
;  - Puissance
;  - Squelch
;----------------------------------------
load_state:
	call	wdt_reset
	call	get_freq

	mov	r0, rx_freq_lo
	mov	r1, rx_freq_hi
	call	load_synth
	
	call	load_power

	; Initialisation du squelch
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_SQUELCH
	movx	a, @dptr
	swap	a
	mov	pwm0, a
	ret

;----------------------------------------
; Enable or diisable channel lock out
; for scanning
;----------------------------------------
switch_lock_out:
	call	wdt_reset
	jnb	mode2.0, switch_lo_load	; Test if scanning, channel is not saved in the same place
	mov	r1, chan_scan
	jmp	switch_lo_update
switch_lo_load:
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_CHAN
	movx	a, @dptr
	mov	r1, a
switch_lo_update:
	mov	dph, #RAM_AREA_STATE
	mov	dpl, r1
	cpl	chan_state.3
	mov	a, chan_state
	jnb	rev_toggle, slo_store		; Claude!: V5.2: store the reverse bit of
	cpl	acc.1				; Claude!: the channel, not the toggled one
slo_store:					; Claude!:
	movx	@dptr, a

	setb	mode.7

	; Calcul de la checksum
	call	load_state_area_checksum
	mov	dph, #RAM_AREA_CONFIG
	mov	dpl, #RAM_STATE_SUM
	movx	@dptr, a
	ret

