# FunctionIndices

[![Build Status](https://github.com/wangl-cc/FunctionIndices.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/FunctionIndices.jl/actions/workflows/ci.yml)
  [![codecov](https://codecov.io/gh/wangl-cc/FunctionIndices.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/wangl-cc/FunctionIndices.jl)
[![GitHub](https://img.shields.io/github/license/wangl-cc/FunctionIndices.jl)](https://github.com/wangl-cc/FunctionIndices.jl/blob/master/LICENSE)
[![Docs dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wangl-cc.github.io/FunctionIndices.jl/dev/)

A small package allows to index arrays by a function via a simple wrapper `FI`. Besides, for indexing with `!=(n)`, `!in(itr)`, there is another wrapper `not` providing a convenient and optimized way, which is similar to `Not` of [`InvertedIndices`](https://github.com/JuliaData/InvertedIndices.jl), but faster in some cases.

1-d indexing `A[FI(f)]` is equivalent to `A[map(f, begin:end)]`, multi-dimensional indexing `A[FI(f1), ..., FI(fn)]` is equivalent to `A[map(FI(f1), axes(A, 1)), ..., map(FI(fn), axes(A, n))]`.

## Quick starts

```julia
julia> using FunctionIndices

julia> A = reshape(0:11, 3, 4)
3×4 reshape(::UnitRange{Int64}, 3, 4) with eltype Int64:
 0  3  6   9
 1  4  7  10
 2  5  8  11

julia> A[FI(iseven)]
6-element Vector{Int64}:
  1
  3
  5
  7
  9
 11

julia> A[map(iseven, begin:end)]
6-element Vector{Int64}:
  1
  3
  5
  7
  9
 11

julia> A[FI(isodd), FI(iseven)]
2×2 Matrix{Int64}:
 3   9
 5  11

julia> A[map(isodd, begin:end), map(iseven, begin:end)]
2×2 Matrix{Int64}:
 3   9
 5  11
```

`not` is an alternative to `Not` and in most cases they are equivalent:

```julia
julia> using InvertedIndices

julia> A[not(1)] == A[Not(1)]
true

julia> A[not(1, 2)] == A[Not(1, 2)]
true

julia> A[not(1:2)] == A[Not(1:2)]
true

julia> let bools = similar(Bool, A); A[not(bools)] == A[Not(bools)] end
true
```

But for `CartesianIndex`, `A[not(CartesianIndex(i, j,..., n))]` is equivalent to `A[not(i), not(j), ..., not(n)]` and will return a array with same dimension but `A[Not(CartesianIndex(i, j,..., n))]` will convert the `CartesianIndex` to a linear index and return a vector:

```julia
julia> A[not(CartesianIndex(1, 2))] # equivalent to A[not(1), not(2)]
2×3 Matrix{Int64}:
 1  7  10
 2  8  11

julia> A[Not(CartesianIndex(1, 2))] # equivalent to A[Not(3)]
11-element Vector{Int64}:
  0
  1
  2
  4
  5
  ⋮
  8
  9
 10
 11
```

Besides, for out of bounds index like `A[4, 5]`, `A[not(4), not(5)]` is equivalent to `A[:, :]`, because inbounds indices are not equal to the given value, while `A[Not[4], Not(5)]` causes an error.

## Performance

Currently, there are some performance issues for `InvertedIndices` ([InvertedIndices#14][i14], [InvertedIndices#27][i27]). Thus, in most of case, `not` is much faster than `Not`. See documents for benchmark comparing.

**Performance Tips:** For an `itr` a collection with more than 100 elements, `not(Set(itr))` may much faster than `not(itr)`.
