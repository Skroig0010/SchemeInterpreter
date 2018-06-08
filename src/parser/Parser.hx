package src.parser;
import src.lexer.Lexer;
import haxe.ds.Either;

class Parser{
    public function new(){ }

    public function parse(lexer : Lexer) : Either<String, Array<Val>>{ 
        var vals : Either<String, Array<Val>> = Right(new Array<Val>());
        while(true){
            skipSpaceAndComment(lexer, true);
            var exp = parseExpr(lexer);
            skipSpaceAndComment(lexer, true); 
                switch(exp){
                    case Right(exp) : 
                        switch(vals){
                            case Right(arr) :
                                arr.push(exp);
                            case Left(_) :
                                // 何もしない
                        }
                    case Left(err) :
                        return Left(err);
                }
            if(lexer.remainText() == ""){
                break;
            }
        }
        return vals;
    }
    // 最初の1文字は見る
    // つまり1単語読み終えたら次の単語の文字を指すようにする
    function parseExpr(lexer : Lexer) : Either<String, Val>{
        lexer.tryParse();
        var e = switch(lexer.getChar()){
            case "\"": 
                parseString(lexer);
            case "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                var n = parseNumber(lexer);
                if(n.match(Left(_))){
                    n = parseAtom(lexer);
                }
                n;
            case "(":
                lexer.moveNext();
                lexer.tryParse();
                var l = parseList(lexer);
                if(l.match(Left(_))){
                    lexer.tryParseEnd(false);
                    lexer.tryParse();
                    l = parseDottedList(lexer);
                }
                lexer.tryParseEnd(l.match(Right(_)));
                if(lexer.getChar() == ")"){
                    lexer.moveNext();
                    l;
                }else{
                    trace("required \")\" at character " + lexer.counter);
                    Left("Don't match list or dotted list");
                }
            case "\'":
                parseQuoted(lexer);
            default:
                parseAtom(lexer);
        }
        lexer.tryParseEnd(e.match(Right(_)));
        return e;
    }

