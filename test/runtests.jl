using Test
using FunctionIndices
using OffsetArrays

@testset "FunctionIndices" begin
    A = collect(reshape(1:12, 3, 4))
    OA = OffsetArray(A, 2:4, 0:3)

    @testset "FI" begin
        @test A[FI(iseven), FI(iseven)] == A[[2], [2, 4]]
        @test OA[FI(iseven), FI(iseven)] == OA[[2, 4], [0, 2]] == A[[1, 3], [1, 3]]
        AdjA = A'
        @test AdjA[FI(iseven), FI(iseven)] ==
              AdjA[[2, 4], [2]] ==
              A[FI(iseven), FI(iseven)]'
    end

    @testset "not" begin
        @test ones()[not(CartesianIndex())] == 1
        @test A[not(1), not(2)] ==
              A[axes(A, 1).!=1, axes(A, 2).!=2] ==
              A[not(CartesianIndex(1, 2))] ==
              A[not(1), not(2)] ==
              A[not(CartesianIndex(1)), not(2)] ==
              A[not(CartesianIndex()), not(1), not(2)]
        @test isempty(A[not(1), not(2), not(1)])
        @test !isempty(A[not(1), not(2), not(2)])
        I = Bool[0, 1, 0]
        J = Bool[1, 0, 1, 0]
        @test A[not(I), not(J)] == A[.!I, .!J] ==
            A[not(Base.to_index(I)), not(Base.to_index(J))]
        @test OA[not(1), not(2)] == OA[axes(OA, 1).!=1, axes(OA, 2).!=2] == A[:, not(3)]
        @test A[not(2)] ==
              A[not(CartesianIndex(2))] ==
              A[1:length(A).!=2] ==
              OA[not(2)] ==
              OA[not(CartesianIndex(2))] ==
              OA[1:length(A).!=2]
        @test A[not(2, 3)] == A[not(2:3)] == OA[not(2, 3)] == OA[not(2:3)]
        @test A[not(2, 3), not(1, 3)] ==
              A[not(2:3), not(1:2:3)] ==
              OA[not(3, 4), not(0, 2)] ==
              OA[not(3:4), not(0:2:2)]
        @test A[not(CartesianIndices((1:2, 2:3)))] ==
              A[not(1:2), not(2:3)] ==
              OA[not(CartesianIndices((2:3, 1:2)))] ==
              OA[not(2:3), not(1:2)]
        # adjoint
        AdjA = A'
        @test AdjA[not(1), not(2)] ==
              AdjA[axes(AdjA, 1).!=1, axes(AdjA, 2).!=2] ==
              A[not(2), not(1)]'
        # slice and colon
        slc1, slc2 = Base.to_indices(A, (:, :)) # slices
        @test A[not(:), :] == A[not(slc1), :] == A[[], :] == similar(A, 0, size(A, 2))
        @test A[:, not(:)] == A[:, not(slc2)] == A[:, []] == similar(A, size(A, 1), 0)
        @test A[not(:), not(:)] == A[not(slc1), not(slc2)] == A[[], []] == similar(A, 0, 0)
        # slice is not equal to axe
        @test OA[not(slc1), :] == OA[[4], :]
        @test OA[:, not(slc2)] == OA[:, [0]]
        @test OA[not(slc1), not(slc2)] == OA[[4], [0]]
        # converted index
        I, J = to_indices(A, (not([2, 3]), FI(iseven)))
        K, L = to_indices(A, (not(1, 2), FI(isodd)))
        @test OA[not(I), not(J)] ==
              OA[[2, 3], FI(isodd)] ==
              A[not(K), not(L)] ==
              A[[1, 2], FI(iseven)]
    end

    @testset "enable/disable optimization" begin
        @test to_indices(A, (not(0:2:2),))[1] isa Vector{Int}
        # disable optimization for not(::StepRange)
        FunctionIndices.indextype(
            ::Type{<:AbstractArray},
            ::Type{<:NotIndex{<:StepRange}},
        ) = Base.LogicalIndex
        @test to_indices(A, (not(0:2:2),))[1] isa Base.LogicalIndex
    end
end
