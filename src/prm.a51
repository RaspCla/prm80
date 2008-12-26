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

;-----------------------------------------------
; TARGET should be 8060 or 8070
; FREQ	144 A9
;	430 U0
;-----------------------------------------------


$NOBUILTIN
$NOSYMBOLS
$NOMOD51
$NOPAGING

;+++++++++++++++++++++++++++++++++++++++
; Check if TARGET is defined if not
;  end with error
IFNDEF TARGET

$ERROR(TARGET not defined)
    END

ELSEIFNDEF FREQ
$ERROR(FREQ not defined)
    END

ELSE

$INCLUDE (83c552.mcu)

;----------------------------------------
; SFRs
;----------------------------------------
AUXR1		EQU	0a2h

RAM		EQU	030h
RAMbit		EQU	020h
;----------------------------------------
; Variables
;----------------------------------------
serial_latch_lo	EQU	RAMbit+0	; Valeur du premier verrou
serial_latch_hi	EQU	RAMbit+1	; Valeur du deuxieme verrou

vol_hold	EQU	RAMbit+2	; Sauvegarde le volume


mode		EQU	RAMbit+3    	; Mode courant
			    		; b0: Squelch		b1: puissance
					; b2: Squelch ouvert	b3: TX
					; b4: PLL verouille	b5: Appui long memorise
					; b6: Anti-rebond actif	b7: Rafraichier lcd

chan_state	EQU	RAMbit+4	; Option du canal
					; b0: shift		b1: reverse
					; b2: 			b3:
					; b4: 			b5: 
					; b6: 			b7:

RS232status	EQU	RAMbit+5	; Registre d'etat du port serie.
charType	EQU	RAMbit+6	; Contien le resultat de l'analyse d'n caractere
lock		EQU	RAMbit+7	; Verroullage
					; b0: Touches		b1: TX
					; b2: Volume          	b3: RX
					; b4: 			b5: 
					; b6: 			b7:

disp_state	EQU	RAMbit+8	; Symbole à afficherpour prm8070
					; b0: Squelch ouvert	b1: mode squelch
					; b2: Puissance haute	b3: reverse
					; b4: shift		b5: tx

disp_hold	EQU	RAM+0		; Sauvegarde de de l'affichage des symboles


lcd_dataA0	EQU	RAM+1		; Premier octet pour le lcd
lcd_dataA1	EQU	RAM+2		; Deuxieme octet pour le lcd
lcd_dataA2	EQU	RAM+3		; Troisieme octet pour le lcd (4 bits seulement)
lcd_dataA3	EQU	RAM+4		; Quatrieme octet pour le lcd (4 bits seulement)
lcd_dataB0	EQU	RAM+5		; Premier octet pour le lcd
lcd_dataB1	EQU	RAM+6		; Deuxieme octet pour le lcd
lcd_dataB2	EQU	RAM+7		; Troisieme octet pour le lcd (4 bits seulement)
lcd_dataB3	EQU	RAM+8		; Quatrieme octet pour le lcd (4 bits seulement)

but_timer	EQU	RAM+9		; compteur pour l'anti rebond
but_timer2	EQU	RAM+10
but_hold_state	EQU	RAM+11
but_repeat	EQU	RAM+12		; Tempo pour la repetion et l'appui long

;ref_div_hi	EQU	RAM+13
;ref_div_lo	EQU	RAM+14

rx_freq_hi	EQU	RAM+15
rx_freq_lo	EQU	RAM+16
tx_freq_hi	EQU	RAM+17
tx_freq_lo	EQU	RAM+18



shift		EQU	RAM+19		; Shift code sur 8 Bits (environ 3MHz max avec un pas de 12.5KHz)

PtrRXin         EQU     RAM+20    	;   .Pointeur d'entree buffer RX
PtrRXout        EQU     RAM+21        	;   .Pointeur de sortie buffer RX
RXnbo           EQU     RAM+22       	;   .Nombre d'octets dans buffer RX
PtrTXin         EQU     RAM+23       	;   .Pointeur d'entree buffer TX
PtrTXout        EQU     RAM+24       	;   .Pointeur d'entree buffer TX
TXnbo           EQU     RAM+25       	;   .Nombre d'octets dans buffer TX.
Page            EQU     RAM+26       	; - Numero de la page de octets.
RS_ASCmaj       EQU     RAM+27       	; - Octet RS232 conv. en majuscule.
RS_HexDec       EQU     RAM+28       	; - Octet RS232 converti en hexa.
AdrH            EQU     RAM+29       	; - Adresse passee par RS232 (MSB).
AdrL            EQU     RAM+30       	; - Adresse passee par RS232 (LSB).
DataRS          EQU     RAM+31       	; - Donnee passee par le port serie.
I2C_err         EQU     RAM+32       	; - Renvoi d'erreur acces bus I2C.


