#include <iostream>
#include <string>
#include <vector>
using namespace std;

//estos son los tokens que el analizador puede retornar
enum TokenType { LE, NE, LT, EQ, GE, GT, ERROR, UNKNOWN };

struct Token {
    TokenType type;
    string lexeme;
};

//funcion para mapear el caracter de entrada a una columna de la matriz
int getColumn(char c) {
    if (c == '<') return 0;
    if (c == '=') return 1;
    if (c == '>') return 2;
    return 3; //otros caracteres
}

//Analizador lexico
Token getRelop(const string& input) {
    //creacion de la matriz de transiciones
    //filas: estados del 0 al 8
    //columnas: entradas ('<', '=', '>', 'otros')
    //-1 representa un estado de error o transición erronea
    int transition_table[9][4] = {
        /* Estado 0 */ {  1,  5,  6, -1 },
        /* Estado 1 */ { -1,  2,  3,  4 },
        /* Estado 2 */ { -1, -1, -1, -1 }, //estado de aceptacion: <=
        /* Estado 3 */ { -1, -1, -1, -1 }, //estado de aceptacion: <>
        /* Estado 4 */ { -1, -1, -1, -1 }, //estado de aceptacion: < 
        /* Estado 5 */ { -1, -1, -1, -1 }, //estado de aceptacion: ==
        /* Estado 6 */ { -1,  7, -1,  8 },
        /* Estado 7 */ { -1, -1, -1, -1 }, //estado de aceptacion: >=
        /* Estado 8 */ { -1, -1, -1, -1 }  //estado de aceptacion: > 
    };

    int state = 0;
    string lexeme = "";
    size_t i = 0;

    while (i < input.length()) {
        char c = input[i];
        int col = getColumn(c);
        
        int next_state = transition_table[state][col];
 
        if (next_state == -1) {
            break; //se detiene el analisis
        }

        //si por alguna razon se llega a un estado con asterisco (*) en el diagrama, hacemos un 'retract'
        //significa que leimos un caracter de mas ("otros") para confirmar el token
        if (next_state == 4 || next_state == 8) {
            state = next_state;
            break; //salida del ciclo
        }

        lexeme += c;
        state = next_state;
        i++;

        //al llegar a un estado de aceptacion directa, se termina el analisis
        if (state == 2 || state == 3 || state == 5 || state == 7) {
            break;
        }
    }

    //retornacion del token correspondiente segun el estado final [cite: 108, 111, 117, 118, 122, 126]
    switch (state) {
        case 2: return {LE, lexeme};
        case 3: return {NE, lexeme};
        case 4: return {LT, lexeme};
        case 5: return {EQ, lexeme};
        case 7: return {GE, lexeme};
        case 8: return {GT, lexeme};
        default: return {ERROR, lexeme};
    }
}

//impresion
void printToken(Token t) {
    string typeNames[] = {"LE (<=)", "NE (<>)", "LT (<)", "EQ (=)", "GE (>=)", "GT (>)", "ERROR"};
    cout << "Token: " << typeNames[t.type] << " | Lexema: " << t.lexeme << endl;
}

int main() {
    string entrada;

    cout << "--- Analizador Lexico (Relop) ---" << endl;
    cout << "Escribe 'salir' para terminar el programa\n" << endl;

    while (true) {
        cout << "Ingrese un operador relacional: ";
        cin >> entrada;

        if (entrada == "salir") {
            cout << "Saliendo del programa..." << endl;
            break;
        }

        //entrada de datos
        Token t = getRelop(entrada);
        
        if (t.type == ERROR) {
            cout << "Error lexico: No se reconoce como un operador relacional." << endl;
        } else {
            printToken(t);
        }
        cout << "---------------------------------" << endl;
    }

    return 0;
}