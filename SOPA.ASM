.8086
.model small
.stack 2048h

dseg    segment para public 'data'
        Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
        HandleFich      dw      0
        car_fich        db      ?

		Car			db	32	; Guarda um caracter do Ecran 
		Cor			db	0	; Guarda os atributos de cor do caracter
		POSy		db	1	; a linha pode ir de [1 .. 25]
		POSx		db	2	; POSx pode ir [1..80]	
		top10fich		db		'top10.TXT',0  		; Menu Top10
		Menu_prin		db		'menu.TXT',0  		; Menu Principal
		Fich         	db      'dados.TXT',0  	; Ficheiro Sopa
		Fich2		db      'dados2.TXT', 0
		menuNivelfich   db 		'menu2.TXT',0
		gameOverFich  db  'gameOver.TXT',0

		
		tentativas dw 0
		pontuacao		dw  0					; Guarda a pontuação do jogador
		
		nivel		    dw	1	
		
		POSya			db	3	; posicao anterior de y
		POSxa			db	3	; posicao anterior de x
		
	
		STR12	 	DB 		"            "	; String para 12 digitos	
		STR10			DB		"          "
		NUMERO		DB		"             $" 	; String destinada a guardar o número lido
		NUM_SP		db		"             $" 	; PAra apagar zona de ecran
		DDMMAAAA 	db		"                     "
		Horas		dw		0				; Vai guardar a HORA actual
		Minutos		dw		0				; Vai guardar os minutos actuais
		Segundos	dw		0				; Vai guardar os segundos actuais
		Old_seg		dw		0				; Guarda os últimos segundos que foram lidos
		NUMDIG	db	0	; controla o numero de digitos do numero lido
		MAXDIG	db	4	; Constante que define o numero MAXIMO de digitos a ser aceite
		Tempo_init		dw		0				; Guarda o tempo de inicio do jogo
		Tempo_j			dw		-1				; Guarda o tempo que decorre o jogo
		
		encontradas dw  0
		letrasPRO      dw 0
		letrasINF     dw 0
		letrasASS      dw 0
		letrasASM      dw 0
		letrasTAC      dw 0
		letrasTEC      dw 0
		letrasMOV      dw 0
		letrasISEC      dw 0
		letrasDEIS     dw 0
		letrasCOMP      dw 0
		letrasWORD     DW 0
		letrasBYTE     dw 0

		
		buffer	db	'                             ',13,10
				db 	'                             ',13,10
				db	'                             ',13,10
				db 	'                             ',13,10
				db	'                             ',13,10
				db	'                             ',13,10
				db	'                             ',13,10
				db	'                             ',13,10
				db	'                             ',13,10
				db	'                             ',13,10	
				db	'                             $',13,10
		nomeplayerTEXT	db		"          $"
		introduznome    db	    "Nome do Utilizador:$"
		pntinsufuciente	db	    "Pontuacao Insuficiente, Prima qualquer tecla$"
		vezes      dw 0
		vezesA      dw 49
		vezesS      dw 49
		espacoBranco	db	    " $"

dseg    ends


cseg    segment para public 'code'
		assume  cs:cseg, ds:dseg


;########################################################################
goto_xy	macro	POSx,POSy	; coloca o cursos na posição (POSx,POSy)
		mov		ah,02h
		mov		bh,0		; numero da página
		mov		dl,POSx
		mov		dh,POSy
		int		10h
endm



 ;MOSTRA stringnome - imprime a string
MOSTRA MACRO STR 
	MOV AH,09H
	LEA DX,STR 
	INT 21H
ENDM

;########################################################################
;ROTINA PARA APAGAR ECRAN - Escreve o carecter SPACE em todas as posições do Ecran

apaga_ecran	proc
		xor		bx,bx
		mov		cx,25*80
		
apaga:	mov		byte ptr es:[bx],' '	; Caracter SPACE
		mov		byte ptr es:[bx+1],31	; Caracteristicas de COR
		inc		bx
		inc 	bx
		loop	apaga
		ret
apaga_ecran	endp


;########################################################################
; LE UMA TECLA	 
; Parametros de saida: (al, ah);
; al - código ta tecla premida
; ah=0 => caracter normal ; ah=1 => Tecla Extendida (cursor, F1, F2, etc.)

LE_TECLA	PROC
sem_tecla:
	call Trata_Horas
	MOV	AH,0BH
	INT 21h
	cmp AL,0
	je	sem_tecla
	
	MOV	AH,08H
	INT	21H
	MOV	AH,0
	CMP	AL,0
	JNE	SAI_TECLA
	MOV	AH, 08H
	INT	21H
	MOV	AH,1
SAI_TECLA:	
	RET
LE_TECLA	ENDP

;########################################################################

;########################################################################
; Assinala caracter no ecran	

assinala_P	PROC
	
CICLO:	
		mov di, si
		goto_xy	POSx,POSy	; Vai para nova posição
		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h		
		mov		Car, al		; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah		; Guarda a cor que está na posição do Cursor
		
		goto_xy	78,0		; Mostra o caractereque estava na posição do AVATAR
		mov		ah, 02h		; IMPRIME caracter da posição no canto
		mov		dl, Car	
		int		21H			
	
		goto_xy	POSx,POSy	; Vai para posição do cursor
	
LER_SETA:	
		call 	LE_TECLA
		cmp		ah, 1
		je		ESTEND
		
		CMP 	AL, 27	; ESCAPE para sair do Programa
		JE		FIM
		CMP		AL, 13	; ENTER para alterar a cor do caracter na posicão do cursor
		je		ASSINALA
		jmp		LER_SETA
		
ESTEND:	cmp 	al,48h
		jne		BAIXO
		dec		POSy			;cima
		cmp 	POSy,5
		jb 		limiteSuperior
		jmp		CICLO
		
limiteSuperior:
		cmp 	nivel,1
		jne 	limiteSuperior2
		MOV POSy,15
		jmp CICLO
		
		limiteSuperior2:
		cmp POSy,2
		jnb CICLO
		MOV POSy,15
		jmp CICLO

BAIXO:	cmp		al,50h
		jne		ESQUERDA
		inc 	POSy		;Baixo
		CMP 	POSy,15
		ja 		limiteInferior
		jmp		CICLO
		
limiteInferior:
		CMP     nivel,1
		jne		limiteInferior2
		MOV 	POSy,5
		JMP 	CICLO
		
		limiteInferior2:
		MOV 	POSy,2
		JMP 	CICLO
		

ESQUERDA:
		cmp		al,4Bh
		jne		DIREITA
		dec		POSx		;Esquerda
		dec		POSx		;Esquerda
		CMP 	POSx,2
		Jb 		limiteEsquerdo
		jmp		CICLO
limiteEsquerdo:
		CMP nivel,1
		jne limiteEsquerdo2
		mov POSx, 24
		jmp CICLO
		
		limiteEsquerdo2:
		mov POSx, 32
		jmp CICLO
		

DIREITA:
		cmp		al,4Dh
		jne		LER_SETA 
		inc		POSx		;Direita
		inc		POSx		;Direita
		CMP POSx, 24
		ja limiteDireito
		jmp		CICLO
limiteDireito:
	cmp nivel,1
	jne limiteDireito2
	MOV POSx,2
	jmp CICLO
	
	limiteDireito2:
	CMP POSx, 32
	jna CICLO
	MOV POSx,2
	jmp CICLO
	
	
