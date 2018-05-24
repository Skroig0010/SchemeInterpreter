package src.test;
import src.parser.*;
import src.lexer.*;
import src.eval.*;
import src.env.*;
import haxe.unit.TestCase;
using src.show.Show;

class MyTestCase extends TestCase {

    function scheme(text : String, env : Env) : Val{
        var lexer = new Lexer(text);
        var parser = new Parser();
        var parsed = parser.parse(lexer);
        switch(parsed){
            case Right(tree) :
                return result = eval.eval(env, tree);
            case Left(_):
                return Atom("err");
        }
    }
    public function testBasic() {
        var env = new Env();
        assertEquals("2", scheme("(+ 1 1)").toString());
    }
}