;----------------------------------------
; Constantes
;----------------------------------------
sp_default	EQU	9fh	; Adresse du pointeur de pile pile a l'initialisation
wdt_int		EQU	0	; Interval du watchdog

; Port constants
ser_sda		EQU	P1.1	; Donnee du bus serie
ser_scl		EQU	P1.0	; Horloge du bus serie

latch_oe	EQU	P3.4
latch_str	EQU	P3.5

lcd_dlen	EQU	P4.2

synth_ce	EQU	P1.5

fi_lo		EQU	0b0h
fi_hi		EQU	006h

but_long_duration	EQU	15
but_repeat_duration	EQU	3
but_repeat_mask		EQU	09h

pwm_freq	EQU	28

; Roles des bits du registre d'etat du port serie "RS232status" :
RD_err		EQU	RS232status.0 ; - Erreur lecture dans buffer RX.
TFR_run		EQU	RS232status.1 ; - Emission de donnees en cours

; Bits analyse du type de caractere
I2C_ACK         EQU     charType.0    ; - Bit "Acknowledge" lu sur l'I2C.
CH_maj          EQU     charType.1    ; - Caractere appartient [A..Z] ?
CH_min          EQU     charType.2    ; - Caractere appartient [a..z] ?
CH_hex          EQU     charType.3    ; - Caractere appartient [0..f/F] ?
CH_dec          EQU     charType.4    ; - Caractere appartient [0..9] ?
XXDD_OK         EQU     charType.5    ; - 2 chiffres hexa recus via RS232.
CH_enter        EQU     charType.6    ; - Caractere recu = ENTER.


;******************************************************************************
;******************************************************************************
;******************************************************************************

;----------------------------------------
; Secteur de boot
;----------------------------------------
	ORG		RESET			; Vecteur d'interruption du RESET
	LJMP	init			;Contourner la zone des vecteurs
							; d'interruption...

	ORG        EXTI0        ; Tant que les interruptions ne
	RETI                   	; sont pas utilisees, le code de
	ORG        TIMER0      	; fin d'interruption (RETI) ne sert 
	RETI                   	; a rien ; il est la uniquement �
	ORG        EXTI1       	; titre de precaution...
	RETI                   	; 
	ORG        TIMER1      	; 
	RETI                   	; 
	
	ORG        SINT        	; Routine d'interrution du port  
	LJMP       Int_RX_TX   	; serie 
				; seule interruption
				; utilisee pour l'instant !
	ORG        I2CBUS      	; 
	RETI                   	; 
	ORG        T2CAP0      	; 
	RETI                   	; 
	ORG        T2CAP1      	; 
	RETI                   	; 
	ORG        T2CAP2      	; 
	RETI                   	; 
	ORG        T2CAP3      	; 
	RETI                   	; 
	ORG        ADCONV      	; 
	RETI                   	; 
	ORG        T2CMP0      	; 
	RETI                   	; 
	ORG        T2CMP1      	; 
	RETI                   	; 
	ORG        T2CMP2      	; 
	RETI                   	; 
	ORG        T2OVER      	; 

;----------------------------------------
; Chargement des fonctions annexe
;----------------------------------------
IF TARGET EQ 8060
 $include (inc_8060.a51)	; Fonctions de gestion de l'afficheur et des touches
ELSEIF TARGET EQ 8070
 $include (inc_8070.a51)	; Fonctions de gestion de l'afficheur et des touches
ENDIF

 $include (inc_sys.a51)	; Diverse fonctions systeme
 $include (inc_mem.a51) ; Gestion des cannaux
 $include (inc_ser.a51) ; Gestion du port serie