ASSINALA:
		mov		bl, 15	; BL = character attribute (text) foreground color (graphics)
		;not		bl			; altera a cor
		
		mov		cor, bl		; altera a cor
		mov 	ah, 09h     ; AH = 09 
		mov		al, car		; AL = ASCII character to write
		mov		bh, 0		; BH = display page  (or mode 13h, background pixel value)
		mov		cx, 1		; CX = count of characters to write (CX >= 1)
		int		10h			; INT 10,9 - Write Character and Attribute at Cursor Position
		CMP nivel,1
		je verf1
		jne verf2
		
verf1:
	call verifica
verf2:
	call verifica2

	
fim:	
		RET
assinala_P	endp



;########################################################################

;########################################################################

PRINTDIG PROC          
    mov cx,0
    mov dx,0
	;chama o valor que está no registo
	;divide o valor por 10
	;push o resto para o stack
	;aumenta a contagem
	;repete o número de passos até o valor do registo é maior que 0
	;até o contador ser maior que 0
	;pop do stack
	;adiciona 48 ao elemento mais alto para em ASCII
	;imprime o caracter com uma interrupção
	;decrementa a contagem
	cmp ax,0			; compara se tem zero, mostra apenas zero
	je	exit1
parte1:
    	cmp ax,0		; se ax é zero
        je print1   

        mov bx,10       ; bx inicializado a 10
         
        div bx 			; extrai o ultimo digito
         
        push dx 		; guarda-o na stack
         
        inc cx 			; incrementa o contador
         
        xor dx,dx		; dx a zero
        jmp parte1
print1:
        cmp cx,0		; ver se o contador é zero
        je exit
         
        pop dx 			; pop topo da stack
         
        add dx,48		; adicionar 48 para representar o valor ASCII dos digitos
         
        mov ah,02h		; para dar print
        int 21h
         
        dec cx			; decrementa o contador
        jmp print1

exit1:
		mov dx,'0'
		mov ah,02h
        int 21h
exit:
		mov dx,' '
		mov ah,02h		; para dar print de um espaço no fim caso fique com menos um digito
        int 21h
		RET
PRINTDIG ENDP


;########################################################################
; IMP_FICH
;########################################################################
IMP_FICH	PROC

		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        ;lea     dx,Fich			;Vai-se manualmente carregar o ficheiro que queremos imprimir cada vez que chamarmos a funcao
        int     21h
        jc      erro_abrir
        mov     HandleFich,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleFich
        mov     cx,1
        lea     dx,car_fich
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_fich
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai_f

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai_f:	
		RET
		
IMP_FICH	endp

;########################################################################
; FUNÇAO PARA ACABAR O JOGO
;########################################################################
END_GAME proc
		call		apaga_ecran
        goto_xy 	0,0
		mov			ah,4CH   	
		INT			21H   		
END_GAME endp


;########################################################################
; LE TECLA MENU
;########################################################################
Le_Tecla_Menu	PROC

	nao_ha:	
		mov		ah,0bh
		int		21h
		cmp		al,0
		je		nao_ha ;loop

		mov		ah,08h
		int		21h
		mov		ah,0
		cmp		al,0
		jne		sucesso

		mov		ah, 08h
		int		21h
		mov		ah,1
			
	sucesso:	;sai do loop
		RET

Le_Tecla_Menu	endp



;********************************************************************************
;********************************************************************************	
;-------------------------------------------------------------------
; HOJE - LE DATA DO SISTEMA E COLOCA NUMA STRING NA FORMA DD/MM/AAAA
; CX - ANO, DH - MES, DL - DIA
;-------------------------------------------------------------------
HOJE PROC	

		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		PUSH SI
		PUSHF
		
		MOV AH, 2AH             ; Buscar a data
		INT 21H                 
		PUSH CX                 ; Ano-> PILHA
		XOR CX,CX              	; limpa CX
		MOV CL, DH              ; Mes para CL
		PUSH CX                 ; Mes-> PILHA
		MOV CL, DL				; Dia para CL
		PUSH CX                 ; Dia -> PILHA
		XOR DH,DH                    
		XOR	SI,SI
; DIA ------------------ 
; DX=DX/AX --- RESTO DX   
		XOR DX,DX               ; Limpa DX
		POP AX                  ; Tira dia da pilha
		MOV CX, 0               ; CX = 0 
		MOV BX, 10              ; Divisor
		MOV	CX,2
DD_DIV:                         
		DIV BX                  ; Divide por 10
		PUSH DX                 ; Resto para pilha
		MOV DX, 0               ; Limpa resto
		loop dd_div
		MOV	CX,2
DD_RESTO:
		POP DX                  ; Resto da divisao
		ADD DL, 30h             ; ADD 30h (2) to DL
		MOV DDMMAAAA[SI],DL
		INC	SI
		LOOP DD_RESTO            
		MOV DL, '/'             ; Separador
		MOV DDMMAAAA[SI],DL
		INC SI
; MES -------------------
; DX=DX/AX --- RESTO DX
		MOV DX, 0               ; Limpar DX
		POP AX                  ; Tira mes da pilha
		XOR CX,CX               
		MOV BX, 10				; Divisor
		MOV CX,2
MM_DIV:                         
		DIV BX                  ; Divisao or 10
		PUSH DX                 ; Resto para pilha
		MOV DX, 0               ; Limpa resto
		LOOP MM_DIV
		MOV CX,2 
MM_RESTO:
		POP DX                  ; Resto
		ADD DL, 30h             ; SOMA 30h
		MOV DDMMAAAA[SI],DL
		INC SI		
		LOOP MM_RESTO
		
		MOV DL, '/'             ; Character to display goes in DL
		MOV DDMMAAAA[SI],DL
		INC SI
 
;  ANO ----------------------
		MOV DX, 0               
		POP AX                  ; mes para AX
		MOV CX, 0               ; 
		MOV BX, 10              ; 
 AA_DIV:                         
		DIV BX                   
		PUSH DX                 ; Guarda resto
		ADD CX, 1               ; Soma 1 contador
		MOV DX, 0               ; Limpa resto
		CMP AX, 0               ; Compara quotient com zero
		JNE AA_DIV              ; Se nao zero
AA_RESTO:
		POP DX                  
		ADD DL, 30h             ; ADD 30h (2) to DL
		MOV DDMMAAAA[SI],DL
		INC SI
		LOOP AA_RESTO
		POPF
		POP SI
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
HOJE   ENDP 

Ler_TEMPO PROC	
 
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	PUSHF
	
	MOV AH, 2CH             ; Buscar a hORAS
	INT 21H                 
	
	XOR AX,AX
	MOV AL, DH              ; segundos para al
	mov Segundos, AX		; guarda segundos na variavel correspondente
	
	XOR AX,AX
	MOV AL, CL              ; Minutos para al
	mov Minutos, AX         ; guarda MINUTOS na variavel correspondente
	
	XOR AX,AX
	MOV AL, CH              ; Horas para al
	mov Horas,AX			; guarda HORAS na variavel correspondente

	POPF
	POP DX
	POP CX
	POP BX
	POP AX
	RET 
		
Ler_TEMPO   ENDP 


