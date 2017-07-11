

global lista_crear
global lista_borrar
global lista_concatenar
global lista_ahijar
global lista_imprimir
global lista_filtrar
global lista_colapsar
 
global tiene_ceros_en_decimal
global parte_decimal_mayor_que_un_medio
global tiene_numeros
 
global raiz_cuadrada_del_producto
global raiz_de_la_suma
global revolver_primeras_5
 
global nodo_crear
global lista_colgar_descendiente
 
 
global nodo_borrar_con_hijos
global nodo_acceder
global nodo_concatenar
global lista_filtrar
global lista_colapsar
global tiene_numeros
;sacar de global 
global nodo_borrar

global tiene_ceros_en_decimal
global parte_decimal_mayor_que_un_medio
global raiz_cuadrada_del_producto
global raiz_de_la_suma
global revolver_primeras_5
global raiz_cuadrada_del_producto

 
; auxiliares ...
extern malloc
extern free
extern fopen
extern fprintf
extern fclose
extern fputs
extern fputc
extern sprintf
 
; cambiar las xxx por su valor correspondiente
 
 %define TAM_LISTA 8
 %define TAM_NODO 28 ;16, 8 y 1
 %define TAM_dato_int 4 ; 1byte
 %define TAM_dato_double 8
 %define TAM_puntero 8
 %define TAM_value 8
 %define offset_primero   0
 %define offset_tipo      0
 %define offset_siguiente 4
 %define offset_hijo      12
 %define offset_valor     20
 %define ENUM_int 0
 %define ENUM_double 1
 %define ENUM_string 2
 %define NaN 0x7FE0000000000000 
 
%define NULL 0
 
%define True 1
%define False 0
 
section .data
 
; tegno que definir los caracteres de soparaciòn de lalista, (),.{} etc.
 
llave1:                 DB "{ ", 0        ; DB = Define Byte, defijo de a bytes proque son caracteres, si definiera de a words rellenaría con ceros y terminaría los strings solo. (en Little endian)
llave2:                 DB " }", 0        ; el cero imprime el caracter de fin de string, que luego es interpretado por C.
corchete1:              DB "[", 0
corchete2:              DB "]", 0
espacio:                DB " ", 0
 
fopen_append:   DB "a", 0
 
formato_int:    DB "[ %d ]",0
formato_double: DB "[ %f ]",0
formato_string: DB "[ %s ]",0

vacia:                  DB "<vacia>",0
 
section .text
; ~ lista* lista_crear()
lista_crear:
        push rbp
        mov rbp, rsp
        mov rdi, TAM_LISTA
        call malloc
        mov QWORD [rax + offset_primero], NULL
        pop rbp
;devuelvo por rax
        ret
 
; ~ nodo_t* nodo_crear(tipo_elementos tipo, valor_elemento value)
nodo_crear:
        push rbp
        mov rbp, rsp
;rbx, r12,13,14,15, rbp, rsp
 
        push rdi
        push rsi
 
        ;llamo a malloc con el tamaño del nodo en rdi
        mov rdi, TAM_NODO
        call malloc
        pop rsi
        pop rdi
        mov [rax + offset_tipo], edi
        mov [rax + offset_valor], rsi
        mov QWORD [rax + offset_hijo], NULL
        mov QWORD [rax + offset_siguiente], NULL
        pop rbp
        ret
 
; ~ void lista_borrar(lista *self)
lista_borrar:
        push rbp
        mov rbp, rsp
 
        push rdi
        sub rsp, 8
 
        mov rdi, [rdi + offset_primero]
        call nodo_borrar
 
        add rsp, 8
        pop rdi
 
        call free
        pop rbp
        ret
 
 
 
