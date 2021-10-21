module FunctionIndices

using MappedArrays

export FI, NotIndex, not

"""
    AbstractFunctionIndex

Supertype of all function index types.
"""
abstract type AbstractFunctionIndex end

"""
    FunctionIndices.to_index(::Type{T<:AbstractArray}, ind, i)

Convert a `AbstractFunctionIndex` `i` to a array index of type `T` with `ind`.
By default, `to_index(::AbstractArray, ind, i)` will return a
`Base.LogicalIndex{Bool, ReadonlyMappedArray{Bool...}}`.
"""
@inline to_index(::Type{T}, ind, i) where {T<:AbstractArray} = Base.to_index(
    # use mappedarray instead of map for less allocations and more information
    mappedarray(to_function(i), ind)::ReadonlyMappedArray{Bool},
) # no type assert here, because this methods will accept any T even T is not a LogicalIndex
@inline Base.to_indices(A, inds, I::Tuple{AbstractFunctionIndex,Vararg{Any}}) = (
    to_index(indextype(A, I[1]), _maybefirst(inds), I[1]),
    to_indices(A, Base._maybetail(inds), Base.tail(I))...,
)

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
By default, `to_function(I::AbstractNotIndex)` returns `!in(parent(I))`.
"""
to_function

_maybefirst(::Tuple{}) = Base.OneTo(1)
_maybefirst(inds::Tuple) = inds[1]

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

to_function(I::AbstractNotIndex) = !in(parent(I))

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
not(x::T, xs::T...) where {T} = NotIndex((x, xs...))

# CartesianIndices should be difference
struct NotCartesianIndex{N} <: AbstractNotIndex{CartesianIndex{N}}
    I::Dims{N}
end
not(I::CartesianIndex) = NotCartesianIndex(I.I)

# NotCartesianIndex{0} will be ignored by to_indices
# A[not(CartesianIndex()), 1] == A[1] like A[CartesianIndex(), 1] == A[1],
@inline Base.to_indices(A, inds, I::Tuple{NotCartesianIndex{0},Vararg{Any}}) =
    to_indices(A, inds, Base.tail(I))
# NotCartesianIndex{N} will be similar as Vararg{NotIndex{Int}, N}
@inline Base.to_indices(A, inds, I::Tuple{NotCartesianIndex,Vararg{Any}}) = (
    to_index(indextype(typeof(A), NotIndex{Int}), _maybefirst(inds), NotIndex(I[1].I[1])),
    to_indices(A, Base._maybetail(inds), (_tail_cartesian(I[1]), Base.tail(I)...))...,
)
# methods to override to_indices(A, ::Type{Any})
@inline Base.to_indices(A, ::Tuple{NotCartesianIndex{0}}) = ()
@inline Base.to_indices(A, I::Tuple{NotCartesianIndex{1}}) =
    to_indices(A, (NotIndex(I[1].I[1]),))
# avoid regard NotCartesianIndex as a LinearIndex
@inline Base.to_indices(A, I::Tuple{NotCartesianIndex}) = to_indices(A, axes(A), I)

_tail_cartesian(I::NotCartesianIndex) = NotCartesianIndex(Base.tail(I.I))

# bool array will not be convert to a FunctionIndex type
not(x::AbstractArray{<:Bool}) = map(!, x)

# Optimize for some special cases
const TVInt = Type{Vector{Int}}
to_index(::TVInt, ind::AbstractUnitRange{<:Integer}, I::AbstractNotIndex{<:Integer}) =
    (n = parent(I); [first(ind):(n-1); (n+1):last(ind)])::Vector{Int}
function to_index(
    ::TVInt,
    ind::AbstractUnitRange{<:Integer},
    I::AbstractNotIndex{<:AbstractUnitRange{<:Integer}},
)
    r = parent(I)
    ret = isempty(r) ? collect(ind) : [first(ind):(first(r)-1); (last(r)+1):last(ind)]
    return ret::Vector{Int}
end
# to_index for NotIndex{<:StepRange} is suboptimal for small size arrays
function to_index(
    ::TVInt,
    ind::AbstractUnitRange{<:Integer},
    I::AbstractNotIndex{<:StepRange{<:Integer}},
)
    r = parent(I)
    isempty(r) && return collect(ind) # collect ind for type stable
    sr = sort(r)
    mids = Vector{Int}(undef, last(sr) - first(sr) - length(sr) + 1)
    i = 1 # index of mids
    j = 1 # index of r
    @inbounds for k = first(sr):last(sr)
        if k == sr[j]
            j += 1
        else
            mids[i] = k
            i += 1
        end
    end
    return [first(ind):(first(r)-1); mids; (last(r)+1):last(ind)]::Vector{Int}
end

end # module