Trata_Horas PROC

	PUSHF
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX		

	call 	Ler_TEMPO			; Horas, minutos e segundos do Sistema
	
	MOV		AX, Segundos
	cmp		AX, Old_seg			; Verifica se os segundos mudaram desde a ultima leitura
	je		fim_horas			; Se a hora não mudou desde a última leitura sai.
	mov		Old_seg, AX			; Se segundos são diferentes actualiza informação do tempo 
	
	inc 	Tempo_j
	mov		ax, Tempo_j
	mov		cx, Tempo_j
	
	MOV		bl, 10     
	div 	bl
	add 	al, 30h				; Caracter Correspondente às dezenas
	add		ah,	30h
	
	; mov	cx, ax
	; mov	Tempo_j, ax		
	
	MOV 	STR10[0],al			
	MOV 	STR10[1],ah
	MOV 	STR10[2],'$'
	GOTO_XY	7,21
	MOSTRA	STR10 	
	
	; QUANDO ACABA O JOGO
;PARAR O TEMPORIZADOR 
;--------------------------------------------------------|
	cmp		Tempo_j, 99 ; 99 PORQUE O JOGO COMEÇA NO -1  |
	Je voltaMenu										;|
;---------------------------------------------------------
	; HORAS

	mov 	ax,Horas
	MOV		bl, 10     
	div 	bl
	add 	al, 30h				; Caracter Correspondente às dezenas
	add		ah,	30h				; Caracter Correspondente às unidades

	MOV 	STR12[0],al			
	MOV 	STR12[1],ah
	MOV 	STR12[2],'h'
	MOV 	STR12[3],'$'
	GOTO_XY 1,0
	MOSTRA	STR12 	

	; MINUTOS

	mov 	ax,Minutos
	MOV 	bl, 10     
	div 	bl
	add 	al, 30h				; Caracter Correspondente às dezenas
	add		ah,	30h				; Caracter Correspondente às unidades
	MOV 	STR12[0],al			 
	MOV 	STR12[1],ah
	MOV 	STR12[2],'m'		
	MOV 	STR12[3],'$'
	GOTO_XY	5,0
	MOSTRA	STR12 		
	
	; SEGUNDOS

	mov 	ax,Segundos
	MOV 	bl, 10     
	div 	bl
	add 	al, 30h				; Caracter Correspondente às dezenas
	add		ah,	30h				; Caracter Correspondente às unidades
	MOV 	STR12[0],al			 
	MOV 	STR12[1],ah
	MOV 	STR12[2],'s'		
	MOV 	STR12[3],'$'
	GOTO_XY	9,0
	MOSTRA	STR12 

	; a testar os fins	
	
	fimhoras:
		POPF
		POP		DX		
		POP		CX
		POP		BX
		POP		AX
		RET		
		MOV		AH,4Ch
		INT		21h
				
	fim_horas:		
		goto_xy	POSx,POSy			; Volta a colocar o cursor onde estava antes de actualizar as horas
		
		POPF
		POP DX		
		POP CX
		POP BX
		POP AX
		RET	
	voltaMenu:
		goto_xy	POSx,POSy			; Volta a colocar o cursor onde estava antes de actualizar as horas
		call GAMEOVER
		POPF
		POP DX		
		POP CX
		POP BX
		POP AX
		RET		
Trata_Horas ENDP


teclanum  proc
		mov	ax, dseg
		mov	ds,ax
		mov	ax,0B800h
		mov	es,ax		; es é ponteiro para mem video

NOVON:	
		mov		NUMDIG, 0			; inícia leitura de novo número
		mov		cx, 20
		XOR		BX,BX
LIMPA_N: 	
		mov		NUMERO[bx], ' '	
		inc		bx
		loop 	LIMPA_N
		
		mov		al, 20
		mov		POSx,al
		mov		al, 10
		mov		POSy,al				; (POSx,POSy) é posição do cursor
		goto_xy	POSx,POSy
		MOSTRA	NUM_SP	

CICLO:	goto_xy	POSx,POSy
	

		call 	LE_TECLA		; lê uma nova tecla
		cmp		ah,1			; verifica se é tecla extendida
		je		ESTEND
		CMP 	AL,27			; caso seja tecla ESCAPE sai do programa
		JE		FIM
		CMP 	AL,13			; Pressionando ENTER vai para OKNUM
		JE		OKNUM		
		CMP 	AL,8			; Teste BACK SPACE <- (apagar digito)
		JNE		NOBACK
		mov		bl,NUMDIG		; Se Pressionou BACK SPACE 
		CMP		bl,0			; Verifica se não tem digitos no numero
		JE		NOBACK			; se não tem digitos continua então não apaga e salta para NOBACK

		dec		NUMDIG			; Retira um digito (BACK SPACE)
		dec		POSx			; Retira um digito	

		xor		bx,bx
		mov		bl, NUMDIG
		mov		NUMERO[bx],' '	; Retira um digito		
		goto_xy	POSx,POSy
		mov		ah,02h			; imprime SPACE na possicão do cursor
		mov		dl,32			; que equivale a colocar SPACE 
		int		21H

NOBACK:	
		CMP		AL,30h			; se for menor que tecla do ZERO
		jb		CICLO
		CMP		AL,39h			; ou se for maior que tecla do NOVE 
		ja		CICLO			; é rejeitado e vai buscar nova tecla 
		
		mov		bl,MAXDIG		; se atigido numero máximo de digitos ?	
		CMP		bl,NUMDIG	
		jbe		CICLO			; não aceita mais digitos
		xor		Bx, Bx			; caso contrario coloca digito na matriz NUMERO
		mov		bl, NUMDIG
		MOV		NUMERO[bx], al		
		mov		ah,02h			; imprime digito 
		mov		dl,al			; na possicão do cursor
		int		21H

		inc		POSx			; avança o cursor e
		inc		NUMDIG			; incrementa o numero de digitos

ESTEND:	jmp	CICLO			; Tecla extendida não é tratada neste programa 

OKNUM:	goto_xy	20,16
		MOSTRA	NUM_SP			
		goto_xy	20,16		
		xor		bx,bx
		mov		bl, NUMDIG
		inc 	bl
		MOV		NUMERO[bx], '$'			
		MOSTRA	NUMERO 
		jmp		NOVON		; Vai ler novo numero

fim:	ret

teclanum ENDP

ler proc

    mov ah,1
    int 21h
	
ler endp

escreve proc

    mov dl,al
    mov ah,2
    int 21
escreve endp
;########################################################################
	; Introduzir o nome do utilizador top10 
;########################################################################
;AINDA NAO ESTA FUNCIONAL

nplayer proc				
	xor si,si
	mov cx,10					
res_player:							
	inc si						
	loop res_player

	xor si,si
	goto_xy 10,10
	MOSTRA introduznome
	goto_xy 29,10
	

loop1:
    cmp cx,0
    jne lel

    call ler
    call escreve

    mov [bx],dl
    

lel:
	MOV POSx,29
	goto_xy POSx ,10
	MOSTRA nomeplayerTEXT
	inc POSx
	call escreve
sos:
	RET
nplayer endp	




;################################################
;----------- top10 ------------------------------
;################################################

addtop10 proc
	goto_xy 0,0
	call 	apaga_ecran
	cmp		pontuacao,0				; testar se há espaço para o novo jogador
	jbe		naoSuficiente
	ja      suficiente
	
naoSuficiente:
	call	apaga_ecran
	goto_xy 10,10
	MOSTRA	pntinsufuciente
	mov  	ah, 07h 			; Espera para que o utilizador insira um caracter
  	int  	21h
	call	Main

