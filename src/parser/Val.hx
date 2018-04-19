package src.parser;

enum Val{
    Atom(s : String);
    List(lst : List<Val>);
    DottedList(lst : List<Val>, v : Val);
    Number(i : Int);
    String(s : String);
    Bool(b : Bool);
}
