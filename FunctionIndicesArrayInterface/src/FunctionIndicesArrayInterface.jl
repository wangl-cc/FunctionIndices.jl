module FunctionIndicesArrayInterface

using ArrayInterface
using ArrayInterfaceCore
using FunctionIndices: to_index, _to_linear_nots,
    AbstractFunctionIndex, AbstractNotIndex, NotCartesian

# ndims_index for AbstractFunctionIndex
# ArrayInterfaceCore.ndims_index(::Type{<:AbstractFunctionIndex}) = 1
ArrayInterfaceCore.ndims_index(::Type{<:AbstractNotIndex{T}}) where {T} =
    ArrayInterfaceCore.ndims_index(T)

# all optimization is enabled for ArrayInterface
ArrayInterface.to_index(s::IndexStyle, ax, i::AbstractFunctionIndex) =
    to_index(Vector{Int}, s, _to_linear_ax(ax), i)

## NotCartesian
ArrayInterface.to_index(::IndexStyle, ax, ::NotCartesian{0}) = ()
ArrayInterface.to_index(s::IndexStyle, ax, i::NotCartesian{1}) =
    to_index(Vector{Int}, s, _to_linear_ax(ax), _to_linear_nots(i)[1])
ArrayInterface.to_index(s::IndexStyle, axs, I::NotCartesian) =
    map((ax, i) -> ArrayInterface.to_index(s, ax, i), _to_ax_tuple(axs), _to_linear_nots(I))

_to_linear_ax(ax) = ax
_to_linear_ax(ax::LinearIndices{1}) = ax
_to_linear_ax(ax::LinearIndices) = eachindex(IndexLinear(), ax)
_to_linear_ax(ax::CartesianIndices{1}) = ax
_to_linear_ax(ax::CartesianIndices) = eachindex(IndexLinear(), ax)

_to_ax_tuple(ax) = (ax,)
_to_ax_tuple(ax::LinearIndices) = axes(ax)
_to_ax_tuple(ax::CartesianIndices) = ax.indices

end # module