suficiente:
	call 	nplayer
	
	mov		ax,pontuacao

	lea		dx, top10fich
	ret
addtop10 endp


resetplayer proc
	mov bx,0
	mov cx,10
res_player:
	mov				nomeplayerTEXT[bx],' '
	inc				bx
	loop			res_player
	ret
resetplayer endp


;##################################
;	ASSINALA AS PALAVRAS
;######################################

verifica proc	

Inicio:
	mov	ax,0B800h
	mov	es,ax
	goto_xy	POSx,POSy		; Vai para nova posição
	mov ah, 08h			; Guarda o Caracter que está na posição do Cursor
	mov	bh,0			; numero da página
	int	10h			
	mov	Car, al			; Guarda o Caracter que está na posição do Cursr
	mov	Cor, ah			; Guarda a cor que está na posição do Cursor	
	cmp al,65
	je	adicionaA
	cmp al,66
	je  adicionaB
	cmp al,83
	je 	adicionaS
	cmp al,77
	je 	adicionaM
	cmp al, 84
	je 	adicionaT
	cmp al, 69
	je 	adicionaE
	cmp al, 67
	je 	adicionaC
	cmp al, 78
	je 	adicionaN
	cmp al, 79
	je 	adicionaO
	cmp al, 76
	je 	adicionaL
	cmp al, 71
	je adicionaG
	cmp al,73
	je adicionaI
	cmp al,80
	je adicionaP
	cmp al,82
	je adicionaR
	cmp al,86
	je adicionaV
	cmp al,89
	je adicionaY
	CMP AL,68
	je adicionaD
	CMP AL,85
	je adicionaU
	cmp al,70
	je adicionaF
	jne naoConta
	
	
	
;************************************************************
;************************************************************
adicionaF:
	CMP POSy,14
	je selecionaINF
	jne naoConta
	
adicionaU:
	CMP POSy,5
	je selecionaCOMPU
	jne naoConta
adicionaD:
	CMP POSy,5
	je selecionaCOMPUTAD
	jne naoConta
	
adicionaY:
	CMP POSy,13
	JE selecionaASSEMBLY
	jne naoConta
adicionaB:
	CMP POSy,11
	je selecionaASSEMB
	jne naoConta

adicionaV:
	CMP POSY,13
	je selecionaMOV
	jne naoConta
	
adicionaR:
	cmp POSy,14
	je selecionaINFOR
	CMP POSy,5
	je selecionaCOMPUTADOR
	CMP POSy,6
	je selecionaPR
	CMP POSY,9
	JE selecionarPROGR
	jne naoConta
 
adicionaP:
	cmp POSx,24
	je selecionaP
	CMP POSx,8
	je selecionaCOMP
	jne naoConta
	
adicionaI:
	cmp POSy,15
	je selecionaTECNOLOGI
	cmp POSY,14
	je 	repetidasI
	jne naoConta
	
adicionaG:
	cmp POSy,15
	je  selecionaTECNOLOG
	cmp POSy,8
	je  selecionaPROG
	jne naoConta
	
adicionaT:
	cmp POSy,14
	je selecionaINFORMAT
	CMP POSY,5
	JE selecionaCOMPUT
	cmp POSy,15
	je  selecionaT
	cmp POSy,10
	je selecionaT2
	jne naoConta
	
adicionaL:
	cmp POSy,15
	je selecionaTECNOL
	cmp POSx,14
	je selecionaASSEMBL
	jne naoConta

adicionaN:
	cmp POSy,15
	je selecionaTECN
	CMP POSy,14
	je selecionaIN
	jne naoConta

adicionaC:
	cmp POSy,14
	je selecionaINFORMATIC
	cmp POSy, 15
	je selecionaTEC
	cmp Posy, 13
	je selecionaPROGRAMAC
	cmp POSy,10
	je selecionaTAC
	CMP POSY,5
	je selecionaC
	jne naoConta
	
adicionaE:
	cmp POSy,15
	je selecionaTE
	cmp POSy,9
	je selecionaASSE
	jne naoConta
	
adicionaO: 
	cmp POSy,14
	je selecionaINFO
	CMP POSY, 5
	JE repetidasO
	CMP POSy,7
	je selecionaPRO
	cmp POSy,15
	je repetidasO
	cmp POSy,13
	je selecionaMO
	jne naoConta

adicionaA:
	CMP POSY,5
	je selecionaCOMPUTA
	cmp POSy,12
	je  repetidasA
	cmp POSy,15
	je selecionaTECNOLOGIA
	cmp POSy,10
	je repetidasA2
	cmp POSx,24
	je selecionaPROGRAMACA
	CMP POSy,14
	je repetidasA
	cmp POSy,6
	je selecionaA2
	jne naoConta

adicionaS:
	cmp POSy,12
	je selecionaAS
	cmp POSy,15
	je selecionaTECNOLOGIAS
	cmp POSy,7
	je selecionaA2S
	cmp POSy,8
	je selecionaASS
	jne naoConta

adicionaM:
	cmp POSy,14
	je selecionaINFORM
	cmp POSy,5
	je selecionaCOM
	cmp POSy,12
	je selecionaASM
	cmp POSy,11
	je selecionaPROGRAM
	cmp POSy,13
	je selecionaM
	cmp POSy,10
	je selecionaASSEM
	jne naoConta


repetidasA:
	cmp POSx,22
	je selecionaINFORMATICA
	CMP POSx,14
	je selecionaINFORMA
	cmp POSx,4
	je selecionaA
	CMP POSx,24
	JE selecionaPROGRAMA
	jne naoConta
	
repetidasA2:
    cmp POSx,24
	je selecionaPROGRA
	CMP POSx,14
	je selecionaTA
	jne naoConta

		
repetidasO:
	cmp POSx,4
	JE selecionaCO
	cmp POSx, 18
	je selecionaCOMPUTADO
	CMP POSx, 24
	je selecionaPROGRAMACAO
	CMP POSx, 14
	je selecionaTECNOLO
	CMP POSx, 10
	je selecionaTECNO
	jne naoConta
	
repetidasI:
	CMP POSx,2
	je selecionaI
	CMP POSx,18
	je selecionaINFORMATI
	jne naoConta
	
;----------------------------
;*********************************
;********** INFORMATICA **********
selecionaI:
	goto_xy 29,9
	inc letrasINF
	jmp assinala
	
selecionaIN:
	goto_xy 30,9
	inc letrasINF
	JMP assinala

selecionaINF:
	goto_xy 31,9
	inc letrasINF
	jmp assinala

selecionaINFO:
	goto_xy 32,9
	inc letrasINF
	jmp assinala
	
selecionaINFOR:
	goto_xy 33,9
	inc letrasINF
	jmp assinala
	
selecionaINFORM:
	goto_xy 34,9
	inc letrasINF
	jmp assinala
	
selecionaINFORMA:
	goto_xy 35,9
	inc letrasINF
	jmp assinala

selecionaINFORMAT:
	goto_xy 36,9
	inc letrasINF
	jmp assinala
	
selecionaINFORMATI:
	goto_xy 37,9
	inc letrasINF
	jmp assinala

selecionaINFORMATIC:
	inc letrasINF
	goto_xy 38,9
	jmp assinala
	
selecionaINFORMATICA:
	goto_xy 39,9
	inc letrasINF
	jmp assinala
	