;----------------------------------------
; Initialisation de bas niveau
;----------------------------------------
init:
	; Initialisation des ports 
	mov	r0,#5dh
	mov	P1,r0
	mov	r0,#0dfh
	mov	P3,r0
	mov	r0,#0ffh
	mov	P5,r0
	mov	r0,#0f9h
	mov	P4,r0

	; Initialisation de la pile
	mov	r0, #sp_default
	mov	SP, r0

	; Initialisation des SFRs
	mov	r0, #80h			; ADC en mode 8 bits
	mov	auxr1, r0
	mov	r0, pwm_freq			; Frequence de la pwm
	mov	pwmp, r0

	; Initialisation des variables
	mov	lcd_dataA0, #0ffh
	mov	lcd_dataA1, #0ffh
	mov	lcd_dataA2, #0ffh
	mov	lcd_dataA3, #0ffh
	mov	lcd_dataB0, #0ffh
	mov	lcd_dataB1, #0ffh
	mov	lcd_dataB2, #0ffh
	mov	lcd_dataB3, #0ffh	

	mov	lock, #00
	mov	vol_hold, #01h 		; Pour etre a peut pres sur de charger le volume au premier lancement
	mov	but_timer, #00
	mov	but_timer2, #0fbh
	mov	disp_hold, #0ffh
	mov	but_hold_state, #0
	mov	but_repeat, #but_long_duration
	
;----------------------------------------
; Initialisation de haut niveau
;----------------------------------------
	call	load_lcd

	; Initialisation du verrou
	mov	serial_latch_lo, #81h
	mov	serial_latch_hi, #31h
	call	load_serial_latch

	; Verifier si un reset est demande
	call	check_buttons			; Charger etat bouton
	cjne	a, #09h, init_no_reset
	call	bip
	call	load_ram_default	 	; reset memory
init_no_reset:

	; Chargement parametre
	call	load_parameters

	; Chargement de l'etat du poste
	call	load_state

	; Chargement du volume
	call	set_volume

	; Initialisation de la liaison serie
	CALL	InitRS232_4800

	call	wdt_reset
	
	; Affichage du canal
	mov	lcd_dataA0, #0h
	mov	lcd_dataA1, #0h
	mov	lcd_dataA2, #0h
	mov	lcd_dataA3, #0h
	mov	lcd_dataB0, #0h
	mov	lcd_dataB1, #0h
	mov	lcd_dataB2, #0h
	mov	lcd_dataB3, #0h	

	call	update_lcd
	
	mov	r7, #0fh

;----------------------------------------
; Boucle RX
;----------------------------------------
m_loop:	

;*** Test du squelch
	call	wdt_reset
	call	squelch

;*** Test de la liaison serie	
	call	TERMINAL		; Passer la main au terminal

;*** Test des boutons
	call	wdt_reset
	call	buttons

;*** Test si Mode erreur synthe (PLL non verouillee)
	jnb	mode.4, m_loop		; Si erreur : boucler

;*** Test TX
	mov	c, P4.0
	orl	c, lock.1		; Test du verroullage TX
	jb	CY, m_notx
	call	tx
m_notx:

;*** Affichage des symboles speciaux
	call	wdt_reset
	call	display_update_symb

;*** Reglage du volume
	call	wdt_reset
	call	set_volume	

;*** Affichage sur le lcd
	call	wdt_reset
	jnb	mode.7, m_end
	call	load_lcd
	clr	mode.7

m_end:
	jmp	m_loop

;----------------------------------------
; Boucle TX
;----------------------------------------
tx:
	; Suppression du squelch si besoin
	jnb	mode.0, tx_cont
	clr	mode.0
	call	update_lcd
	
tx_cont:
	setb	mode.3
	; Affichage du mode
	call	display_update_symb
	call	wdt_reset
	call	load_lcd
	
	
	mov	r0, tx_freq_lo
	mov	r1, tx_freq_hi
	mov	a, #40h
	orl	serial_latch_hi, a
	call	load_serial_latch
	call	load_synth
	
	mov	a, #80h
	orl	serial_latch_hi, a
	call	load_serial_latch
	mov	r0, #0ffh
tx_lp:
	call	wdt_reset
	call	check1750
	call	TERMINAL		; Passer la main au terminal
	jnb	P4.0, tx_lp

	clr	mode.3
	; Affichage du mode
	call	display_update_symb
	call	wdt_reset
	call	load_lcd

	mov	r0, rx_freq_lo
	mov	r1, rx_freq_hi
	mov	a, #3fh
	anl	serial_latch_hi, a
	call	load_serial_latch
	call	load_synth

	ret

IF FREQ EQ 144
$include (inc_144.a51) ; Chargement de la configuration version 144MHz
ELSEIF FREQ EQ 430
$include (inc_430.a51) ; Chargement de la configuration version 430MHz
ENDIF
	end

ENDIF ; IFNDEF TARGET
