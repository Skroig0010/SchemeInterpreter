package src.lexer;

class Lexer{
    var text : String;
    var length : Int;
    var counter : Int = 0;
    public function new(text : String){
        this.text = text;
        length = text.length;
    }

    public function getToken() : Token{
        while(length > counter){
            var char = text.charAt(counter);
            counter++;
            switch(char){
                case " ":continue;
                case "\n":continue;
                case "\t":continue;
                case "(":return Token.LParen;
                case ")":return Token.RParen;
                case ".":return Token.Period;
                case "\"":
                         var str : String = "";
                         var prevChr : String = "";
                         while(length > counter){
                             char = text.charAt(counter);
                             if(char == "\"" && prevChr != "\\"){
                                 return Token.String(str);
                             }
                             str += char;
                             counter++;
                             prevChr = char;
                         }
                         return Token.None;
                default:// ここを書き直す。判定に正規表現使う
                         var str : String = "";
                         var reg = new EReg("^[0-9A-Z!\\$%&\\*\\+-\\.\\/<=>\\?@\\^_]+$", "i");
                         while(length > counter){
                             if(!reg.match(str + char)){
                                 if(reg.match(str)){
                                     return Token.Symbol(str);
                                 }else{
                                     return Token.None;
                                 }
                             }
                             str += char;
                             char = text.charAt(counter);
                             counter++;
                         }
                         return Token.Symbol(str);
            }
        }
        return null;
    }
}
