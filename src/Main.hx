package src;
import haxe.io.*;
import src.lexer.Lexer;
import src.lexer.Token;
import src.parser.Parser;

class Main{
    public static function main(){
        var args = Sys.args();
        var line : String = "";
        var input : Input = Sys.stdin();
        var parser : Parser;
        var lexer : Lexer;
        while(true){
            // get standard input
            line = input.readLine();
            lexer = new Lexer(line);
            var token : Token;
            if(line == "quit")break; 
            trace(line);
            do{
                token = lexer.getToken();
                trace(Std.string(token));
            }while(token != null);
        }
        // How to use Reflection
        // trace(Reflect.callMethod(Type.resolveClass("Math"), Reflect.field(Type.resolveClass("Math"), "cos"), [3.14159265358979323846265]));
    }
}