;********************************
;********** COMPUTADOR **********
selecionaC:
	goto_xy 29,12
	inc letrasCOMP
	jmp assinala
	
selecionaCO:
	goto_xy 30,12
	inc letrasCOMP
	JMP assinala

selecionaCOM:
	goto_xy 31,12
	inc letrasCOMP
	jmp assinala

selecionaCOMP:
	goto_xy 32,12
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPU:
	goto_xy 33,12
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPUT:
	goto_xy 34,12
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPUTA:
	goto_xy 35,12
	inc letrasCOMP
	jmp assinala

selecionaCOMPUTAD:
	goto_xy 36,12
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPUTADO:
	inc letrasCOMP
	goto_xy 37,12
	jmp assinala

selecionaCOMPUTADOR:
	goto_xy 38,12
	inc letrasCOMP
	jmp assinala
	
;******************************
;********** ASSEMBLY **********
selecionaA2:
	goto_xy 29,7
	inc letrasASS
	jmp assinala
	
selecionaA2S:
	GOTO_XY 30,7
	inc letrasASS
	JMP assinala

selecionaASS:
	goto_xy 31,7
	inc letrasASS
	jmp assinala

selecionaASSE:
	goto_xy 32,7
	inc letrasASS
	jmp assinala
	
selecionaASSEM:
	goto_xy 33,7
	inc letrasASS
	jmp assinala
	
selecionaASSEMB:
	goto_xy 34,7
	inc letrasASS
	jmp assinala
	
selecionaASSEMBL:
	goto_xy 35,7
	inc letrasASS
	jmp assinala

selecionaASSEMBLY:
	goto_xy 36,7
	inc letrasASS
	jmp assinala

;******************************
;********** MOV ***************
selecionaM:
	goto_xy 29,11
	inc letrasMOV
	jmp assinala
	
selecionaMO:
	GOTO_XY 30,11
	inc letrasMOV
	JMP assinala

selecionaMOV:
	goto_xy 31,11
	inc letrasMOV
	jmp assinala

	
;******************************
;********** ASM  **************
selecionaA:
	goto_xy 29,5
	inc letrasASM
	jmp assinala
				
selecionaAS:
	goto_xy 30,5
	inc letrasASM
	jmp assinala
		
selecionaASM:
	goto_xy 31,5
	inc letrasASM
	jmp assinala


;*******************************
;********** TAC  ***************		
selecionaT2:
	goto_xy 29,8
	inc letrasTAC
	jmp assinala
	
selecionaTA:
	GOTO_XY 30,8
	inc letrasTAC
	jmp assinala
	
selecionaTAC:	
	GOTO_XY 31,8
	inc letrasTAC
	jmp assinala


;*************************************
;********** TECNOLOGIAS***************	
selecionaT:
	goto_xy 29,10 
	inc letrasTEC
	jmp assinala
	
selecionaTE:
	goto_xy 30,10
	inc letrasTEC
	jmp assinala

selecionaTEC:
	goto_xy 31,10
	inc letrasTEC
	jMP assinala

selecionaTECN:
	goto_xy 32,10
	inc letrasTEC
	jmp assinala
		
selecionaTECNO:
	goto_xy 33,10
	inc letrasTEC
	jmp assinala

selecionaTECNOL:
	goto_xy 34,10
	inc letrasTEC
	jmp assinala

selecionaTECNOLO:
	goto_xy 35,10
	inc letrasTEC
	jmp assinala

selecionaTECNOLOG:
	goto_xy 36,10
	inc letrasTEC
	jmp assinala

selecionaTECNOLOGI:
	goto_xy 37,10
	inc letrasTEC
	jmp assinala

selecionaTECNOLOGIA:
	goto_xy 38,10
	inc letrasTEC
	jmp assinala
		
selecionaTECNOLOGIAS:
	goto_xy 39,10
	inc letrasTEC
	JMP assinala

	
;*************************************
;********** PROGRAMACAO***************	
selecionaP:
	goto_xy 29,6
	inc letrasPRO
	JMP assinala
	
selecionaPR	:
	goto_xy 30,6
	inc letrasPRO
	JMP assinala
	
selecionaPRO:
	goto_xy 31,6
	inc letrasPRO
	JMP assinala
	
selecionaPROG:
	goto_xy 32,6
	inc letrasPRO
	JMP assinala
	
selecionarPROGR:
	goto_xy 33,6
	inc letrasPRO
	JMP assinala
		
selecionaPROGRA:
	goto_xy 34,6
	inc letrasPRO
	JMP assinala

selecionaPROGRAM:
	goto_xy 35,6
	inc letrasPRO
	JMP assinala
		
selecionaPROGRAMA:
	goto_xy 36,6
	inc letrasPRO
	JMP assinala
		
selecionaPROGRAMAC:
	goto_xy 37,6
	inc letrasPRO
	JMP assinala

selecionaPROGRAMACA:
	goto_xy 38,6
	inc letrasPRO
	JMP assinala

selecionaPROGRAMACAO:
	goto_xy 39,6
	inc letrasPRO
	JMP assinala


assinala:
	mov 	ah, 08h			; Guarda o Caracter que está na posição do Cursor
	mov		bh,0			; numero da página
	int		10h			
	mov		Car, al			; Guarda o Caracter que está na posição do Cursor
	mov		Cor, ah			; Guarda a cor que está na posição do Cursor	
	
	mov		bl, 15		; BL = character attribute (text) foreground color (graphics)
	mov		cor, bl		; altera a cor
	mov 	ah, 09h     ; AH = 09 
	mov		al, car		; AL = ASCII character to write
	mov		bh, 0		; BH = display page  (or mode 13h, background pixel value)
	mov		cx, 1		; CX = count of characters to write (CX >= 1)
	int		10h			; INT 10,9 - Write Character and Attribute at Cursor Position
	ADD pontuacao,5
	goto_xy     12,23
	mov			ax,pontuacao
	call		PRINTDIG
	cmp letrasPRO,11
	je 	cicloEncontraP
	cmp letrasASM,3
	je cicloEncontraASM
	cmp letrasMOV,3
	je cicloEncontraMOV
	cmp letrasTAC,3
	je cicloEncontraTAC
	cmp letrasASS,8
	je cicloEncontraASS
	cmp letrasCOMP,10
	je cicloEncontraCOM
	cmp letrasTEC,11
	je cicloEncontraTEC
	CMP letrasINF,11
	JE cicloEncontraINF
	jmp repetir
	
cicloEncontraP:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasPRO,0
	jmp verificaFIM

cicloEncontraASS:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasASS,0
	jmp verificaFIM
	
cicloEncontraMOV:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasMOV,0
	jmp verificaFIM
	
cicloEncontraTAC:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasTAC,0
	jmp verificaFIM
	
cicloEncontraTEC:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasTEC,0
	jmp verificaFIM
	
cicloEncontraINF:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasINF,0
	jmp verificaFIM
	
cicloEncontraASM:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasASM,0
	jmp verificaFIM
	
cicloEncontraCOM:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasCOMP,0
	jmp verificaFIM
	

verificaFIM:
	CMP encontradas,8
	JNE repetir
	MOV encontradas,0
	mov tentativas,0
	mov pontuacao,0
	call gameOver
		
naoConta:
	inc tentativas
	goto_xy     12,22
	mov			ax,tentativas
	call		PRINTDIG
	
	cmp pontuacao,5
	jb meteZero
	SUB pontuacao,5
	goto_xy     12,23
	mov			ax,pontuacao
	call		PRINTDIG
	
	jmp repetir
	

