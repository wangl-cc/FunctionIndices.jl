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
let bools = similar(Bool, A); A[not(bools)] == A[Not(bools)] end
```

But for `CartesianIndex`, `A[not(CartesianIndex(i, j,..., n))]` is equivalent to `A[not(i), not(j), ..., not(n)]` and will return a array with same dimension but `A[Not(CartesianIndex(i, j,..., n))]` will convert the `CartesianIndex` to a linear index and return a vector:

```@repl quick-start
A[not(CartesianIndex(1, 2))] # equivalent to A[not(1), not(2)]
A[Not(CartesianIndex(1, 2))] # equivalent to A[Not(3)]
```

Besides, for out of bounds index like `A[4, 5]`, `A[not(4), not(5)]` is equivalent to `A[:, :]`, because inbounds indices are not equal to the given value, while `A[Not[4], Not(5)]` causes an error.

## Performant tips for `not`

* For a big amount of indices `I` should be exclude, convert it to a `Set` by `not(Set(I))` might faster `not(I)`.
* For small array, the optimized `not(x)` might be slower than normal `FI(!in(x))`.

See [performance comparing](@ref performance) for details.

## Mechanism

This package define a type `AbstractFunctionIndex` (`AFI` for short) which can be convert ed to a array index by `Base.to_indices`.

There are three methods determining how to convert `AFI` to array index:

* [`FunctionIndices.to_index`](@ref): this function is the direct method converting `AFI`. The default method of `to_index` converting `AFI` to a function and map it for `ind`. Besides, the `to_index` also accepts a `Type` argument, which is determining call which method of `to_index` to convert `AFI`.
* [`FunctionIndices.to_function`](@ref): this function is called in default method `to_index` and convert the given `AFI` to a function.
* [`FunctionIndices.indextype`](@ref): this function is called in `to_indices` and returns a type as the `Type` argument of `to_index`. The `indextype` accepts two arguments, the type of array and type of a `AFI`.

## Example to defined

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
    `to_function` for `AbstractNotIndex` is defined as `!in(parent(I))`.

If a big array of linear indices `I` should be exclude, create a new index array by `setdiff` might faster than `map(!in(I))`.
You can do this by Defining `indextype` and `to_index` for `YANI`:
```@example new-not
FunctionIndices.indextype(::Type{<:AbstractArray}, ::Type{<:YANI{<:Array{<:Integer}}}) = Vector{Int}
FunctionIndices.to_index(::Type{Vector{Int}}, ind, I::YANI{<:Array{<:Integer}}) = setdiff(ind, parent(I))::Vector{Int}
typeof(to_indices(0:10, (YANI([1, 2, 3]),))[1]), typeof(to_indices(0:10, (not([1, 2, 3]),))[1])
```

## References

```@autodocs
Modules = [FunctionIndices]
```
