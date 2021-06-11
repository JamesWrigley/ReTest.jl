using ReTest # useful when setup.jl included separately

module Trace
export trace
using ReTest: @test

const RUN = []

function trace(x)
    push!(RUN, x)
    @test true
end
end

# NOTE: all keywords have the same defaults as `retest`, except `marks`
function check(x...; runtests=false, output::Union{Nothing,String}=nothing,
               verbose=true, stats=false, dry=false, strict::Bool=true,
               recursive=true, static=nothing, id=nothing, load=false, marks::Bool=false)
    @assert !(runtests & (output !== nothing)) "unimplemented"
    args = x[1:end-1]
    expected = x[end]
    if expected isa AbstractString
        expected = split(x[end])
    end

    empty!(Trace.RUN)
    if runtests
        getfield(args[1], :runtests)(args[2:end]...; verbose=verbose, stats=stats, dry=dry,
                                     strict=strict, recursive=recursive, static=static,
                                     id=id, load=load, marks=marks)
    elseif output === nothing
        retest(args...; verbose=verbose, stats=stats, dry=dry, strict=strict,
               recursive=recursive, static=static, id=id, load=load, marks=marks)
    else
        mktemp() do path, io
            redirect_stdout(io) do
                retest(args...; verbose=verbose, stats=stats, dry=dry, strict=strict,
                       recursive=recursive, static=static, id=id, load=load, marks=marks)
            end
            seekstart(io)
            printed = join(map(rstrip, split(readchomp(io), '\n')), '\n')
            output = join(map(rstrip, split(chomp(output), '\n')), '\n')
            @test printed == output
        end
    end
    @test Trace.RUN == expected
end

# @chapter title [wrap_in_testset::Bool=true] body
macro chapter(title, wrap_in_testset, body=nothing)
    title = string(title)
    if body === nothing
        body = wrap_in_testset
        wrap_in_testset = true
    else
        wrap_in_testset::Bool
    end

    if isempty(ARGS) || any(pat -> occursin(Regex(pat, "i"), title), ARGS)
        printstyled("\n\n", rpad("## $title #", 78, '#'), "\n\n", bold=true, color=:cyan)
        if wrap_in_testset
            quote
                Test.@testset $("$title") begin
                    $(esc(body))
                end
            end
        else
            esc(body)
        end
    end
end
