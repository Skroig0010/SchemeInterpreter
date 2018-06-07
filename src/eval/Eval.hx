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
            "string-append" => function(x : Array<Val>){
                var str = x.map(function(y : Val){
                    return switch(y){
                        case String(s) : s;
                        default : throw "string required, but got "  +Show.toString(x[0]);
                    }
                });
                return String(str.slice(1).fold(function(y : String, z : String){ return z + y;} , str[0]));
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
            "eq?" => function(x : Array<Val>){
                if(x.length != 2) throw "eq? required 2 arguments";
                switch([x[0], x[1]]){
                    case [Atom(atm1), Atom(atm2)] : 
                        return Bool(atm1 == atm2);
                    case [List([]), List([])] : 
                        return Bool(true);
                    case [List(lst1), List(lst2)] : 
                        return Bool(lst1 == lst2);
                    case [DottedList(lst1, v1), DottedList(lst2, v2)] : 
                        return Bool(lst1 == lst2 && v1 == v2);
                    case [Number(num1), Number(num2)] :
                        return Bool(num1 == num2);
                    case [String(str1), String(str2)] :
                        return Bool(str1 == str2);
                    case [Bool(b1), Bool(b2)] :
                        return Bool(b1 == b2);
                    case [PrimitiveFunc(_), PrimitiveFunc(_)] : 
                        return Bool(x[0] == x[1]);
                    case [Func(_), Func(_)] : 
                        return Bool(x[0] == x[1]);
                    default : return Bool(false);
                }
            },
            "neq?" => function(x : Array<Val>){
                return switch(primitives["eq?"](x)){
                    case Bool(b) : Bool(!b);
                    default : throw "unexpected error";
                }
            },
            "equal?" => function(x : Array<Val>){
                if(x.length != 2) throw "eq? required 2 arguments";
                switch([x[0], x[1]]){
                    case [List(lst1), List(lst2)] : 
                        if(lst1.length != lst2.length) return Bool(false);
                        for(i in 0...lst1.length){
                            if(!primitives["equal?"]([lst1[i], lst2[i]]).match(Bool(true)))return Bool(false);
                        }
                        return Bool(true);
                    case [DottedList(lst1, v1), DottedList(lst2, v2)] : 
                        return Bool(primitives["equals"]([List(lst1), List(lst2)]).match(Bool(true)) && v1 == v2);
                    default :
                        return primitives["eq?"](x);
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
            "symbol?" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return Bool(x[0].match(Atom(_)));
            },
            "car" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                switch(x[0]){
                    case List(v) : return v[0];
                    case DottedList(v, _) : return v[0];
                    default : throw "list required, but got " + Show.toString(x[1]);
                }
            },
            "cdr" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                switch(x[0]){
                    case List(v) : return List(v.slice(1));
                    case DottedList(v, v2) if(v.length > 1) : return DottedList(v.slice(1), v2);
                    case DottedList(v, v2) if(v.length == 1) : return v2;
                    default : throw "list required, but got " + Show.toString(x[1]);
                }
            },
            "cons" => function(x : Array<Val>){
                if(x.length != 2) throw "cons required 2 arguments";
                switch([x[0], x[1]]){
                    case [v, v2] if(!v2.match(List(_)) && !v2.match(DottedList(_, _))) : return DottedList([v], v2);
                    case [v, List(v2)] : return List([v].concat(v2));
                    case [v, DottedList(v2, v3)] : return DottedList([v].concat(v2), v3);
                    default : throw "list required, but got " + Show.toString(x[1]);
                }
            },
            "list" => function(x : Array<Val>){ return List(x); },
            "length" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                    case List(lst) : Number(lst.length);
                    default : throw "list required, but got " + Show.toString(x[1]);
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
            "last" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                return switch(x[0]){
                    case List(lst) : lst[lst.length - 1];
                    case DottedList(lst, _) : lst[lst.length - 1];
                    default : throw "list required, but got " + Show.toString(x[1]);
                }
            },
            "append" => function(x : Array<Val>){
                if(x.length == 0)return List([]);
                var lst = x.slice(1, x.length-2).fold(function(v1 : Val, v2 : Array<Val>){
                    return switch(v1){
                        case List(l1) : v2.concat(l1);
                        default : throw "list required, but got " + Show.toString(x[1]);
                    }
                }, switch(x[0]){
                    case List(l) : l;
                    default : throw "何がどうなっているのやら";
                });
                if(lst.length == 0){
                    return x[x.length - 1];
                }
                return switch(x[x.length - 1]){
                    case List(l) : List(lst.concat(l));
                    case DottedList(l, v) : DottedList(lst.concat(l), v);
                    default : List(lst.concat(x.slice(x.length - 1)));
                }
            },
            "apply" => function(x : Array<Val>){
                return apply(x[0], x.slice(1));
            },
            "load" => function(x : Array<Val>){
                if(x.length != 1) throw "too many arguments";
                switch(x[0]){
                    case String(filename) :
                        var txt = sys.io.File.getContent(filename);
                        var parsed = new Parser().parse(new Lexer(txt));
                        switch(parsed){
                            case Right(tree) :
                                return tree;
                            case Left(err) :
                                throw err;
                        }
                    default : throw "list required, but got " + Show.toString(x[1]);
                }
            }
    ];
    }

    public function eval(env : Env, val : Val){
        switch(val){
            case Number(i) : 
                return val;
            case String(s) : 
                return val;
            case Bool(b) : 
                return val;
            case Atom(id) : 
                return env.getVar(id);
            case List([Atom("quote"), v]) : 
                return v;
            case List([Atom("if"), pred, conseq, alt]) :
                return switch(eval(env, pred)){
                    case Bool(false) : eval(env, alt);
                    default : eval(env, conseq);
                };
            case List([Atom("set!"), Atom(key), form]) :
                return env.setVar(key, eval(env, form));
            case List([Atom("set-car!"), Atom(key), form]) :
                var evdForm = eval(env, form);
                return env.setVar(key,
                        switch(env.getVar(key)){
                            case List([]) : throw"Attempt to apply set-car! on ()";
                            case List(lst) : List([evdForm].concat(lst.slice(1)));
                            case DottedList(lst, v) : DottedList([evdForm].concat(lst.slice(1)), v);
                            default : throw"Attempt to apply set-car! on " + Show.toString(form);
                        }
                        );
            case List([Atom("set-cdr!"), Atom(key), form]) :
                var evdForm = eval(env, form);
                return env.setVar(key,
                        switch(env.getVar(key)){
                            case List([]) : 
                                throw"Attempt to apply set-cdr! on ()";
                            case List(lst) if(lst.length == 1) :
                                switch(evdForm){
                                    case List(lst2) :
                                        List(lst.concat(lst2));
                                    case DottedList(lst2, v) :
                                        DottedList(lst.concat(lst2), v);
                                    default : 
                                        DottedList(lst, evdForm);
                                }
                            case List(lst) : 
                                switch(evdForm){
                                    case List(lst2) :
                                        List([lst[0]].concat(lst2));
                                    case DottedList(lst2, v) :
                                        DottedList([lst[0]].concat(lst2), v);
                                    default :
                                        List([lst[0], evdForm].concat(lst.slice(2)));
                                }
                            case DottedList(lst, v) if(lst.length == 1) :
                                switch(evdForm){
                                    case List(lst2) :
                                        List(lst.concat(lst2));
                                    case DottedList(lst2, v2) :
                                        DottedList(lst.concat(lst2), v2);
                                    default :
                                        DottedList(lst, evdForm);
                                }
                            case DottedList(lst, v) :
                                switch(evdForm){
                                    case List(lst2) :
                                        List(lst.concat(lst2));
                                    case DottedList(lst2, v2) :
                                        DottedList(lst.concat(lst2), v2);
                                    default :
                                        DottedList([lst[0], evdForm].concat(lst.slice(2)), v);
                                }
                            default : throw"Attempt to apply set-cdr! on " + Show.toString(form);
                        }
                        );
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

            case List(lst) if(lst[0].match(Atom("define-macro")) && lst[1].match(List(_))) :
                return switch(lst[1]){
                    case List(args) : env.defineVar(Show.toString(args[0]), makeNormalMacro(env, args.slice(1), lst.slice(2)));
                    default : throw "err";
                };
            case List(lst) if(lst[0].match(Atom("define-macro")) && lst[1].match(DottedList(_))) :
                return switch(lst[1]){
                    case DottedList(args, varargs) : 
                        env.defineVar(Show.toString(args[0]), makeVarargsMacro(varargs, env, args.slice(1), lst.slice(2)));
                    default : throw "err";
                }


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
            case List(lst) if(lst[0].match(Atom("let")) && !lst[1].match(Atom(_))): 
                // 名前付きletはマクロで実装できるのでガードで潰しておく(ここでできそうなら編集する)
                var newEnv = new Env();
                switch(lst[1]){
                    case List(lst1) :
                        for(l in lst1){
                            switch(l){
                                case List(ll) : 
                                    newEnv.defineVar(Show.toString(ll[0]), eval(env, ll[1]));
                                default : throw "something wrong in let";
                            }
                        }
                        newEnv.bindVars(env);
                        return eval(newEnv, List([Val.Atom("begin")].concat(lst.slice(2))));
                    default : throw "something wrong in let";
                }
            case List(lst) if(lst[0].match(Atom("let*"))) :
                var newEnv = new Env();
                newEnv.bindVars(env);
                switch(lst[1]){
                    case List(lst1) :
                        for(l in lst1){
                            switch(l){
                                case List(ll) : 
                                    newEnv.defineVar(Show.toString(ll[0]), eval(newEnv, ll[1]));
                                default : throw "something wrong in let*";
                            }
                        }
                        return eval(newEnv, List([Val.Atom("begin")].concat(lst.slice(2))));
                    default : throw "something wrong in let*";
                }
            case List(lst) if(lst[0].match(Atom("letrec"))) :
                var newEnv = new Env();
                newEnv.bindVars(env);
                switch(lst[1]){
                    case List(lst1) :
                        for(l in lst1){
                            switch(l){
                                case List(ll) : 
                                    newEnv.defineVar(Show.toString(ll[0]), List([]));
                                default : throw "something wrong in letrec";
                            }
                        }
                        for(l in lst1){
                            switch(l){
                                case List(ll) : 
                                    newEnv.defineVar(Show.toString(ll[0]), eval(newEnv, ll[1]));
                                default : throw "something wrong in letrec";
                            }
                        }
                        return eval(newEnv, List([Val.Atom("begin")].concat(lst.slice(2))));
                    default : throw "something wrong in letrec";
                }
            case List(lst) if(lst[0].match(Atom("do"))) :
                var newEnv = new Env();
                var varNamesAndSteps = new Map<String, Val>();
                newEnv.bindVars(env);
                switch(lst[1]){
                    case List(lst1) :
                        for(l in lst1){
                            switch(l){
                                case List(ll) :
                                    newEnv.defineVar(Show.toString(ll[0]), List([]));
                                    varNamesAndSteps.set(Show.toString(ll[0]), ll[2]);
                                default : throw "something wrong in do";
                            }
                            switch(l){
                                case List(ll) :
                                    newEnv.defineVar(Show.toString(ll[0]), eval(newEnv, ll[1]));
                                default : throw "something wrong in do";
                            }
                        }
                        switch(lst[2]){
                            case List(ll) :
                                while(!eval(newEnv, ll[0]).match(Bool(true))){
                                    // コマンド更新
                                    eval(newEnv, List([Val.Atom("begin")].concat(lst.slice(3))));
                                    // ステップ更新
                                    var nextStepVars = new Map<String, Val>();
                                    for(key in varNamesAndSteps.keys()){
                                        nextStepVars.set(key, eval(newEnv, varNamesAndSteps.get(key)));
                                    }
                                    for(key in varNamesAndSteps.keys()){
                                        newEnv.setVar(key, nextStepVars.get(key));
                                    }
                                }
                                return eval(newEnv, List([Val.Atom("begin")].concat(ll.slice(1))));
                            default : throw "something wrong in do";
                        }
                    default : throw "something wrong in do";
                }

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

            case List(lst) : 
                var func = eval(env, lst[0]);
                return switch(func){
                    case Macro(_):
                        eval(env, apply(func, lst.slice(1)));
                    default :
                        apply(func, lst.slice(1).map(function (x) {return eval(env,x);}));
                }

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

    function makeMacro(varargs, env, params, body) : Val{
        return Macro(params.map(Show.toString), varargs, body, env);
    }

    function makeNormalMacro(env, params, body){
        return makeMacro(None, env, params, body);
    }
    function makeVarargsMacro(varargs, env, params, body){
        return makeMacro(Some(Show.toString(varargs)), env, params, body);
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
            case Macro(params, varargs, body, closure) :
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
