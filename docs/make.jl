using Documenter
using BenchmarkTools
using InvertedIndices
using FunctionIndices
using Latexify

makedocs(;
    sitename = "FunctionIndices",
    pagas = ["index.md", "performance.md", "references.md"],
)

deploydocs(; repo = "github.com/wangl-cc/FunctionIndices.jl", push_preview = true)