meteZero:
	mov pontuacao,0
	goto_xy     12,23
	mov			ax,pontuacao
	call		PRINTDIG
	jmp repetir
	
repetir:
	call assinala_P
		
		
verifica endp


;##################################
;	ASSINALA AS PALAVRAS NIVEL 2
;######################################

verifica2 proc	

Inicio:
	mov	ax,0B800h
	mov	es,ax
	goto_xy	POSx,POSy		; Vai para nova posição
	mov ah, 08h			; Guarda o Caracter que está na posição do Cursor
	mov	bh,0			; numero da página
	int	10h			
	mov	Car, al			; Guarda o Caracter que está na posição do Cursr
	mov	Cor, ah			; Guarda a cor que está na posição do Cursor	
	cmp al,65
	je	adicionaA
	cmp al,66
	je  adicionaB
	cmp al,83
	je 	adicionaS
	cmp al,77
	je 	adicionaM
	cmp al, 84
	je 	adicionaT
	cmp al, 69
	je 	adicionaE
	cmp al, 67
	je 	adicionaC
	cmp al, 78
	je 	adicionaN
	cmp al, 79
	je 	adicionaO
	cmp al, 76
	je 	adicionaL
	cmp al, 71
	je adicionaG
	cmp al,73
	je adicionaI
	cmp al,80
	je adicionaP
	cmp al,82
	je adicionaR
	cmp al,86
	je adicionaV
	cmp al,89
	je adicionaY
	CMP AL,68
	je adicionaD
	CMP AL,85
	je adicionaU
	cmp al,70
	je adicionaF
	CMP al,87
	je adicionarW
	
	
	
;************************************************************
;************************************************************
adicionarW:
	CMP POSy,2
	je selecionaW
	jne naoConta
adicionaF:
	CMP POSy,4
	je selecionaINF
	jne naoConta
	
adicionaU:
	CMP POSY,6
	JE selecionaCOMPU
	jne naoConta
adicionaD:
	CMP POSY,9
	JE selecionaCOMPUTAD
	CMP POSy,6
	je selecionaD
	CMP POSy,2
	je selecionaWORD
	jne naoConta
	
adicionaY:
	CMP POSy,11
	je selecionaASSEMBLY
	CMP POSy,15
	je selecionaBY
	jne naoConta

adicionaB:
	CMP POSY,9
	je selecionaASSEMB
	CMP POSy,15
	je selecionaB
	jne naoConta

adicionaV:
	CMP POSy,10
	je selecionaMOV
	jne naoConta
	
adicionaR:
	CMP POSy,3
	je selecionaPR
	CMP POSy,6
	je repetidasR
	CMP POSy,11
	je selecionaCOMPUTADOR
	CMP POSy,2
	je selecionaWOR
	jne naoConta
 
adicionaP:
	cmp posy,2
	je selecionaP
	CMP POSy,5
	je selecionaCOMP
	jne naoConta
	
adicionaI:
	cmp POSy,2
	je selecionaI
	CMP POSy,10
	je selecionaINFORMATI
	CMP POSy,12
	je selecionaTECNOLOGI
	CMP POSy,6
	JE selecionaDEI
	CMP POSy,13
	je selecionaI2
	jne naoConta
	
adicionaG:
	cmp POSy,5
	je selecionaPROG
	CMP POSy,12
	je selecionaTECNOLOG
	jne naoConta
	
adicionaT:
	cmp POSy,9
	je selecionaINFORMAT
	CMP POSy,7
	je selecionaCOMPUT
	CMP POSy,14
	je selecionaT2
	CMP posY,12
	JE selecionaT
	CMP posY,15
	JE selecionaBYT
	jne naoConta
	
adicionaL:
	CMP POSy,10
	je selecionaASSEMBL
	CMP POSy,12
	je selecionaTECNOL
	jne naoConta

adicionaN:
	CMP POSy,3
	je selecionaIN
	CMP POSy,12
	je selecionaTECN
	jne naoConta

adicionaC:
	CMP POSy,11
	JE selecionaINFORMATIC
	cmp POSY,2
	JE selecionaC
	CMP POSY,14
	je selecionaTAC
	CMP POSy,12
	je selecionaTEC
	CMP POSy,10
	je selecionaPROGRAMAC
	CMP POSy,13
	je selecionaISEC
	jne naoConta
	
adicionaE:
	CMP POSy,7
	je selecionaASSE
	CMP POSy,12
	je selecionaTE
	CMP POSy,6
	je selecionaDE
	CMP POSy,13
	je selecionaISE
	CMP POSy,15
	je selecionaBYTE
	jne naoConta
	
adicionaO: 
	cmp POSy,4
	je selecionaPRO
	cmp POSy,5
	je selecionaINFO
	CMP POSy,3
	je selecionaCO
	CMP POSy,10
	je repetidasO
	CMP POSy,12
	je repetidasO2
	CMP POSy, 2
	je selecionaWO
	jne naoConta

adicionaA:
	CMP POSy,8
	je repetidasA2
	CMP POSy,12
	je repetidasA
	CMP POSy,4
	je selecionaA2
	CMP POSy,15
	je selecionaA
	CMP POSy,14
	je selecionaTA
	CMP POSy,7
	JE selecionaPROGRA
	CMP POSy,9
	JE selecionaPROGRAMA
	CMP POSy,11
	JE selecionaPROGRAMACA
	
	jne naoConta

adicionaS:
	CMP POSy,5
	JE selecionaA2S
	cmp POSy,6
	je repetidasS
	CMP POSy,15
	je selecionaAS
	CMP POSy,12
	je selecionaTECNOLOGIAS
	CMP POSy,13
	je selecionaIS
	jne naoConta

adicionaM:
	CMP POSy,7
	je selecionaINFORM
	CMP POSy,4
	je selecionaCOM
	CMP POSy,8
	je repetidasM
	CMP POSy,10
	je selecionaM
	CMP POSy,15
	je selecionaASM
	jne naoConta
	
repetidasM:
	CMP POSx,2
	je selecionaASSEM
	CMP POSx,24
	je selecionaPROGRAM
	jne naoConta
	
repetidasR:
	CMP POSx,32
	je selecionaINFOR
	CMP POSx,24
	je selecionaPROGR
	jne naoConta

repetidasS:
	CMP POSx,2
	je selecionaASS
	CMP POSx,20
	je selecionaDEIS
	jne naoConta
	
repetidasA:
	CMP POSX,20
	JE selecionaTECNOLOGIA
	cmp POSx,32
	je selecionaINFORMATICA
	jne naoConta
	
repetidasA2:
	cmp POSx,32
	je selecionaINFORMA
	CMP POSx,14
	je selecionaCOMPUTA
	jne naoConta

		
repetidasO:
	CMP POSx,10
	je selecionaMO
	CMP POSx,18
	je selecionaCOMPUTADO
	jne naoConta
	
repetidasO2:
	cmp POSx,10
	je selecionaTECNO
	CMP POSx,14
	je selecionaTECNOLO
	CMP POSx,24
	je selecionaPROGRAMACAO
	jne naoConta
	
	
;----------------------------
;*********************************
;********** INFORMATICA **********
selecionaI:
	goto_xy 37,8
	inc letrasINF
	jmp assinala
	
selecionaIN:
	goto_xy 38,8
	inc letrasINF
	JMP assinala