; ~ void lista_imprimir(lista *self, char *archivo)
lista_imprimir:
        push rbp
        mov rbp, rsp
        push r12
        push r15
        mov r12, rdi
        mov rdi, rsi
        mov  rsi, fopen_append
        call fopen
        mov r15, rax
 
        cmp QWORD [r12 + offset_primero], NULL
        JNE .fin_if
 
        mov rdi, vacia
        mov rsi, r15
        call fputs
        jmp .fin
 
        .fin_if:
        mov r12, [r12 + offset_primero]
 
;puntero a nodo y file stream
;imprimo el primero por separado porque no tiene un espacio adelante.
 
        mov rdi, r12
        mov rsi, r15
        call nodo_imprimir_columna
 
        .while:
                cmp QWORD [r12 + offset_siguiente], NULL
                JE .fin
                mov rdi, espacio
                mov rsi, r15
                call fputs
                mov r12, [r12 + offset_siguiente]
                mov rdi, r12
                mov rsi, r15
                call nodo_imprimir_columna
                jmp .while
 
 
        .fin:

        mov rdi, 10
        mov rsi, r15
        call fputc

        mov rdi, r15
        call fclose
        pop r15
        pop r12
        pop rbp
        ret
 
; ~ void lista_concatenar(lista *self, nodo_t *nodo)
lista_concatenar:
        push rbp
        mov rbp, rsp
        push r12
        sub rsp, 8
        mov r12, rsi
 
        lea rdi, [rdi + offset_primero]
        call nodo_ultimo
       
        mov [rax], r12
       
        add rsp, 8
        pop r12
        pop rbp
        ret
 
; ~ void lista_colgar_descendiente(lista *self, uint posicion, nodo_t *nodo)
lista_colgar_descendiente:
    push rbp
    mov rbp, rsp
    push r12
    sub rsp, 8
    mov r12, rdx
     
    cmp QWORD [rdi + offset_primero], NULL
    JNE .fin_if
    mov rsi, rdx
    call lista_concatenar
    jmp .fin
           
            .fin_if:
            mov rdi, [rdi + offset_primero]
            .while:
                    cmp esi, 0
                    JE .fin_while
                    mov rdi, [rdi + offset_siguiente]
                    dec esi
                    jmp .while
     
        .fin_while:
        call nodo_ultimo_hijo
        mov [rax + offset_hijo], r12
        .fin:
        add rsp, 8
        pop r12
        pop rbp
            ret
     
 
; ~ void lista_filtrar(lista *self, nodo_bool_method method)
lista_filtrar:
;LEAKEA MEMORIA. REVISAR.
        push rbp
        mov rbp, rsp
        push r12 ;rdi = self
        push r13 ;rsi = method
        push r14 ;rax = return from method
        push r15 ;siguiente
 
        mov r12, rdi
        mov r13, rsi
 
        lea r12, [r12 + offset_primero]
 
;ahora r12 tiene el puntero al primer nodo.
; y r13 tiene el puntero al metodo
 
        .loop:
 
                mov rdi, [r12]
                cmp rdi, NULL
                Je .fin
                call r13
;devuelve el resultado por rax, ESPERO.
                cmp rax, True
                JE .borrar
 
                mov rdi, [r12]
                lea r12, [rdi + offset_siguiente]
                jmp .loop
 
        .borrar:
        mov rdi, [r12]
        mov r15, [rdi + offset_siguiente]
 
        call nodo_borrar_con_hijos
        mov [r12], r15
 
        jmp .loop
 
        .fin:
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbp
                ret
 
 
 
; ... funciones auxiliares y adicionales
 
nodo_borrar:
        push rbp
        mov rbp, rsp
        push r12
        sub rsp, 8
 
        cmp rdi, NULL
        je .fin
        mov r12, rdi
 
        mov rdi, [r12 + offset_siguiente]
        call nodo_borrar
 
        mov rdi, [r12 + offset_hijo]
        call nodo_borrar
 
        cmp DWORD [r12 + offset_tipo], ENUM_string
        JNE .free
 
        mov rdi, [r12 + offset_valor]
        call free
 
        .free:
        mov rdi, r12
        call free
 
        .fin:
        add rsp, 8
        pop r12
        pop rbp
        ret
 
