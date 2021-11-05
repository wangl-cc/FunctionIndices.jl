# FunctionIndices

[![Build Status](https://github.com/wangl-cc/FunctionIndices.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/FunctionIndices.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/wangl-cc/FunctionIndices.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/wangl-cc/FunctionIndices.jl)
[![GitHub](https://img.shields.io/github/license/wangl-cc/FunctionIndices.jl)](https://github.com/wangl-cc/FunctionIndices.jl/blob/master/LICENSE)
[![Docs stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://wangl-cc.github.io/FunctionIndices.jl/stable/)
[![Docs dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wangl-cc.github.io/FunctionIndices.jl/dev/)

A small package allows to access array elements by a function via a simple wrapper `FI`.
As a special case, for indexing with `!=(n)`, `!in(itr)`, there is another wrapper `not` providing a convenient and optimized way.
The `not` is similar to `Not` of [`InvertedIndices`](https://github.com/JuliaData/InvertedIndices.jl), but faster in some cases.
Besides, this package also provides ways to change the behavior for special array types and function index types.

## Quick start to index with function index

1-d indexing `A[FI(f)]` is equivalent to `A[map(f, begin:end)]`, multi-dimensional indexing `A[FI(f1), ..., FI(fn)]` is equivalent to `A[map(FI(f1), axes(A, 1)), ..., map(FI(fn), axes(A, n))]`.

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

julia> let I = rand(Bool, size(A)); A[not(I)] == A[Not(I)] end
true
```

But for `CartesianIndex` and `CartesianIndices`,
`A[not(CartesianIndex(i, j,...))]` is equivalent to `A[not(i), not(j), ...]`
and `A[not(CartesianIndices((I, J,...))]` is equivalent to `A[not(I), not(J), ...]`.
which return arrays with same dimension,
while `A[Not(CartesianIndex(i, j,...))]`
will convert the `CartesianIndex` to a linear index and return a vector,
and `A[Not(CartesianIndices((I, J,...)))]` seams an undefined behavior.

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

Besides, for out of bounds index like `A[4, 5]`, `A[not(4), not(5)]` is equivalent to `A[:, :]`,
because inbounds indices are not equal to the given value, while `A[Not[4], Not(5)]` throws an error.

## Optimizations for `not` with special index types

For faster indexing,
this package provides optimizations for `not` with some special index types,
which means `not(x)` is not equivalent to `FI(!in(x))` for `x` belonging to those index types,
and will be converted to different index types by `to_indices` function.

There are two list of those index types, both of which are enabled for `not`,
but for customized "NotIndex" types, you need to enable them by `indextype`.
More about customized  "NotIndex" types and `indextype` can be found in
[document](https://wangl-cc.github.io/FunctionIndices.jl/dev/).

There optimizations are enabled for any "NotIndex" types by default:

* `x::Colon` will be converted to an empty `Int` array: `Int[]`;
* `x::AbstractArray{Bool}` will be converted to an `LogicalIndex` with mask `mappedarray(!, x)`;
* `x::AbstractArray` will be converted like `FI(!in(x′))`,
  while `x′` is a `Set` like array converted from `x` with faster `in`;
* For `I′, J′ = to_indices(A, (not(I), not(J)))`, `not(I′)` and `not(I′)` will revert to `I`, `J`.

There optimizations are enabled only if `indextype` is defined as `Vector{Int}`:

* `x::Integer` will be converted to an `Int` array where `x` is removed from given axe.
* `x::OrdinalRange{<:Integer}`  will be converted to an `Int` array
  which is a set difference[^1] of given `ind` and `x`
* `x::Base.Slice` will be converted to an empty `Int` array,
  when the slice represents the given axe.
  Otherwise, it will be treated as a normal `AbstractUnitRange`.

## Performant tips for `not`

For small array, the optimized `not(x)` might be slower in some case,
because of the overhead for creating a `Set`.

There are some tips for better performance:
* Use `FI(!in(x))` instead of `not(x)`.
* Create your own "Not" type, see [below example](@ref intro-define) for details.
* For hand write indices like `not([1, 2, 3])`, `not(1, 2, 3)` will faster,
  which create a `not` of `Tuple` instead of `Array`.

More about this package see [document](https://wangl-cc.github.io/FunctionIndices.jl/dev/).

[^1]: The set difference is not calculated by `setdiff` from `julia` base library,
  but optimized for each `OrdinalRange` types. see source code of for details.
