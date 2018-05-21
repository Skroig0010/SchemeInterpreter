package src.eval;
import src.parser.*;
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
                if(x.length != 1)throw "err";
                return switch(x[0]){
                case Number(_) : Bool(true);
                default : Bool(false);}},
            "boolean?" => function(x : Array<Val>){
                if(x.length != 1)throw "err";
                return switch(x[0]){
                case Bool(_) : Bool(true);
                default : Bool(false);}},
            "string?" => function(x : Array<Val>){
                if(x.length != 1)throw "err";
                return switch(x[0]){
                case Bool(_) : Bool(true);
                default : Bool(false);}},
            "not" => function(x : Array<Val>){
                if(x.length != 1)throw "err";
                return switch(x[0]){
                case Bool(t) if(t == false): Bool(true);
                default : Bool(false);}},
            "=" => numBoolBinop(function(x : Int, y : Int){return x == y;}), 
            "<" => numBoolBinop(function(x : Int, y : Int){return x < y;}), 
            "<=" => numBoolBinop(function(x : Int, y : Int){return x <= y;}), 
            ">" => numBoolBinop(function(x : Int, y : Int){return x > y;}), 
            ">=" => numBoolBinop(function(x : Int, y : Int){return x >= y;}), 
            "&&" => boolBoolBinop(function(x : Bool, y : Bool){return x && y;}), 
            "||" => boolBoolBinop(function(x : Bool, y : Bool){return x || y;}), 
            "null?" => function(x : Array<Val>){
                return Bool(x[0].match(List([])))
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

            case List(lst) : return apply(eval(env, lst[0]), lst.slice(1).map(function (x) {return eval(env,x);}));
            default : return Atom("err");
                      //case DottedList(lst, v):
                      //case Atom(s):return val;
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
