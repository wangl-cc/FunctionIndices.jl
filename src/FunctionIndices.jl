module FunctionIndices

using MappedArrays

export FI, NotIndex, not, notin

"""
    AbstractFunctionIndex

Supertype of all function index types.
"""
abstract type AbstractFunctionIndex end

"""
    FunctionIndices.to_index(A, ind, i)
    FunctionIndices.to_index(::Type{T}, S::IndexStyle, ind, i)

Convert a index `i` to a array index with the given axis `ind`.
By default, to_index(A::AbstractArray, ind, i) is defined as
`to_index(indextype(A), IndexStyle(A), ind, i)`.
To implement a custom index type with index type `T` and index style `S`,
override `to_index(::Type{T<:AbstractArray}, S::IndexStyle, ind, i)`.
If additional information is needed about the array `A`, override `to_index(A, ind, i)`.
"""
@inline to_index(A, ind, I) = to_index(indextype(A, I), IndexStyle(A), ind, I)
@inline to_index(::Type, S::IndexStyle, ind, i) = _to_logic_index(
    S,
    # use mappedarray instead of map for less allocations and more information
    mappedarray(to_function(i), ind)::ReadonlyMappedArray{Bool},
) # no type assert here, because this methods will accept any T even T is not a LogicalIndex

_to_logic_index(::IndexLinear, i) = Base.LogicalIndex{Int}(i)
_to_logic_index(::IndexStyle, i) = Base.to_index(i)

@inline Base.to_indices(A, inds, I::Tuple{AbstractFunctionIndex,Vararg{Any}}) = (
    to_index(A, _maybefirst(inds), I[1]),
    to_indices(A, Base._maybetail(inds), Base.tail(I))...,
)

_maybefirst(::Tuple{}) = Base.OneTo(1)
_maybefirst(inds::Tuple) = inds[1]

"""
    indextype([A::AbstractArray,] I::AbstractFunctionIndex)
    indextype([::Type{TA},] ::Type{TI})

Determine the index type which the function index type `TI`
will be converted to by `Base.to_indices` for array type `TA`.
By default, it's `AbstractArray`.

!!! note

    If you define a methods `indextype(::Type{TA}, ::Type{TI}) = T`,
    while `to_index(::Type{T}, inds, I::TI)` is not defined,
    the `to_indices` will not convert a index of type `TI` to a `T`,
    but a `Base.LogicalIndex`, the default return type of `to_index`.
"""
indextype(A::AbstractArray, I::AbstractFunctionIndex) = indextype(typeof(A), typeof(I))
indextype(::Type{<:AbstractArray}, ::Type{<:AbstractFunctionIndex}) = AbstractArray

"""
    to_function(I::AbstractFunctionIndex)

Converts a `AbstractFunctionIndex` to a `Function`.
By default, `to_function(I::AbstractNotIndex)` returns `notin(parent(I))`.
"""
to_function

"""
    FunctionIndex{F} <: AbstractFunctionIndex
    FI

A implementation of function index, which make indexing with function possible.
1-d indexing `A[FI(f)]` is equivalent to `A[map(f, begin:end)]`,
multi-dimensional indexing `A[FI(f1), ..., FI(fn)]` is equivalent to
`A[map(FI(f1), axes(A, 1)), ..., map(FI(fn), axes(A, n))]`.
"""
struct FunctionIndex{F} <: AbstractFunctionIndex
    f::F
end
const FI = FunctionIndex

to_function(ind::FunctionIndex) = ind.f

"""
    AbstractNotIndex{T}

Supertype of all not types which create by [`not`](@ref).
"""
abstract type AbstractNotIndex{T} <: AbstractFunctionIndex end

"""
    notin(item, collection)
    notin(collection)

The same as `!in`, used in the default `to_function` for `AbstractNotIndex`.
"""
notin(item, collection) = !(item in collection)
notin(collect) = Base.Fix2(notin, collect)

to_function(I::AbstractNotIndex) = notin(parent(I))

"""
    NotIndex{T} <: AbstractNotIndex{T}

The default implementation of [`not`](@ref).
There are some optimization for `NotIndex(x)` comparing to `FI(!in(x))`.
For large arrays, this implementation may be faster.
but for small arrays this implementation may be slower.
See [performance comparing](@ref performance) for more details.
"""
struct NotIndex{T} <: AbstractNotIndex{T}
    parent::T
