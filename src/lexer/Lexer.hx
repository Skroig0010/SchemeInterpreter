package src.lexer;

class Lexer{
    public var counter(default, null) : Int;
    var text : String;
    var length : Int;
    var tempCounter : Array<Int>;
    public function new(text : String){
        this.text = text;
        length = text.length;
        counter = 0;
        tempCounter = new Array();
    }
    public function tryParse(){
        tempCounter.push(counter);
        //trace("counter : " + counter + " tempCounter.length : " + tempCounter.length);
    }

    public function tryParseEnd(isMatched : Bool){
        if(isMatched){
            tempCounter.pop();
        }else{
            counter = tempCounter.pop();
        }
        //trace("counter : " + counter + " tempCounter.length : " + tempCounter.length + " isMatched : " + isMatched);
    }

    public function getChar() : String{
        var char = text.charAt(counter);
        return char;
    }

    public function remainText() : String{
        return text.substr(counter);
    }
    public function moveNext() : Bool{
        counter++;
        return counter < length;
    }
}