selecionaINF:
	goto_xy 39,8
	inc letrasINF
	jmp assinala

selecionaINFO:
	goto_xy 40,8
	inc letrasINF
	jmp assinala
	
selecionaINFOR:
	goto_xy 41,8
	inc letrasINF
	jmp assinala
	
selecionaINFORM:
	goto_xy 42,8
	inc letrasINF
	jmp assinala
	
selecionaINFORMA:
	goto_xy 43,8
	inc letrasINF
	jmp assinala

selecionaINFORMAT:
	goto_xy 44,8
	inc letrasINF
	jmp assinala
	
selecionaINFORMATI:
	goto_xy 45,8
	inc letrasINF
	jmp assinala

selecionaINFORMATIC:
	goto_xy 46,8
	inc letrasINF
	jmp assinala
	
selecionaINFORMATICA:
	
	goto_xy 47,8
	inc letrasINF
	jmp assinala
	

	
;********************************
;********** COMPUTADOR **********
selecionaC:
	goto_xy 37,3
	inc letrasCOMP
	jmp assinala
	
selecionaCO:
	goto_xy 38,3
	inc letrasCOMP
	JMP assinala

selecionaCOM:
	goto_xy 39,3
	inc letrasCOMP
	jmp assinala

selecionaCOMP:
	goto_xy 40,3
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPU:
	goto_xy 41,3
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPUT:
	goto_xy 42,3
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPUTA:
	goto_xy 43,3
	inc letrasCOMP
	jmp assinala

selecionaCOMPUTAD:
	goto_xy 44,3
	inc letrasCOMP
	jmp assinala
	
selecionaCOMPUTADO:
	goto_xy 45,3
	inc letrasCOMP
	jmp assinala

selecionaCOMPUTADOR:
	goto_xy 46,3
	inc letrasCOMP
	jmp assinala
	
;******************************
;********** ASSEMBLY **********
selecionaA2:
	goto_xy 37,7
	inc letrasASS
	jmp assinala
	
selecionaA2S:
	GOTO_XY 38,7
	inc letrasASS
	JMP assinala

selecionaASS:
	goto_xy 39,7
	inc letrasASS
	jmp assinala

selecionaASSE:
	goto_xy 40,7
	inc letrasASS
	jmp assinala
	
selecionaASSEM:
	goto_xy 41,7
	inc letrasASS
	jmp assinala
	
selecionaASSEMB:
	goto_xy 42,7
	inc letrasASS
	jmp assinala
	
selecionaASSEMBL:
	goto_xy 43,7
	inc letrasASS
	jmp assinala

selecionaASSEMBLY:
	goto_xy 44,7
	inc letrasASS
	jmp assinala

;********************************
;**********  MOV  ***************
selecionaM:
	goto_xy 37,4
	inc letrasMOV
	jmp assinala
	
selecionaMO:
	GOTO_XY 38,4
	inc letrasMOV
	JMP assinala

selecionaMOV:
	goto_xy 39,4
	inc letrasMOV
	jmp assinala

	
;******************************
;********** ASM  **************
selecionaA:
	goto_xy 37,2
	inc letrasASM
	jmp assinala
				
selecionaAS:
	goto_xy 38,2
	inc letrasASM
	jmp assinala
		
selecionaASM:
	goto_xy 39,2
	inc letrasASM
	jmp assinala


;*******************************
;********** TAC  ***************		
selecionaT2:
	goto_xy 37,9
	inc letrasTAC
	jmp assinala
	
selecionaTA:
	GOTO_XY 38,9
	inc letrasTAC
	jmp assinala
	
selecionaTAC:
	GOTO_XY 39,9
	inc letrasTAC
	jmp assinala


;*************************************
;********** TECNOLOGIAS***************	
selecionaT:
	goto_xy 37,6 
	inc letrasTEC
	jmp assinala
	
selecionaTE:
	goto_xy 38,6
	inc letrasTEC
	jmp assinala

selecionaTEC:
	goto_xy 39,6
	inc letrasTEC
	jMP assinala

selecionaTECN:
	goto_xy 40,6
	inc letrasTEC
	jmp assinala
		
selecionaTECNO:
	goto_xy 41,6
	inc letrasTEC
	jmp assinala

selecionaTECNOL:
	goto_xy 42,6
	inc letrasTEC
	jmp assinala

selecionaTECNOLO:
	goto_xy 43,6
	inc letrasTEC
	jmp assinala

selecionaTECNOLOG:
	goto_xy 44,6
	inc letrasTEC
	jmp assinala

selecionaTECNOLOGI:
	goto_xy 45,6
	inc letrasTEC
	jmp assinala

selecionaTECNOLOGIA:
	goto_xy 46,6
	inc letrasTEC
	jmp assinala
		
selecionaTECNOLOGIAS:
	goto_xy 47,6
	inc letrasTEC
	JMP assinala

	
;*************************************
;********** PROGRAMACAO***************	
selecionaP:
	goto_xy 37,5
	inc letrasPRO
	JMP assinala
	
selecionaPR	:
	goto_xy 38,5
	inc letrasPRO
	JMP assinala
	
selecionaPRO:
	goto_xy 39,5
	inc letrasPRO
	JMP assinala
	
selecionaPROG:
	goto_xy 40,5
	inc letrasPRO
	JMP assinala
	
selecionaPROGR:
	goto_xy 41,5
	inc letrasPRO
	JMP assinala
		
selecionaPROGRA:
	goto_xy 42,5
	inc letrasPRO
	JMP assinala

selecionaPROGRAM:
	goto_xy 43,5
	inc letrasPRO
	JMP assinala
		
selecionaPROGRAMA:
	goto_xy 44,5
	inc letrasPRO
	JMP assinala
		
selecionaPROGRAMAC:
	goto_xy 45,5
	inc letrasPRO
	JMP assinala

selecionaPROGRAMACA:
	goto_xy 46,5
	inc letrasPRO
	JMP assinala

selecionaPROGRAMACAO:
	goto_xy 47,5
	inc letrasPRO
	JMP assinala

;*******************************
;********** DEIS***************		
selecionaD:
	goto_xy 37,10
	inc letrasDEIS
	jmp assinala
	
selecionaDE:
	GOTO_XY 38,10
	inc letrasDEIS
	jmp assinala
	
selecionaDEI:
	GOTO_XY 39,10
	inc letrasDEIS
	jmp assinala
	
selecionaDEIS:
	GOTO_XY 40,10
	inc letrasDEIS
	jmp assinala
	

;*******************************
;********** ISEC ***************		
selecionaI2:
	goto_xy 37,11
	inc letrasISEC
	jmp assinala
	
selecionaIS:
	GOTO_XY 38,11
	inc letrasISEC
	jmp assinala
	
selecionaISE:
	GOTO_XY 39,11
	inc letrasISEC
	jmp assinala
	
selecionaISEC:
	GOTO_XY 40,11
	inc letrasISEC
	jmp assinala
	
;*******************************
;********** BYTE ***************		
selecionaB:
	goto_xy 37,12
	inc letrasBYTE
	jmp assinala
	
selecionaBY:
	GOTO_XY 38,12
	inc letrasBYTE
	jmp assinala
	
selecionaBYT:
	GOTO_XY 39,12
	inc letrasBYTE
	jmp assinala
	
selecionaBYTE:
	GOTO_XY 40,12
	inc letrasBYTE
	jmp assinala
	
