%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
int yyerror(char *s);

extern FILE *yyin;
extern int num_linea; // Referencia a la variable de scanner.l

#define MAX_SIMB 300
#define TIPO_VAR 0
#define TIPO_FUNC 1
#define TIPO_MACRO 2
#define TIPO_INT 0

typedef struct {
    char *nombre;
    int clase;
    int tipo_dato;
    int aridad;
    int ambito;
    int activo;
    int usado; // NUEVO: Campo para variables no usadas
} Simbolo;

Simbolo tabla[MAX_SIMB];

int ntabla = 0;
int ambito_actual = 0;
int semantic_errors = 0;

// MEJORA: Mensaje de error sintactico incluye numero de linea
int yyerror(char *s) {
    printf("Error sintáctico en línea %d. %s\n", num_linea, s);
    return 0;
}

void entrar_ambito() {
    ambito_actual++;
}

void salir_ambito() {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].ambito == ambito_actual) {
            tabla[i].activo = 0;
        }
    }
    ambito_actual--;
}

int existe_en_ambito_actual(char *id) {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].activo &&
            tabla[i].ambito == ambito_actual &&
            strcmp(tabla[i].nombre, id) == 0) {
            return 1;
        }
    }
    return 0;
}

int existe_global(char *id, int clase) {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].activo &&
            tabla[i].ambito == 0 &&
            tabla[i].clase == clase &&
            strcmp(tabla[i].nombre, id) == 0) {
            return 1;
        }
    }
    return 0;
}

// Inicializamos el campo 'usado' en 0 al agregar variables
void agregar_variable(char *id, int tipo_dato) {
    if (existe_en_ambito_actual(id)) {
        printf("Error semántico: redeclaración de variable '%s'\n", id);
        semantic_errors++;
        return;
    }
    tabla[ntabla++] = (Simbolo){strdup(id), TIPO_VAR, tipo_dato, 0, ambito_actual, 1, 0};
}

void agregar_macro(char *id) {
    if (existe_global(id, TIPO_MACRO)) {
        printf("Error semántico: macro '%s' ya definida\n", id);
        semantic_errors++;
        return;
    }
    tabla[ntabla++] = (Simbolo){strdup(id), TIPO_MACRO, TIPO_INT, 0, 0, 1, 0};
}

void agregar_funcion(char *id, int aridad) {
    if (existe_global(id, TIPO_FUNC)) {
        printf("Error semántico: función '%s' ya declarada\n", id);
        semantic_errors++;
        return;
    }
    tabla[ntabla++] = (Simbolo){strdup(id), TIPO_FUNC, TIPO_INT, aridad, 0, 1, 0};
}

int buscar_tipo_variable(char *id) {
    for (int a = ambito_actual; a >= 0; a--) {
        for (int i = ntabla - 1; i >= 0; i--) {
            if (tabla[i].activo &&
                tabla[i].clase == TIPO_VAR &&
                tabla[i].ambito == a &&
                strcmp(tabla[i].nombre, id) == 0) {
                return tabla[i].tipo_dato;
            }
        }
    }
    return -1;
}

int buscar_aridad_funcion(char *id) {
    for (int i = 0; i < ntabla; i++) {
        if (tabla[i].activo &&
            tabla[i].clase == TIPO_FUNC &&
            strcmp(tabla[i].nombre, id) == 0) {
            return tabla[i].aridad;
        }
    }
    return -1;
}

// Helper para marcar una variable como usada en la tabla
void marcar_usada(char *id) {
    for (int a = ambito_actual; a >= 0; a--) {
        for (int i = ntabla - 1; i >= 0; i--) {
            if (tabla[i].activo && tabla[i].clase == TIPO_VAR &&
                tabla[i].ambito == a && strcmp(tabla[i].nombre, id) == 0) {
                tabla[i].usado = 1;
                return;
            }
        }
    }
}

// MEJORA: Mensaje de error incluye linea
void verificar_uso_variable(char *id) {
    if (buscar_tipo_variable(id) == -1) {
        printf("Error semántico en línea %d: variable '%s' no declarada\n", num_linea, id);
        semantic_errors++;
    } else {
        marcar_usada(id); // Si existe, la marcamos como usada
    }
}

void verificar_variable_declarada(char *id) {
    if (buscar_tipo_variable(id) == -1) {
        printf("Error semántico en línea %d: variable '%s' no declarada\n", num_linea, id);
        semantic_errors++;
    }
}

void verificar_llamada_funcion(char *id, int argumentos) {
    int esperados = buscar_aridad_funcion(id);
    if (esperados == -1) {
        printf("Error semántico: función '%s' no declarada\n", id);
        semantic_errors++;
        return;
    }

    if (esperados != argumentos) {
        printf("Error semántico: función '%s' espera %d argumento(s), pero recibió %d\n",
               id, esperados, argumentos);
        semantic_errors++;
    }
}

// Funciones nuevas para entregar la salida del punto 7.1 y 7.2
void verificar_no_usadas() {
    for(int i = 0; i < ntabla; i++) {
        if (tabla[i].clase == TIPO_VAR && tabla[i].usado == 0) {
            printf("Advertencia: variable '%s' declarada pero no usada\n", tabla[i].nombre);
        }
    }
}