end
Base.parent(I::NotIndex) = I.parent

# convert to Vector{Int} by default for NotIndex
indextype(::Type{<:AbstractArray}, ::Type{<:NotIndex}) = Vector{Int}

"""
    not(x)

Create a `NotIndex` with given `x`, which is similar to `Not` of
[`InvertedIndices`](https://github.com/JuliaData/InvertedIndices.jl).
In most cases, `not` is much faster than `Not`.
See [performance comparing](@ref performance) for more details.

# Main differences between `not` and `Not`

For `CartesianIndex`, `A[not(CartesianIndex(i, j,..., n))]` is equivalent to
`A[not(i), not(j), ..., not(n)]` and will return a array with same dimension,
but `A[Not(CartesianIndex(i, j,..., n))]` will convert the `CartesianIndex` to
a linear index and return a vector:

```jldoctest
julia> A = reshape(1:12, 3, 4)
3×4 reshape(::UnitRange{Int64}, 3, 4) with eltype Int64:
 0  3  6   9
 1  4  7  10
 2  5  8  11

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

Besides, for index like `A[4, 5]` which is out of bounds,
`A[not(4), not(5)]` is equivalent to `A[:, :]`,
because inbounds indices are always not equal to the given value,
while `A[Not[4], Not(5)]` causes an error.
"""
not(x) = NotIndex(x)
not(x::Integer) = NotIndex(Int(x))
not(x::T, xs::T...) where {T} = not((x, xs...))

# CartesianIndices and CartesianIndex should be difference
const NotCartesian{N} =
    Union{AbstractNotIndex{<:CartesianIndex{N}},AbstractNotIndex{<:CartesianIndices{N}}}

# NotCartesian{0} will be ignored by to_indices
# A[not(CartesianIndex()), 1] == A[1] like A[CartesianIndex(), 1] == A[1],
@inline Base.to_indices(A, inds, I::Tuple{<:NotCartesian{0},Vararg{Any}}) =
    to_indices(A, inds, Base.tail(I))
# NotCartesian{N} will be convert to as Vararg{AbstractNotIndex{Int}, N}
@inline Base.to_indices(A, inds, I::Tuple{<:NotCartesian,Vararg{Any}}) =
    to_indices(A, inds, (_to_linear_nots(I[1])..., Base.tail(I)...))

# methods override Base.to_indices(A, ::Type{Any})
# to avoid regard NotCartesian as a LinearIndex
@inline Base.to_indices(A, I::Tuple{<:NotCartesian}) = to_indices(A, _to_linear_nots(I[1]))

# convert the NotCartesian to normal nots
_to_linear_nots(I::NotCartesian) = map(_type_unionall(I), _getIS(parent(I)))
# to strip parameter from AbstractNotIndex, T.name.wrapper is hacky (T is always a DataType)
_type_unionall(::T) where {T} = T.name.wrapper

_getIS(I::CartesianIndex) = I.I
_getIS(I::CartesianIndices) = I.indices

# utils
## SetArray as a replace of Set for more information about parent
struct SetArray{T,N,TA<:AbstractArray{T,N}} <: AbstractArray{T,N}
    A::TA
    s::Set{T}
    SetArray(A::AbstractArray{T,N}) where {T,N} = new{T,N,typeof(A)}(A, Set{T}(A))
end
# no more methods needed for SetArray
Base.parent(A::SetArray) = A.A
Base.in(x, A::SetArray) = in(x, A.s)
## Tuple as a Vector to indexing
struct TupleVector{T,P<:Tuple} <: AbstractVector{T}
    parent::P
    TupleVector(tp::Tuple{Vararg{T}}) where {T} = new{T,typeof(tp)}(tp)
end
Base.parent(V::TupleVector) = V.parent
Base.size(V::TupleVector) = (length(parent(V)),)
Base.@propagate_inbounds Base.getindex(V::TupleVector{T,N}, i::Integer) where {T,N} =
    parent(V)[i]

