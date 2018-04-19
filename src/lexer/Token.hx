package src.lexer;

enum Token{
    LParen;
    RParen;
    Period;
    Symbol(s : String);
    String(s : String);
    None;
}
