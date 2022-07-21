# FunctionIndices

[![Build Status](https://github.com/wangl-cc/FunctionIndices.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/FunctionIndices.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/wangl-cc/FunctionIndices.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/wangl-cc/FunctionIndices.jl)
[![GitHub](https://img.shields.io/github/license/wangl-cc/FunctionIndices.jl)](https://github.com/wangl-cc/FunctionIndices.jl/blob/master/LICENSE)
[![Docs stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://wangl-cc.github.io/FunctionIndices.jl/stable/)
[![Docs dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wangl-cc.github.io/FunctionIndices.jl/dev/)

A small package allows indexing array with functions via a simple wrapper `FI`.
For example, `A[FI(iseven)]` returns an array containing all elements of `A` whose indices instead of values are even, like `(0:3)[FI(iseven)] == [1, 3]`.
To access elements whose values are even, try `filter(iseven, A)`.
As a special case, for indexing with `!=(i)` or `!in(I)`, which are expected to get elements whose index are not is `i` or not in `I`,
there is another wrapper `not` providing a convenient and optimized way.
The `not` is similar to `Not` of [`InvertedIndices`](https://github.com/JuliaData/InvertedIndices.jl), but faster in some cases,
see [performance comparing](https://wangl-cc.github.io/FunctionIndices.jl/stable/performance) for more information.

## Quick start to index with function index

1-d indexing `A[FI(f)]` is equivalent to `A[map(f, begin:end)]`,
multidimensional indexing `A[FI(f1), ..., FI(fn)]` is equivalent to `A[map(FI(f1), axes(A, 1)), ..., map(FI(fn), axes(A, n))]`.

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

`not` is an alternative to `Not`, and in most cases they are equivalent:

```julia
julia> using InvertedIndices

julia> A[not(1)] == A[Not(1)]
true

julia> A[not(1, 2)] == A[Not(1, 2)]
true

julia> A[not(1:2)] == A[Not(1:2)]
true

julia> let I = rand(Bool, size(A)); A[not(I)] == A[Not(I)] end
true
```

But for `CartesianIndex` and `CartesianIndices`,
`A[not(CartesianIndex(i, j,...))]` is equivalent to `A[not(i), not(j), ...]`
and `A[not(CartesianIndices((I, J,...))]` is equivalent to `A[not(I), not(J), ...]`,
where `not` treats inverted Cartesian indices as Cartesian inverted indices,
and always returns an array with the same dimension.
However, `A[Not(CartesianIndex(i, j,...))]`
converts `CartesianIndex` to linear index and return a vector,
and `A[Not(CartesianIndices((I, J,...)))]` seems an undefined behaviour.

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

julia> A[not(CartesianIndex(1, 2):CartesianIndex(2, 3))] # equivalent to A[not(1:2), not(2:3)]
1×2 Matrix{Int64}:
 2  11

julia> A[Not(CartesianIndex(1, 2):CartesianIndex(2, 3))] # seems an undefined behavior
1×2 Matrix{Int64}:
 5  8
```

Besides, for out of bounds index like `A[4, 5]`,
`A[not(4), not(5)]` is equivalent to `A[:, :]`,
because inbounds indices are not equal to the given value,
while `A[Not[4], Not(5)]` throws a `BoundsError`.

This package is also compatible with `OffsetArrays`:
```julia
julia> using OffsetArrays

julia> OA = OffsetArray(A, 2:4, 0:3)
3×4 OffsetArray(reshape(::UnitRange{Int64}, 3, 4), 2:4, 0:3) with eltype Int64 with indices 2:4×0:3:
 0  3  6   9
 1  4  7  10
 2  5  8  11

julia> OA[FI(iseven), FI(iseven)] # OA[[2, 4], [0, 2]]
2×2 Matrix{Int64}:
 0  6
 2  8

julia> OA[not(2), not(3)] # OA[[3, 4], [0, 1, 2]]
2×3 Matrix{Int64}:
 1  4  7
 2  5  8
```