# Optimization for some special cases
## Optimization for any indextype(A)
### For not(::Colon), (not(::Slice) is only optimized for indextype{A} == Vector{Int})
to_index(::Type{<:AbstractArray}, ::IndexStyle, ind, ::AbstractNotIndex{<:Colon}) = []
### For not(::AbstractArray{Bool})
to_index(::Type{<:AbstractArray}, S::IndexStyle, ind, I::AbstractNotIndex{<:AbstractArray{Bool}}) =
    _to_logic_index(S, mappedarray(!, parent(I)))
### For not(::AbstractArray), only test if in like a Set for AbstractArray
to_function(I::NotIndex{<:AbstractArray}) = notin(SetArray(parent(I)))
### For converted function index
to_index(
    ::Type{<:AbstractArray},
    S::IndexStyle,
    ind,
    I::AbstractNotIndex{<:Base.LogicalIndex{<:Any,<:ReadonlyMappedArray{Bool}}},
) = (rma = parent(I).mask; _not_mapped(S, rma.f, ind))
_not_mapped(S, f, ind) = _to_logic_index(S, mappedarray(!f, ind))
_not_mapped(::IndexStyle, f::Base.Fix2{typeof(notin),<:Tuple}, ::Any) = TupleVector(f.x)
_not_mapped(::IndexStyle, f::Base.Fix2{typeof(notin),<:SetArray}, ::Any) = parent(f.x)

## Optimize only for indextype(I) == Vector{Int}
const TVInt = Type{Vector{Int}}
function to_index(
    ::TVInt,
    ::IndexStyle,
    ind::AbstractUnitRange{<:Integer},
    I::AbstractNotIndex{<:Integer}
)
    n = parent(I)
    return n in ind ? [first(ind):(n-1); (n+1):last(ind)] : collect(ind)
end

function to_index(
    ::TVInt,
    ::IndexStyle,
    ind::AbstractUnitRange{<:Integer},
    I::AbstractNotIndex{<:AbstractUnitRange{<:Integer}},
)
    r = _check_index(ind, parent(I))
    return isempty(r) ? collect(ind) : [first(ind):(first(r)-1); (last(r)+1):last(ind)]
end
# to_index for NotIndex{<:StepRange} is suboptimal for small size arrays
function to_index(
    ::TVInt,
    ::IndexStyle,
    ind::AbstractUnitRange{<:Integer},
    I::AbstractNotIndex{<:StepRange{<:Integer}},
)
    r = _check_index(ind, parent(I))
    isempty(r) && return collect(ind)
    # collect ind for type stable
    step(r) == 1 && return [first(ind):first(r)-1; last(r)+1:last(ind)]
    ret = Vector{Int}(undef, length(ind) - length(r))
    copyto!(ret, first(ind):first(r)-1)
    offset = first(r) - first(ind) + 1
    @inbounds for i in 1:(last(r)-first(r))
        if i % step(r) != 0
            ret[offset] = i + first(r)
            offset += 1
        end
    end
    copyto!(ret, offset, last(r)+1:last(ind))
    return ret
end
function to_index(
    ::TVInt,
    S::IndexStyle,
    ind::AbstractUnitRange{<:Integer},
    I::AbstractNotIndex{<:Base.Slice},
)
    if parent(I) == ind # if slice is the same as the range, return a empty array
        return Int[]::Vector{Int}
    else # if slice is not equal to ind, invoke the method for unit range
        return invoke(
            to_index,
            Tuple{TVInt,typeof(S),typeof(ind),AbstractNotIndex{<:AbstractUnitRange{Int}}},
            Vector{Int},
            S,
            ind,
            I,
        )::Vector{Int}
    end
end

# process index like (1:2)[not(-1:3)] to (1:2)[not(1:2)]
# and (1:2)[not(2:-1:1)] to (1:2)[not(1:2)]
function _check_index(ind::AbstractUnitRange{<:Integer}, r::StepRange{<:Integer})
    if step(r) > 0
        return max(first(ind), first(r)):step(r):min(last(ind), last(r))
    else
        return max(first(ind), last(r)):-step(r):min(last(ind), first(r))
    end
end
_check_index(ind::AbstractUnitRange{<:Integer}, r::AbstractUnitRange{<:Integer}) =
    max(first(ind), first(r)):min(last(ind), last(r))

end # module