nodo_ultimo:
 
        push rbp
        mov rbp, rsp
 
        .loop:
                cmp QWORD [rdi], NULL
                JE .fin
                mov rdi, [rdi]
                add rdi, offset_siguiente
                jmp .loop
 
        .fin:
        mov rax, rdi
        pop rbp
        ret
 
nodo_ultimo_hijo:
 
 
        cmp QWORD [rdi + offset_hijo], NULL
        JE .fin
        mov rdi, [rdi + offset_hijo]
        jmp nodo_ultimo_hijo
 
        .fin:
        mov rax, rdi
        ret
 
;void valor_imprimir(tipo_elementos tipo, valor_elemento valor, FILE *stream)
valor_imprimir:
 
;if (tipo==int){fprintf(stream,"[ %d ]", valor.i)}
;if (tipo==double){fprintf(stream,"[ %f ]", valor.d)}
;if (tipo==string){fprintf(stream,"[ %s ]", valor.s)}
 
        push rbp
        mov rbp, rsp
; aprovecho el orden del enum tipo_elementos
        cmp edi,  ENUM_double
        JL      .imprimir_int
        JG      .imprimir_string
 
        .imprimir_double:
                mov rax, 1
                mov rdi, rdx
                movq xmm0, rsi
                mov rsi, formato_double
                call fprintf
                jmp .fin
 
        .imprimir_string:
                mov rdi, rdx
                mov rdx, rsi
                mov rsi, formato_string
                call fprintf
                jmp .fin
 
        .imprimir_int:
                mov rdi, rdx
                mov rdx, rsi
                mov rsi, formato_int
                call fprintf
                jmp .fin
 
        .fin:
        pop rbp
        ret
 
;void nodo_imprimir_columna(nodo_t *self, FILE *stream)
nodo_imprimir_columna:
 
        push rbp
        mov  rbp, rsp
        push r12 ;<- nodo
        push r13 ;<- stream
 
        mov r12, rdi
        mov r13, rsi
 
        mov rdi, llave1
        call fputs
 
        .imprimir:
        mov edi, [r12 + offset_tipo]
        mov rsi, [r12 + offset_valor]
        mov rdx, r13
        call valor_imprimir
;void valor_imprimir(tipo_elementos tipo, valor_elemento valor, FILE *stream)
        .mover:
        cmp QWORD [r12 + offset_hijo], NULL
        je .fin
        mov r12, [r12 + offset_hijo]
        jmp .imprimir
; VER NODO NULO
 
 
        .fin:
 
        mov rsi, r13
        mov rdi, llave2
        call fputs
 
 
 
        pop r13
        pop r12
        pop rbp
        ret
 
 
nodo_borrar_con_hijos:
        push rbp
        mov rbp, rsp
        push r12
        sub rsp, 8
 
        cmp rdi, NULL
        je .fin
        mov r12, rdi
 
        mov rdi, [r12 + offset_hijo]
        call nodo_borrar_con_hijos
 
        cmp DWORD [r12 + offset_tipo], ENUM_string
        JNE .free
 
        mov rdi, [r12 + offset_valor]
        call free
 
        .free:
        mov rdi, r12
        call free
 
        .fin:
        add rsp, 8
        pop r12
        pop rbp
        ret
     
     
     
;~nodo_t* nodo_acceder(nodo_t *self, uint posicion)
nodo_acceder:
        push rbp
        mov rbp, rsp
        .while:
                cmp esi, 0
                je .fin
                mov rdi, [rdi + offset_siguiente]
                dec rsi
                jmp .while
 
        .fin:
        mov rax, rdi
        pop rbp
        ret
;~void nodo_concatenar(nodo_t **self, nodo_t *siguiente)
nodo_concatenar:
        push rbp
        mov rbp, rsp
 
        mov [rdi], rsi
 
        pop rbp
        ret
 
     
