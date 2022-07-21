using Documenter
using BenchmarkTools
using InvertedIndices
using FunctionIndices
using Latexify

makedocs(;
    sitename = "FunctionIndices",
)

deploydocs(; repo = "github.com/wangl-cc/FunctionIndices.jl", push_preview = true)
