# Internal

## `AbstractFunctionIndex` interface

This package defines a type `AbstractFunctionIndex` (`AFI` for short) which can be converted to an array index by `Base.to_indices`. To define a new type of `AbstractFunctionIndex`, you need to implement the following methods:

| Method | Defaults | Description |
| :----- | :------- | :---------- |
| `to_function(I)` | required | convert the given `AFI` to a function; |
| `indextype` | `AbstractArray` | determines the return index of `to_index` type converted from `AFI`; |
| `to_index` | map function of `AFI` to axis | convert `AFI` to an index; |

## `AbstractNotIndex` interface

`AbstractNotIndex` is a subtype of `AbstractFunctionIndex`, which represents an inverted index.
To define a new type of `AbstractNotIndex`, the only needed method is `Base.parent`,
which returns the parent index which is inverted by this index.
`to_function` for `AbstractNotIndex` is pre-defined as [`notin(parent(I))`](@ref notin).

## [Define a new `NotIndex`](@id example)

If you don't like the default behaviour of `not`, creating a new `Notindex` type is easy:

```@example new-not
using FunctionIndices
struct YatAnotherNotIndex{T} <: FunctionIndices.AbstractNotIndex{T}
    parent::T
end
const YANI = YatAnotherNotIndex
Base.parent(I::YatAnotherNotIndex) = I.parent
reshape(1:10, 2, 5)[YANI(1), YANI(2)]
```

If a big array of linear indices `I` should be excluded,
create a new index array by `setdiff` might faster than `map(!in(I))`.
You can do this by defining `indextype` and `to_index` for `YANI`:

```@example new-not
FunctionIndices.indextype(::Type{<:AbstractArray}, ::Type{<:YANI{<:Array{<:Integer}}}) = Vector{Int}
FunctionIndices.to_index(::Type{Vector{Int}}, A, ind, I::YANI{<:Array{<:Integer}}) = setdiff(ind, parent(I))::Vector{Int}
to_indices(0:10, (YANI([1, 2, 3]),))
```
