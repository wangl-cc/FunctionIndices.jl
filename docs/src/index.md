# Introduction

A small package allows to access array elements by a function via a simple wrapper `FI`.
As a special case, for indexing with `!=(n)`, `!in(itr)`, there is another wrapper `not` providing a convenient and optimized way.
The `not` is similar to `Not` of [`InvertedIndices`](https://github.com/JuliaData/InvertedIndices.jl), but faster in some cases.
Besides, this package also provides ways to change the behavior for special array types and function index types.

## Quick start

1-d indexing `A[FI(f)]` is equivalent to `A[map(f, begin:end)]`, multi-dimensional indexing `A[FI(f1), ..., FI(fn)]` is equivalent to `A[map(FI(f1), axes(A, 1)), ..., map(FI(fn), axes(A, n))]`.

```@repl quick-start
using FunctionIndices
A = reshape(0:11, 3, 4)
A[FI(iseven)]
A[map(iseven, begin:end)]
A[FI(isodd), FI(iseven)]
A[map(isodd, begin:end), map(iseven, begin:end)]
```

`not` is an alternative to `Not` and in most cases they are equivalent:

```@repl quick-start
using InvertedIndices
A[not(1)] == A[Not(1)]
A[not(1, 2)] == A[Not(1, 2)]
A[not(1:2)] == A[Not(1:2)]
let I = rand(Bool, size(A)); A[not(I)] == A[Not(I)] end
```

But for `CartesianIndex` and `CartesianIndices`,
`A[not(CartesianIndex(i, j,...))]` is equivalent to `A[not(i), not(j), ...]`
and `A[not(CartesianIndices((I, J,...))]` is equivalent to `A[not(I), not(J), ...]`.
which return arrays with same dimension,
while `A[Not(CartesianIndex(i, j,...))]`
will convert the `CartesianIndex` to a linear index and return a vector,
and `A[Not(CartesianIndices((I, J,...)))]` seams an undefined behavior.

```@repl quick-start
A[not(CartesianIndex(1, 2))] # equivalent to A[not(1), not(2)]
A[Not(CartesianIndex(1, 2))] # equivalent to A[Not(3)]
A[not(CartesianIndex(1, 2):CartesianIndex(2, 3))] # equivalent to A[not(1:2), not(2:3)]
A[Not(CartesianIndex(1, 2):CartesianIndex(2, 3))] # seems an undefined behavior
```

because inbounds indices are not equal to the given value, while `A[Not[4], Not(5)]` throws an error.

## Mechanism

This package define a type `AbstractFunctionIndex` (`AFI` for short) which can be convert ed to a array index by `Base.to_indices`.

There are three methods determining how to convert `AFI` to array index:

- [`FunctionIndices.to_index`](@ref): this function is the direct method converting `AFI`. The default method of `to_index` converting `AFI` to a function and map it for `ind`. Besides, the `to_index` also accepts a `Type` argument, which is determining call which method of `to_index` to convert `AFI`.
- [`FunctionIndices.to_function`](@ref): this function is called in default method `to_index` and convert the given `AFI` to a function.
- [`FunctionIndices.indextype`](@ref): this function is called in `to_indices` and returns a type as the `Type` argument of `to_index`. The `indextype` accepts two arguments, the type of array and type of a `AFI`.

## Optimizations for `not` with special index types

For faster indexing,
this package provides optimizations for `not` with some special index types,
which means `not(x)` is not equivalent to `FI(!in(x))` for `x` belonging to those index types,
and will be converted to different index types by `to_indices` function.

There are two list of those index types, both of which are enabled for `not`,
but for customized "NotIndex" types, you need to enable them by `indextype`.

There optimizations are enabled for any "NotIndex" types by default:

- `x::Colon` will be converted to an empty `Int` array: `Int[]`;
- `x::AbstractArray{Bool}` will be converted to an `LogicalIndex` with mask `mappedarray(!, x)`;
- `x::AbstractArray` will be converted like `FI(!in(x′))`,
  while `x′` is a `Set` like array converted from `x` with faster `in`;
- For `I′, J′ = to_indices(A, (not(I), not(J)))`, `not(I′)` and `not(I′)` will revert to `I`, `J`.

There optimizations are enabled only if `indextype` is defined as `Vector{Int}`:

- `x::Integer` will be converted to an `Int` array where `x` is removed from given axe.
- `x::OrdinalRange{<:Integer}` will be converted to an `Int` array
  which is a set difference[^1] of given `ind` and `x`
- `x::Base.Slice` will be converted to an empty `Int` array,
  when the slice represents the given axe.
  Otherwise, it will be treated as a normal `AbstractUnitRange`.

## Performant tips for `not`

For small array, the optimized `not(x)` might be slower in some case,
because of the overhead for creating a `Set`.
see [performance comparing](@ref performance) for details.

There are some tips for better performance:

- Use `FI(!in(x))` instead of `not(x)`.
- Create your own "Not" type, see [below example](@ref intro-define) for details.
- For a small array of indices like `not([1, 2, 3])`, `not(1, 2, 3)` will faster.

## [Example to define "Not"](@id intro-example)

If you don't like the default behavior of `not`, creating a new "Not" index type is easy:

```@example new-not
using FunctionIndices
struct YatAnotherNotIndex{T} <: FunctionIndices.AbstractNotIndex{T}
    parent::T
end
const YANI = YatAnotherNotIndex
Base.parent(I::YatAnotherNotIndex) = I.parent
reshape(1:10, 2, 5)[YANI(1), YANI(2)]
```

!!! info
    `to_function` for `AbstractNotIndex` is pre-defined as
    [`notin(parent(I))`](@ref notin).

If a big array of linear indices `I` should be exclude,
create a new index array by `setdiff` might faster than `map(!in(I))`.
You can do this by Defining `indextype` and `to_index` for `YANI`:

```@example new-not
FunctionIndices.indextype(::Type{<:AbstractArray}, ::Type{<:YANI{<:Array{<:Integer}}}) = Vector{Int}
FunctionIndices.to_index(::Type{Vector{Int}}, A, ind, I::YANI{<:Array{<:Integer}}) = setdiff(ind, parent(I))::Vector{Int}
typeof(to_indices(0:10, (YANI([1, 2, 3]),))[1]), typeof(to_indices(0:10, (not([1, 2, 3]),))[1])
```

[^1]:
    The set difference is not calculated by `setdiff` from `julia` base library,
    but optimized for each `OrdinalRange` types. see source code of for details.