void imprimir_tabla() {
    printf("\nThe following table:\n");
    printf("+----------+----------+------+--------+--------+\n");
    printf("| Nombre   | Clase    | Tipo | Ámbito | Aridad |\n");
    printf("+----------+----------+------+--------+--------+\n");
    for(int i=0; i<ntabla; i++) {
        char* clase_str = (tabla[i].clase == TIPO_VAR) ? "variable" : (tabla[i].clase == TIPO_FUNC) ? "función" : "macro";
        char* tipo_str = "int"; 
        
        char ambito_str[10];
        if(tabla[i].ambito == 0) strcpy(ambito_str, "global");
        else sprintf(ambito_str, "%d", tabla[i].ambito);

        char aridad_str[10] = "-";
        if(tabla[i].clase == TIPO_FUNC) sprintf(aridad_str, "%d", tabla[i].aridad);

        printf("| %-8s | %-8s | %-4s | %-6s | %-6s |\n",
               tabla[i].nombre, clase_str, tipo_str, ambito_str, aridad_str);
    }
    printf("+----------+----------+------+--------+--------+\n");
}
%}

%union {
    char *str;
    int num;
}

%token <str> ID
%token <str> STRING_LITERAL
%token <str> NUMBER

%token INCLUDE DEFINE
%token INT FUNC RETURN IGUAL IF
%token PARIZQ PARDER LLAVEIZQ LLAVEDER PUNTOYCOMA COMA
%token MENOR MAYOR PUNTO
%token MAS MENOS MULT DIV

%type <num> parametros
%type <num> lista_param
%type <num> argumentos
%type <num> lista_args

%%

programa:
      preprocesador declaraciones
      {
          verificar_no_usadas();
          if (semantic_errors == 0) {
              printf("Análisis completado sin errores semánticos.\n");
          } else {
              printf("Análisis completado con %d error(es) semántico(s).\n", semantic_errors);
          }
          imprimir_tabla();
      }
    ;

preprocesador:
      preprocesador directiva
    |
    ;

directiva:
      include
    | define
    ;

include:
      INCLUDE MENOR ID MAYOR
    | INCLUDE MENOR ID PUNTO ID MAYOR
    | INCLUDE STRING_LITERAL
    ;

define:
      DEFINE ID NUMBER { agregar_macro($2); }
    | DEFINE ID ID { agregar_macro($2); }
    | DEFINE ID STRING_LITERAL { agregar_macro($2); }
    | DEFINE ID { agregar_macro($2); }
    ;

declaraciones:
      declaracion
    | declaraciones declaracion
    ;

declaracion:
      INT ID PUNTOYCOMA { agregar_variable($2, TIPO_INT); }
    | FUNC ID PARIZQ { agregar_funcion($2, -1); entrar_ambito(); }
      parametros PARDER bloque_funcion
      {
          int aridad = $5;
          for (int i = 0; i < ntabla; i++) {
              if (tabla[i].activo &&
                  tabla[i].clase == TIPO_FUNC &&
                  strcmp(tabla[i].nombre, $2) == 0) {
                  tabla[i].aridad = aridad;
                  break;
              }
          }
          salir_ambito();
      }
    ;

parametros:
      { $$ = 0; }
    | lista_param { $$ = $1; }
    ;

lista_param:
      ID { agregar_variable($1, TIPO_INT); $$ = 1; }
    | lista_param COMA ID { agregar_variable($3, TIPO_INT); $$ = $1 + 1; }
    ;

bloque_funcion:
      LLAVEIZQ instrucciones LLAVEDER
    ;

bloque:
      LLAVEIZQ { entrar_ambito(); } instrucciones LLAVEDER { salir_ambito(); }
    ;

instrucciones:
      instrucciones instruccion
    |
    ;

instruccion:
      INT ID PUNTOYCOMA { agregar_variable($2, TIPO_INT); }
    | ID IGUAL expresion PUNTOYCOMA { verificar_variable_declarada($1); }
    | ID PARIZQ argumentos PARDER PUNTOYCOMA { verificar_llamada_funcion($1, $3); }
    | RETURN ID PUNTOYCOMA { verificar_uso_variable($2); }
    | IF PARIZQ ID PARDER bloque { verificar_uso_variable($3); }
    | bloque
    ;

// NUEVO: Reglas para soportar expresiones matematicas simples 
expresion:
      ID { verificar_uso_variable($1); }
    | ID MAS ID { verificar_uso_variable($1); verificar_uso_variable($3); }
    | ID MENOS ID { verificar_uso_variable($1); verificar_uso_variable($3); }
    | ID MULT ID { verificar_uso_variable($1); verificar_uso_variable($3); }
    | ID DIV ID { verificar_uso_variable($1); verificar_uso_variable($3); }
    ;

argumentos:
      { $$ = 0; }
    | lista_args { $$ = $1; }
    ;

lista_args:
      ID { verificar_uso_variable($1); $$ = 1; }
    | lista_args COMA ID { verificar_uso_variable($3); $$ = $1 + 1; }
    ;

%%

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Uso: %s archivo_fuente\n", argv[0]);
        return EXIT_FAILURE;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        printf("Error: no se pudo abrir el archivo '%s'\n", argv[1]);
        return EXIT_FAILURE;
    }

    yyparse();

    fclose(yyin);

    return semantic_errors == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}