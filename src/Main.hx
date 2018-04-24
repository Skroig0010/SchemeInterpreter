package src;
import haxe.io.*;
import src.lexer.Lexer;
import src.lexer.Token;
import src.parser.Parser;

class Main{
    public static function main(){
        var args = Sys.args();
        var input : Input = Sys.stdin();
        var parser : Parser;
        var lexer : Lexer;
        while(true){
            var line : String = "";
            // get standard input
            do{
                line += input.readLine() + "\n";
            }while(line.charAt(line.length - 2) == ";");
            lexer = new Lexer(line);
            if(line == "quit\n")break;
            parser = new Parser();
            trace(parser.parse(lexer));
        }
        // How to use Reflection
        // trace(Reflect.callMethod(Type.resolveClass("Math"), Reflect.field(Type.resolveClass("Math"), "cos"), [3.14159265358979323846265]));
    }
}