;*******************************
;********** WORD ***************		
selecionaW:
	goto_xy 37,13
	inc letrasWORD
	jmp assinala
	
selecionaWO:
	GOTO_XY 38,13
	inc letrasWORD
	jmp assinala
	
selecionaWOR:
	GOTO_XY 39,13
	inc letrasWORD
	jmp assinala
	
selecionaWORD:
	GOTO_XY 40,13
	inc letrasWORD
	jmp assinala


assinala:
	mov 	ah, 08h			; Guarda o Caracter que está na posição do Cursor
	mov		bh,0			; numero da página
	int		10h			
	mov		Car, al			; Guarda o Caracter que está na posição do Cursor
	mov		Cor, ah			; Guarda a cor que está na posição do Cursor	
	
	mov		bl, 15		; BL = character attribute (text) foreground color (graphics)
	mov		cor, bl		; altera a cor
	mov 	ah, 09h     ; AH = 09 
	mov		al, car		; AL = ASCII character to write
	mov		bh, 0		; BH = display page  (or mode 13h, background pixel value)
	mov		cx, 1		; CX = count of characters to write (CX >= 1)
	int		10h			; INT 10,9 - Write Character and Attribute at Cursor Position
	ADD pontuacao,5
	goto_xy     12,23
	mov			ax,pontuacao
	call		PRINTDIG
	cmp letrasPRO,11
	je 	cicloEncontraP
	cmp letrasASM,3
	je cicloEncontraASM
	cmp letrasMOV,3
	je cicloEncontraMOV
	cmp letrasTAC,3
	je cicloEncontraTAC
	cmp letrasASS,8
	je cicloEncontraASS
	cmp letrasCOMP,10
	je cicloEncontraCOM
	cmp letrasTEC,11
	je cicloEncontraTEC
	CMP letrasINF,11
	JE cicloEncontraINF
	cmp letrasDEIS,4
	JE cicloEncontraDEIS
	CMP letrasISEC,4
	je cicloEncontraISEC
	cmp letrasBYTE,4
	JE cicloEncontraBYTE
	CMP letrasWORD,4
	je cicloEncontraWORD
	jmp fim
	
cicloEncontraP:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasPRO,0
	jmp verificaFIM

cicloEncontraASS:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasASS,0
	jmp verificaFIM
	
cicloEncontraMOV:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasMOV,0
	jmp verificaFIM
	
cicloEncontraTAC:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasTAC,0
	jmp verificaFIM
	
cicloEncontraTEC:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasTEC,0
	jmp verificaFIM
	
cicloEncontraINF:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasINF,0
	jmp verificaFIM
	
cicloEncontraASM:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasASM,0
	jmp verificaFIM
	
cicloEncontraCOM:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasCOMP,0
	jmp verificaFIM
	
cicloEncontraDEIS:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasDEIS,0
	jmp verificaFIM
	
cicloEncontraISEC:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasISEC,0
	jmp verificaFIM
	
cicloEncontraBYTE:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasBYTE,0
	jmp verificaFIM
	
cicloEncontraWORD:
	add encontradas,1
	goto_xy     54,22
	mov			ax,encontradas
	call		PRINTDIG
	mov letrasWORD,0
	jmp verificaFIM
	

verificaFIM:
	CMP encontradas,12
	JNE fim
	MOV encontradas,0
	mov tentativas,0
	mov pontuacao,0
	call gameOver
		

naoConta:
	inc tentativas
	goto_xy     12,22
	mov			ax,tentativas
	call		PRINTDIG
	cmp pontuacao,5
	jb meteZero
	SUB pontuacao,5
	goto_xy     12,23
	mov			ax,pontuacao
	call		PRINTDIG
	jmp fim
	

meteZero:
	mov pontuacao,0
	goto_xy     12,23
	mov			ax,pontuacao
	call		PRINTDIG
	jmp fim
	
fim:
	call assinala_P
		
		
verifica2 endp

;################################################
;----------- GAMEOVER------------------------------
;################################################

GAMEOVER proc
	mov 		tentativas,0
	mov			pontuacao,0
	call		apaga_ecran
	goto_xy		0,0
	lea			dx,gameOverFich  		; carregar para dx o ficheiro que queremos imprimir
	call 		IMP_FICH   			; imprimir o ficheiro
	
	mov ah,07h
	int 21h
	cmp al,'1'
	je MENU
	cmp al,'2'
	je sair
	
sair:
call END_GAME


GAMEOVER endp


;################################################
;----------- MENU ------------------------------
;################################################
Menu proc
	call		apaga_ecran
	goto_xy		0,0
	lea			dx,Menu_prin  		; carregar para dx o ficheiro que queremos imprimir
	call 		IMP_FICH   			; imprimir o ficheiro

	mov  ah, 07h 					
  	int  21h
  	cmp  al, '1' 					
	je menuNiveis
  	cmp  al, '2' 					
  	je   top10 						
	cmp  al, '3' 				
	je  sair 						
	jmp Menu 						
;-----------------------		
top10:
	call	apaga_ecran
	goto_xy 0,0
	lea  	dx, top10fich   		
    call 	IMP_FICH   

	mov  	ah, 07h 				
  	int  	21h
	JMP MENU

;-----------------------
sair:
	call 	END_GAME

;-----------------------
menuNiveis:

	call	apaga_ecran
	goto_xy 0,0
	lea  	dx, menuNivelfich 		
    call 	IMP_FICH
	call 	Le_Tecla_Menu
	
	mov  ah, 07h 					
  	int  21h
	
	cmp 	al, '1' 
	je		OPCnivel1
	cmp 	al, '2'
	je      OPCnivel2
	
	OPCnivel1:
	jmp nivel1

	OPCnivel2:
	jmp nivel2
	call	Main

;-----------------------	
nivel1:
	goto_xy 	8,0
	mov     ax,dseg
	mov		ax,0b800h

	call		apaga_ecran
	call        Trata_Horas
	goto_xy	    0,2				
	lea 		dx, fich
	call     	imp_fich
	
	mov POSx, 4
	mov POSy,9
	goto_xy POSx, POSY
	
	mov         Tempo_j,0
	
	mov 		nivel,1
	goto_xy     54,21
	mov			ax,nivel
	call		PRINTDIG

	goto_xy     12,22
	mov			ax,pontuacao
	call		PRINTDIG
	
	mov pontuacao,0
	mov tentativas,0
	mov encontradas,0
	call	    assinala_p
	
	call		main

;-----------------------	
;-----------------------
nivel2:
	
	mov         ax,dseg
	mov		    ax,0b800h
	
	call		apaga_ecran
	goto_xy		0,0
	call        Trata_Horas
		
	lea  		dx, Fich2
	call 		imp_fich
	mov         Tempo_j,0
	mov nivel,2
	goto_xy     54,21
	mov			ax,nivel
	call		PRINTDIG

	goto_xy     12,23
	mov			ax,pontuacao
	call		PRINTDIG
	
	mov pontuacao,0
	mov tentativas,0
	mov encontradas,0
	call	    assinala_p
	call        main	
	
MENU ENDP

;########################################################################
;----------- MAIN------------------------------
;########################################################################
Main  proc
		
		mov			ax, dseg
		mov			ds,ax
		
		mov			ax,0B800h
		mov			es,ax
		call MENU
	
Main	endp
cseg	ends
end     Main           

