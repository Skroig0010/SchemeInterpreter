package src;
import haxe.io.*;
import src.lexer.Lexer;
import src.parser.Parser;
import src.eval.Eval;

class Main{
    public static function main(){
        var args = Sys.args();
        var input : Input = Sys.stdin();
        var eval : Eval;
        var parser : Parser;
        var lexer : Lexer;
        while(true){
            // get standard input
            var line = input.readLine();
            lexer = new Lexer(line);
            if(line == "quit")break;
            parser = new Parser();
            var parsed = parser.parse(lexer);
            trace(parsed);
            switch(parsed){
                case Right(tree) :
                    eval = new Eval();
                    var result = eval.eval(tree);
                    trace(result);
                case Left(_):
                    trace("parse error");
            }
        }
        // How to use Reflection
        // trace(Reflect.callMethod(Type.resolveClass("Math"), Reflect.field(Type.resolveClass("Math"), "cos"), [3.14159265358979323846265]));
    }
}
