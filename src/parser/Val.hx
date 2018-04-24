package src.parser;

enum Val{
    Atom(s : String);
    List(lst : Array<Val>);
    DottedList(lst : Array<Val>, v : Val);
    Number(i : Int);
    String(s : String);
    Bool(b : Bool);
}
