package src;
import haxe.io.*;
import src.lexer.Lexer;
import src.parser.*;
import src.eval.Eval;
import src.env.Env;
using src.show.Show;

class Main{
    static public var eval = new Eval();
    static public var env = eval.primitiveBindings();


    public static function main(){
        trace(1/0);
        var args = Sys.args();
        var input : Input = Sys.stdin();
        var output : Output = Sys.stdout();
        while(true){
            // get standard input
            var line = input.readLine();
            if(line == "quit")break;
            var result = evaluate(line);
            output.writeString(result.toString() + "\n");
        }
    }

    static public function evaluate(code : String) : src.parser.Val{
        var parser : Parser;
        var lexer : Lexer;
        lexer = new Lexer(code);
        parser = new Parser();
        var parsed = parser.parse(lexer);
        switch(parsed){
            case Right(exps) :
                try{
                    return eval.eval(env, exps[0]);
                }catch(errmsg : String){
                    trace("runtime error occurred : " + errmsg);
                    return Atom("error");
                }
            case Left(_):
                trace("parse error");
                return Atom("error");
        }
    }

    static public function valtoDynamic(val : Val){
        return eval.valToHaxeObject(val);
    }
}
