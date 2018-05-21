package src.parser;
import haxe.ds.Option;
import src.env.Env;
enum Val{
    Atom(s : String);
    List(lst : Array<Val>);
    DottedList(lst : Array<Val>, v : Val);
    Number(i : Int);
    String(s : String);
    Bool(b : Bool);
    PrimitiveFunc(f : Array<Val> -> Val);
    Func(params : Array<String>,vararg : Option<String>, body : Array<Val>, closure : Env);
}
