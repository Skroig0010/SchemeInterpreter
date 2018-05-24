package src.eval;
import src.parser.*;
import src.lexer.Lexer;
import haxe.ds.Either;
import src.env.Env;
import src.show.Show;

using Lambda;

class Eval{

    public var primitives : Map<String, Array<Val> -> Val>;
    public function new(){
        primitives = [
            "+" => numericBinop(function(x : Int, y : Int){return x + y;}),
            "-" => numericBinop(function(x : Int, y : Int){return x - y;}),
            "*" => numericBinop(function(x : Int, y : Int){return x * y;}),
            "/" => numericBinop(function(x : Int, y : Int){return cast (x / y, Int);}),
            "mod" => numericBinop(function(x : Int, y : Int){return x % y;}),
            "number?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                case Number(_) : Bool(true);
                default : Bool(false);}},
            "boolean?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                case Bool(_) : Bool(true);
                default : Bool(false);}},
            "not" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                case Bool(t) if(t == false): Bool(true);
                default : Bool(false);}},
            "string?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                case Bool(_) : Bool(true);
                default : Bool(false);}
            },
            "symbol->string" => function(x : Array<Val>){
                if(x.length != 1)throw "too many arguments";
                return switch(x[0]){
                    case Atom(s) : String(s);
                    default : throw "symbol required, but got "  +Show.toString(x[0]);
                }
            },
            "string->symbol" => function(x : Array<Val>){
                if(x.length != 1)throw "too many arguments";
                return switch(x[0]){
                    case String(s) : Atom(s);
                    default : throw "string required, but got "  +Show.toString(x[0]);
                }
            },
            "string->number" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                    case String(str) : Number(Std.parseInt(str));
                    default : throw "string required, but got " + Show.toString(x[0]);
                }
            },
            "number->string" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                    case Number(number) : String("" + number);
                    default : throw "number required, but got " + Show.toString(x[0]);
                }
            },
            "procedure?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                    case Func(_) : Bool(true);
                    case PrimitiveFunc(_) : Bool(true);
                    default : Bool(false);
                }
            },
            "=" => numBoolBinop(function(x : Int, y : Int){return x == y;}), 
            "<" => numBoolBinop(function(x : Int, y : Int){return x < y;}), 
            "<=" => numBoolBinop(function(x : Int, y : Int){return x <= y;}), 
            ">" => numBoolBinop(function(x : Int, y : Int){return x > y;}), 
            ">=" => numBoolBinop(function(x : Int, y : Int){return x >= y;}), 
            "&&" => boolBoolBinop(function(x : Bool, y : Bool){return x && y;}), 
            "||" => boolBoolBinop(function(x : Bool, y : Bool){return x || y;}), 
            "null?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return Bool(x[0].match(List([])));
            },
            "pair?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                    case List([]) : Bool(false);
                    case List(_) : Bool(true);
                    case DottedList(_) : Bool(true);
                    default : Bool(false);
                }
            },
            "list?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return Bool(x[0].match(List(_)));
            },
            "car" => function(x : Array<Val>){
                if(x.length != 1)throw "err";
                switch(x[0]){
                    case List(v) : return v[0];
                    case DottedList(v, _) : return v[0];
                    default : throw "err";
                }
            },
            "cdr" => function(x : Array<Val>){
                if(x.length != 1)throw "err";
                switch(x[0]){
                    case List(v) : return List(v.slice(1));
                    case DottedList(v, v2) if(v.length > 1) : return DottedList(v.slice(1), v2);
                    case DottedList(v, v2) if(v.length == 1) : return v2;
                    default : throw "err";
                }
            },
            "cons" => function(x : Array<Val>){
                if(x.length != 2)throw "err";
                switch([x[0], x[1]]){
                    case [v, v2] if(!v2.match(List(_)) && !v2.match(DottedList(_, _))) : return DottedList([v], v2);
                    case [v, List(v2)] : return List([v].concat(v2));
                    case [v, DottedList(v2, v3)] : return DottedList([v].concat(v2), v3);
                    default : throw "err";
                }
            },
            "list" => function(x : Array<Val>){ return List(x); },
            "length" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                    case List(lst) : Number(lst.length);
                    default : throw "err";
                }
            },
            "memq" => function(x : Array<Val>){
                if(x.length != 2) throw "memq required 2 arguments";
                switch(x[1]){
                    case List(lst) :
                        for(i in 0...lst.length){
                            if(Type.enumEq(x[0], lst[i]))return List(lst.slice(i));
                        }
                        return Bool(false);
                    default : throw "list required, but got " + Show.toString(x[1]);
                }
            },
            "load" => function(x : Array<Val>){
                if(x.length != 1)throw "err";
                switch(x[0]){
                    case String(filename) :
                        var txt = sys.io.File.getContent(filename);
                        var parsed = new Parser().parse(new Lexer(txt));
                        switch(parsed){
                            case Right(tree) :
                                return tree;
                            case Left(_) :
                                throw "err";
                        }
                    default : throw "err";
                }
            }
    ];
    }

    public function eval(env : Env, val : Val){
        switch(val){
            case Number(i) : return val;
            case String(s) : return val;
            case Bool(b) : return val;
            case Atom(id) : return env.getVar(id);
            case List([Atom("quote"), v]) : return v;
            case List([Atom("if"), pred, conseq, alt]) :
                            return switch(eval(env, pred)){
                                case Bool(false) : eval(env, alt);
                                default : eval(env, conseq);
                            };
            case List([Atom("set!"), Atom(key), form]) :
                            return env.setVar(key, eval(env, form));
            // case List([Atom("set-car!"), List(lst), form]) :
            case List([Atom("define"), Atom(key), form]) : 
                            return env.defineVar(key, eval(env, form));
            case List(lst) if(lst[0].match(Atom("define")) && lst[1].match(List(_))) :
                            return switch(lst[1]){
                                // たぶん(define ((a b c) x y) (...))みたいなのがエラーにならない
                                case List(args) : env.defineVar(Show.toString(args[0]), makeNormalFunc(env, args.slice(1), lst.slice(2)));
                                default : throw "err";
                            };
            case List(lst) if(lst[0].match(Atom("define")) && lst[1].match(DottedList(_))) :
                            return switch(lst[1]){
                                case DottedList(args, varargs) : env.defineVar(Show.toString(args[0]), makeVarargs(varargs, env, args.slice(1), lst.slice(2)));
                                default : throw "err";
                            };

            case List(lst) if(lst[0].match(Atom("lambda")) &&  lst[1].match(List(_))) :
                            return switch(lst[1]){
                                case List(args) : makeNormalFunc(env, args, lst.slice(2));
                                default : throw "err";
                            };
            case List(lst) if(lst[0].match(Atom("lambda")) && lst[1].match(DottedList(_))) :
                            return switch(lst[1]){
                                case DottedList(args, varargs) : makeVarargs(varargs, env, args, lst.slice(2));
                                default : throw "err";
                            };
            case List(lst) if(lst[0].match(Atom("lambda")) && lst[1].match(Atom(_))) :
                            return makeVarargs(lst[1], env, [], lst.slice(2));

            case List(lst) if(lst[0].match(Atom("cond")) && lst.length > 1) :
                            for(x in lst.slice(1)){
                                switch(x){
                                    case List(l) if(l[0].match(Atom("else")) && l.length > 1) :
                                        return l.slice(1).map(function(x){return eval(env, x);})[l.length - 2];
                                    case List(l) if(l.length > 1) :
                                        if(eval(env, l[0]).match(Bool(true))){
                                            return l.slice(1).map(function(x){return eval(env, x);})[l.length - 2];
                                        }
                                    default : throw "cond parameter must be list";
                                }
                            }
                            throw "cond has no list";
            case List(lst) if(lst[0].match(Atom("or"))) :
                            for(x in lst.slice(1)){
                                var res = eval(env, x);
                                if(!res.match(Bool(false)))return res;
                            }
                            return Bool(false);
            case List(lst) if(lst[0].match(Atom("and"))) :
                            var res : Val = Bool(true);
                            for(x in lst.slice(1)){
                                res = eval(env, x);
                                if(res.match(Bool(false)))return Bool(false);
                            }
                            return res;
            case List(lst) if(lst[0].match(Atom("begin"))) : 
                            var res : Val = val;
                            for(x in lst.slice(1)){
                                res = eval(env, x);
                            }
                            return res;

        case List(lst) if(lst[0].match(Atom("load")) && lst[1].match(String(_))) :
                            eval(env, apply(eval(env, lst[0]), lst.slice(1)));
                            return Atom("loaded");

            case List(lst) : return apply(eval(env, lst[0]), lst.slice(1).map(function (x) {return eval(env,x);}));
            default : throw "err";
        }
    }

    public function primitiveBindings(){
        var env = new Env();
        for(key in primitives.keys()){
            env.defineVar(key, PrimitiveFunc(primitives.get(key)));
        }
        return env;
    }

    function makeFunc(varargs, env, params, body) : Val{
        return Func(params.map(Show.toString), varargs, body, env);
    }
    function makeNormalFunc(env, params, body){
        return makeFunc(None, env, params, body);
    }
    function makeVarargs(varargs, env, params, body){
        return makeFunc(Some(Show.toString(varargs)), env, params, body);
    }

    public function apply(func : Val, args : Array<Val>){
        switch(func){
            case Atom(f) :
                return primitives.get(f)(args);
            case PrimitiveFunc(f) : 
                return f(args);
            case Func(params, varargs, body, closure) : 
                if(params.length != args.length && varargs.match(None))throw "err";
                for(i in 0...params.length){
                    closure.defineVar(params[i], args[i]);
                }
                switch(varargs){
                    case Some(arg) : closure.defineVar(arg, List(args.slice(params.length)));
                    case None :
                }
                return body.map(function (x){return eval(closure,x);})[body.length - 1];
            default :
                return Atom("err");
        }
    }

    public function numericBinop(func : Int -> Int -> Int) : Array<Val> -> Val{
        return function(args : Array<Val>){
            return args.slice(1).fold(function(x : Val, y : Val) : Val{
                return switch[x, y]{
                    case[Number(num1), Number(num2)] :
                        Number(flip(func)(num1, num2));
                    default : throw "number required, but got another value.";
                }
            }, args[0]);
        }
    }

    public function numBoolBinop(func : Int -> Int -> Bool) : Array<Val> -> Val{
        return function(args : Array<Val>){
            return args.slice(1).fold(function(x : Val, y : Val) : Val{
                return switch[x, y]{
                    case [Number(num1), Number(num2)] :
                        Bool(flip(func)(num1, num2));
                    default : throw "number required, but got another value.";
                }
            }, args[0]);
        }
    }

    public function boolBoolBinop(func : Bool -> Bool -> Bool) : Array<Val> -> Val{
        return function(args : Array<Val>){
            return args.slice(1).fold(function(x : Val, y : Val) : Val{
                return switch[x, y]{
                    case [Bool(b1), Bool(b2)] :
                        Bool(flip(func)(b1, b2));
                    default : throw "bool required, but got another value.";
                }
            }, args[0]);
        }
    }

    public function strBoolBinop(func : String -> String -> Bool) : Array<Val> -> Val{
        return function(args : Array<Val>){
            return args.slice(1).fold(function(x : Val, y : Val) : Val{
                return switch[x, y]{
                    case [String(b1), String(b2)] :
                        Bool(flip(func)(b1, b2));
                    default : throw "string required, but got another value.";
                }
            }, args[0]);
        }
    }

    function flip<T, U>(func : T -> T -> U) : T -> T -> U{
        return function(x : T, y : T){
            return func(y, x);
        };
    }
}