;~Void nodo_colapsar(nodo_t **self_pointer, nodo_value_method join_method)
nodo_colapsar:
ret
 
 
     
     
     
;~boolean tiene_numeros(nodo_t *n)
tiene_numeros:
 
        push rbp
        mov rbp, rsp
        push r12
 
        mov r12, 0
 
        mov rdi, [rdi + offset_valor]
        mov rax, False
 
        .while:
 
                cmp BYTE [rdi], 0
                JE .fin
 
                cmp BYTE [rdi], "0"
                JE .true
 
                cmp BYTE [rdi], "1"
                JE .true
 
                cmp BYTE [rdi], "2"
                JE .true
 
                cmp BYTE [rdi], "3"
                JE .true
 
                cmp BYTE [rdi], "4"
                JE .true
 
                cmp BYTE [rdi], "5"
                JE .true
 
                cmp BYTE [rdi], "6"
                JE .true
 
                cmp BYTE [rdi], "7"
                JE .true
 
                cmp BYTE [rdi], "8"
                JE .true
 
                cmp BYTE [rdi], "9"
                JE .true
 
                jmp .false
 
 
                .false:
                add rdi, 1
                jmp .while
 
 
                .true:
                mov rax, True
                jmp .fin
; tambien podria haber usado is_digit.
 
        .fin:  
        pop r12
        pop rbp
        ret
 
 
 
     
;boolean tiene_ceros_en_decimal(nodo_t *n)
tiene_ceros_en_decimal:
    push rbp
    mov rbp, rsp

    push rdx
    push r13
    push r14
    push r15
    


    mov r12, rdi ;<- valor del nodo argumento
    mov rdi, 100
    call malloc
    mov r13, rax ;<-char *str en r13
    mov rdi, r12

    mov edi, [rdi + offset_valor] ;<- muevo el valor al puntero rdi
    cmp edi, 0
    je .False
;para la catedra el cero es falso

   

    ;preparo para llamar a sprintf

    mov rdi, r13
    mov rsi, formato_int
    mov rdx, r12
    call sprintf

mov r14, 0

.while:
cmp r14, 100
jg .fin_while

cmp BYTE [r13 + r14], NULL
je .fin_while

cmp BYTE [r13 + r14], "0"
je .hay_cero

inc r14

jmp .while
.fin_while:

.False:
mov rdi, r13
call free
mov rax, False
pop r15
pop r14
pop r13
pop rdx
pop rbp
ret

.hay_cero:
mov rdi, r13
call free
mov rax, True
pop r15
pop r14
pop r13
pop rdx
pop rbp
ret

;
;char *str = malloc(100);
;sprintf(str, "%d", nodo->valor);
;
;int i = 0;
;do {
;if (i > 100) break;
;if (str[i] == '\0') break;
;if (str[i] == '0') goto: HAYCERO
;i += 1;
;}
;usar  sprintf
;



