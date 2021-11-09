Maybe{T} = Union{T,Nothing}

issubmodule(m::Module, s) = s isa Module && parentmodule(s) == m && m != s

function submodules(m::Module)
    nms = filter!(names(m, all=true)) do y
        Base.isdefined(m, y) && !Base.isdeprecated(m, y)
    end
    symbols = Core.eval.(Ref(m), nms)
    filter!(x -> issubmodule(m, x), symbols)
end

# list of recursive submodules of m, including m itself
function recsubmodules(m::Module)
    subs = submodules(m)
    if isempty(subs)
        recs = subs
    else
        recs = mapreduce(recsubmodules, vcat, subs)
    end
    pushfirst!(recs, m)
    recs
end

function allequal(xs)
    local val
    for x in xs
        if !@isdefined(val)
            val = x
        else
            isequal(val, x) || return false
        end
    end
    true
end

# test if a module or one of its parents was replaced
function is_replaced(mod::Module)
    par = parentmodule(mod)
    while par != mod
        getfield(par, nameof(mod)) != mod && return true
        mod = par
        par = parentmodule(par)
    end
    false
end

# list of recursive parent modules of mod, starting with mod
function parentmodules(mod::Module)
    pars = [mod]
    while true
        par = parentmodule(mod)
        par == mod && return pars
        push!(pars, par)
        mod = par
    end
end
