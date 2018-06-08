package src.show;
import src.parser.Val;
using src.show.Show;

class Show{
    public static function toString(val : Val) : String{
        return switch(val){
            case Atom(s) : s;
            case List(lst) : "(" + showVal(lst) + ")";
            case DottedList(lst, v) : "(" + showVal(lst) + " . " + v.toString() + ")";
            case Number(i) : "" + i;
            case String(s) : s;
            case Bool(b) : if(b) "#t" else "#f";
            case PrimitiveFunc(f) : "#<primitive>";
            case Func(params, vararg, body, closure) : 
                var s = "(lambda (" + params.join(" ") +
                switch(vararg){
                     case None : "";
                     case Some(arg) : " . " + arg;
                 };
                s + ") ...)";
            case Macro(params, vararg, body, closure) :
                var s = "(macro (" + params.join(" ") +
                switch(vararg){
                     case None : "";
                     case Some(arg) : " . " + arg;
                 };
                s + ") ...)";
            case HaxeObject(obj) :
                "haxe object : " + obj;
        }
    }

    static function showVal(lst : Array<Val>){
        return lst.map(toString).join(" ");
    }
}
