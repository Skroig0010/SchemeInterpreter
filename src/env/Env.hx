package src.env;
import src.parser.*;
using src.show.Show;

class Env{
    var env : Map<String, Val>;
    public function showEnv(end : Bool){
        for(key in env.keys()){
            switch(env.get(key)){
                case PrimitiveFunc(_):
                case Func(_, _, _, closure):
                    if(!end){
                        trace(key + " : " + env.get(key).toString());
                        closure.showEnv(true);
                    }else{
                        trace("  " + key + " : " + env.get(key).toString());
                    }
                default :
                    if(!end){
                        trace(key + " : " + env.get(key).toString());
                    }else{
                        trace("  " + key + " : " + env.get(key).toString());
                    }
            }
        }
    }

    public function new(){
        env = new Map();
    }

    public function keys(){
        return env.keys();
    }

    public function isBound(key : String){
        return env.exists(key);
    }

    public function getVar(key : String){
        return env.get(key);
    }

    public function setVar(key : String, val : Val){
        if(!isBound(key)){
            throw "err";
        }
        env.set(key, val);
        return val;
    }

    public function defineVar(key : String, val : Val){
        env.set(key, val);
        return val;
    }

    public function bindVars(bindings : Env){
        for(key in bindings.keys()){
            env.set(key, bindings.getVar(key));
        }
    }

}