;	mov ax, rdi
;	.while:
;	div 10
;	cmp ah, 0
;	je .True
;TERMINAR
;	Signed divide AX by
;r/m
;8, with result stored in:
;AL
;←
;Quotient, AH
;←
;Remainder.
	
	

     
; me creo un arreglo en el que entre un int cualquiera (#digitos del int, 50 chars por ejemplo)
;sprintf(arreglo, "%d", n->valor.i)
     
     
;boolean parte_decimal_mayor_que_un_medio(nodo_t *n)
;    roundps, necesito mover a xmm
parte_decimal_mayor_que_un_medio:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    mov r13, [rdi + offset_valor]
    mov r12, NaN
    and QWORD r13, r12
    cmp r13, r12
    je .menor_a_medio


    pxor xmm3, xmm3
    pxor xmm1, xmm1;<- 0 seteo a cero para no preocuparme por la parte alta.
    pxor xmm2, xmm2;<- 0

    mov rax, rdi
    mov rax, [rax + offset_valor]
    movq xmm2, rax

    roundsd xmm1, xmm2, 00

    comisd xmm2, xmm3 ; comparo con cero (xmm3)
    ja .mayor_a_cero
    jb .menor_a_cero
    je .menor_a_medio

    .mayor_a_cero:
    comisd xmm1, xmm2
    ja .mayor_a_medio
    jb .menor_a_medio
    je .menor_a_medio


    .menor_a_cero:
    comisd xmm1, xmm2
    ja .menor_a_medio
    jb .mayor_a_medio
    je .mayor_a_medio



    .mayor_a_medio:
    mov rax, True
    jmp .fin

    .menor_a_medio:
    mov rax, False
        

    .fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret




;valor_e raiz_cuadrada_del_producto(valor_e valorA, valor_e valorB);
raiz_cuadrada_del_producto:


    push rbp
    mov rbp, rsp

;ahora hago convert de int a double, la parte alta es cero y al convertirla queda en 0
    movsxd rdi, edi
    movsxd rsi, esi

    cvtsi2sd xmm1, rdi
    cvtsi2sd xmm2, rsi

    mulsd xmm1, xmm2;xmm1 <- xmm1*xmm2
    pxor xmm2, xmm2 ;<-0

    comisd xmm1, xmm2 ; comparo con cero el resultado del producto.
    jb .cero
    movq xmm2, xmm1
    pxor xmm1, xmm1
    sqrtsd xmm1, xmm2 ;Computes the root of xmm2/m64 and stores it in xmm1

    cvttsd2si rax, xmm1
    jmp .fin

    .cero:
    mov rax, 0
    jmp .fin

    .fin:
    pop rbp
    ret



;valor_e raiz_de_la_suma(valor_e valorA, valor_e valorB);
raiz_de_la_suma:


    push rbp
    mov rbp, rsp

;ahora hago convert de int a double, la parte alta es cero y al convertirla queda en 0

    movq xmm1, rdi
    movq xmm2, rsi

    addsd xmm1, xmm2;xmm1 <- xmm1*xmm2
    pxor xmm2, xmm2 ;<-0


    movq xmm2, xmm1
    pxor xmm1, xmm1
    sqrtsd xmm1, xmm2 ;Computes the root of xmm2/m64 and stores it in xmm1

    movq rax, xmm1
    jmp .fin

    .fin:
    pop rbp
    ret

;valor_e revolver_primeras_5(valor_e vA, valor_e vB)
revolver_primeras_5:
;Usar tambien al, bl, cl, dl que son de 8 bits.

push rbp               ;armo stack
mov rbp, rsp
push r15
push r14
push r13
push r12



push rdi               ;me los guardo para llamar a malloc
push rsi
mov rdi, 11            ;llamo con 11 = 10 + final_de_string
call malloc ; MALLOC TIRA NULL !!??!!??!!??!!??!!??!!??!!??!!??!!??!!??!!??!!??!!??!!??!!??
mov r15, rax           ;guardo el puntero y restauro los argumentos iniciales
pop rsi
pop rdi
xor r11, r11            ;pongo a cero r11 y r12 para usarlos como indices de str1 y str2
xor r12, r12
xor r13, r13

 .colocar_letra_string1:
cmp byte [rdi+r11], 0        ;me fijo si el string terminó
je .solo_string2             ;y si es así salto al otro

cmp r13, 10                  ;me fijo si ya pase todos los chars
je .fin                      ;y si es así termino

mov byte al, [rdi + r11]
mov byte [r15 + r13], al ;r14     ;hago la copia del char

add r11, 1                   ;indice_string1++
add r13, 1                   ;indice_result++
jmp .colocar_letra_string2   ;salto a colocar la otra letra




 .colocar_letra_string2:
cmp byte [rsi+r12], 0        ;me fijo si el string terminó

je .solo_string1             ;y si es así salto al otro
cmp r13, 10                  ;me fijo si ya pase todos los chars
je .fin                      ;y si es así termino

mov byte al, [rsi + r12]
mov [r15 + r13], al ;r14         ;hago la copia del char

add r12, 1                   ;indice_string2++
add r13, 1                   ;indice_result++
jmp .colocar_letra_string1   ;salto a colocar la otra letra


.solo_string1:

cmp byte [rdi+r11], 0        ;me fijo si el string terminó
je .fin                      ;y si es así salto a .fin

cmp r13, 10                  ;me fijo si ya pase todos los chars
je .fin                      ;y si es así salto a .fin

mov byte al, [rdi + r11]
mov [r15 + r13], al ;r14         ;hago la copia del char

add r11, 1                   ;indice_string1++
add r13, 1                   ;indice_result++
jmp .solo_string1            ;vuelvo a colocar char

.solo_string2:

cmp byte [rsi+r12], 0        ;me fijo si el string terminó
je .fin                      ;y si es así salto a .fin

cmp r13, 10                  ;me fijo si ya pase todos los chars
je .fin                      ;y si es así salto a .fin

mov byte al, [rsi + r12]
mov [r15 + r13], al ;r14         ;hago la copia del char

add r12, 1                   ;indice_string1++
add r13, 1                   ;indice_result++
jmp .solo_string2            ;vuelvo a colocar char


.fin:
mov byte [r15 + r13], 0      ;hago la copia del fin de string
mov rdi, r15
mov rax, r15


pop r12
pop r13
pop r14
pop r15
pop rbp
ret







lista_colapsar:
;void lista_colapsar(lista_colgante_t *self,nodo_bool_method test_method, nodo_value_method join_method)

push rbp;a
mov rbp, rsp

push rbx;d
push r12;a
push r13;d
push r14;a
push r15;d
sub rsp, 8;a

cmp QWORD rdi, NULL
je .fin


;Primero chequeo que la lsita no sea vacía, para opder asignar los valores inciales.
;if primero = null, jmp fin.
cmp QWORD [rdi + offset_primero], NULL
je .fin

;r14 <- abajo

mov r12, rdx                    ;r12 <- join_method
mov r13, rsi                    ;r13 <- test_method
mov r15, rdi
mov r15, [r15 + offset_primero] ;r15 <- actual
mov r14, [r15 + offset_hijo]

.while_afuera:
;while (actual =/ NULL)
cmp r15, NULL
je .fin_while_afuera

mov r14, [r15 + offset_hijo]

;if (test_method(actual) && actual.hijo =/ NULL){
    mov rdi, r15
    call r13
    cmp rax, True
    jne .fin_if
    cmp QWORD [r15 + offset_hijo], NULL
    je .fin_if

    .while_adentro: ;while(abajo=/NULL){
        cmp r14, NULL
        je .fin_while_adentro


        mov rdi, [r15 + offset_valor]
        mov rsi, [r14 + offset_valor]
        call r12

        cmp DWORD [r15 + offset_tipo], ENUM_string ;if(actual.tipo==string){free(actual.valor;)
            jne .fin_if_string
            push rax
            mov rdi, [r15 + offset_valor]

            sub rsp, 8
            call free
            add rsp, 8
            

            pop rax
            .fin_if_string:
    
        mov [r15 + offset_valor], rax

        mov r14, [r14 + offset_hijo]
        jmp .while_adentro
            .fin_while_adentro:

    mov rdi, [r15 + offset_hijo]
    call nodo_borrar_con_hijos
    mov QWORD [r15 + offset_hijo], NULL
    .fin_if:
    mov r15, [r15 + offset_siguiente]
    jmp .while_afuera

        .fin_while_afuera:


.fin:
add rsp, 8
pop r15
pop r14
pop r13
pop r12
pop rbx

pop rbp
ret