    function parseAtom(lexer : Lexer) : Either<String, Val>{
        lexer.tryParse();
        var symbol = lexer.getChar();
        var reg = ~/^[0-9A-Z!\$%&\*\+-\.<=>\?@\^_#]+$/i;
        if(!reg.match(symbol)){
            lexer.tryParseEnd(false);
            trace("Don't match Symbol at character " + lexer.counter);return Left("Don't match Symbol");
        }
        while(lexer.moveNext()){
            if(!reg.match(symbol+lexer.getChar()) || isWhiteSpace(lexer.getChar())){
                break;
            }
            symbol += lexer.getChar();
        }
        var isNum = Std.parseInt(symbol) == null;
        if(reg.match(symbol) && symbol != "." && isNum){
            lexer.tryParseEnd(true);
            switch(symbol){
                case "#t":
                    return Right(Bool(true));
                case "#f":
                    return Right(Bool(false));
                default:
                    return Right(Atom(symbol));
            }
        }else{
            lexer.tryParseEnd(false);
            return Left("Don't match Symbol at character " + lexer.counter);
        }
    }
    function parseString(lexer : Lexer) : Either<String, Val>{
        lexer.tryParse();
        // "を食べる
        if(lexer.getChar() != "\""){
            lexer.tryParseEnd(false);
            trace("Don't match String at character " + lexer.counter);return Left("Don't match String");
        }
        var prevChar = "";
        var text = "";
        while(lexer.moveNext()){
            if(lexer.getChar() == "\""){
                if(prevChar != "\\")break;
            }
            prevChar = lexer.getChar();
            text += lexer.getChar();
        }
        // "を食べる
        if(lexer.getChar() != "\""){
            lexer.tryParseEnd(false);
            trace("Don't match String at character " + lexer.counter);return Left("Don't match String");
        }
        lexer.moveNext();
        lexer.tryParseEnd(true);
        return Right(Val.String(text));
    }

    function parseNumber(lexer : Lexer) : Either<String, Val>{
        lexer.tryParse();
        var number = lexer.getChar();
        var reg = ~/[0-9]/;
        var isNegative = false;

        if(number == "-"){
            isNegative = true;
            number = "";
        }else{
            if(!reg.match(number)){
                lexer.tryParseEnd(false);
                trace("Don't match Number at character " + lexer.counter);return Left("Don't match Number");
            }
        }
        while(lexer.moveNext()){
            if(!reg.match(lexer.getChar())){
                break;
            }
            number += lexer.getChar();
        }
        // 
        var i = Std.parseInt(number);
        if(i == null){
            lexer.tryParseEnd(false);
            return Left("Don't match Number");
        }
        lexer.tryParseEnd(true);
        if(isNegative)i = -i;
        return Right(Number(i));
    }
    function parseQuoted(lexer : Lexer) : Either<String, Val>{
        lexer.tryParse();
        if(lexer.getChar() != "'"){
            lexer.tryParseEnd(false);
            trace("Don't match Quoted at character " + lexer.counter);return Left("Don't match Quoted");
        }
        lexer.moveNext();
        var x = parseExpr(lexer);
        switch(x){
            case Right(exp):
                lexer.tryParseEnd(true);
                return Right(List([Atom("quote"), exp]));
            case Left(_):
                lexer.tryParseEnd(false);
                trace("Don't match Quated at character " + lexer.counter);return Left("Don't match Quated");
        }
    }
    function parseList(lexer : Lexer) : Either<String, Val>{
        lexer.tryParse();
        skipSpaceAndComment(lexer, true);
        var lst = new Array();
        while(lexer.getChar() != ")"){
            switch(parseExpr(lexer)){
                case Right(exp):lst.push(exp);
                case Left(err):
                                lexer.tryParseEnd(false);
                                return Left("Don't match List");
            }
            if(lexer.getChar() != ")"){
                if(!skipSpaceAndComment(lexer, false)){
                    lexer.tryParseEnd(false);
                    return Left("Don't match List");
                }
            }
        }
        lexer.tryParseEnd(true);
        return Right(List(lst));
    }
    function parseDottedList(lexer : Lexer) : Either<String, Val>{
        lexer.tryParse();
        skipSpaceAndComment(lexer, true);
        var lst = new Array();
        while(lexer.getChar() != "."){
            switch(parseExpr(lexer)){
                case Right(exp):lst.push(exp);
                case Left(err):
                                lexer.tryParseEnd(false);
                                return Left("Don't match DottedList");
            }
            if(!skipSpaceAndComment(lexer, false)){
                lexer.tryParseEnd(false);
                return Left("Don't match DottedList");
            }
        }
        lexer.moveNext();// .を食べる
        if(!skipSpaceAndComment(lexer, false)){
            lexer.tryParseEnd(false);
            return Left("Don't match DottedList");
        }
        var x = parseExpr(lexer);
        var v : Val;
        switch(x){
            case Right(exp):v = exp;
            case Left(err):
                            lexer.tryParseEnd(false);
                            return Left("Don't match DottedList");
        }
        lexer.tryParseEnd(true);
        return Right(DottedList(lst, v));
    }

    function skipSpaceAndComment(lexer : Lexer, canEmpty) : Bool{
        var skipAnything = canEmpty;
        while(spaces(lexer) || comment(lexer)){
            skipAnything = true;
        }
        if(!skipAnything)trace("required space after symbol at character " + lexer.counter);
        return skipAnything;
    }

    function spaces(lexer : Lexer) : Bool{
        lexer.tryParse();
        if(!isWhiteSpace(lexer.getChar())){
            lexer.tryParseEnd(false);
            return false;
        }
        while(lexer.moveNext()){
            if(lexer.getChar() != " "){
                lexer.tryParseEnd(true);
                return true;
            }
        }
        return true;
    }
    function comment(lexer : Lexer) : Bool{
        lexer.tryParse();
        if(lexer.getChar() == ";"){
        }else{
            lexer.tryParseEnd(false);
            return false;
        }
        while(lexer.moveNext()){
            if(lexer.getChar() == "\n"){
                lexer.moveNext();
                break;
            }
        }
        lexer.tryParseEnd(true);
        return true;
    }

    function isWhiteSpace(chr : String) : Bool{
        return chr == " " || chr == "\n" || chr == "\t";
    }
}
