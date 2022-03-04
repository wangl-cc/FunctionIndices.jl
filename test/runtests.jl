using Test
using FunctionIndices
using OffsetArrays

@testset "FunctionIndices" begin
    A = collect(reshape(1:12, 3, 4))
    OA = OffsetArray(A, 2:4, 0:3)
    struct YANI{T} <: FunctionIndices.AbstractNotIndex{T}
        parent::T
    end
    Base.parent(I::YANI) = I.parent
    YANI(x::T, xs::T...) where {T} = YANI((x, xs...))

    @testset "FI" begin
        @test A[FI(iseven), FI(iseven)] == A[[2], [2, 4]]
        @test OA[FI(iseven), FI(iseven)] == OA[[2, 4], [0, 2]] == A[[1, 3], [1, 3]]
        AdjA = A'
        @test AdjA[FI(iseven), FI(iseven)] ==
              AdjA[[2, 4], [2]] ==
              A[FI(iseven), FI(iseven)]'
    end

    @testset "$_not" for _not in (not, YANI)
        @testset "not base" begin
            @test ones()[_not(CartesianIndex())] == 1
            @test A[_not(1), _not(2)] ==
                A[axes(A, 1).!=1, axes(A, 2).!=2] ==
                A[_not(CartesianIndex(1, 2))] ==
                A[_not(1), _not(2)] ==
                A[_not(CartesianIndex(1)), _not(2)] ==
                A[_not(CartesianIndex()), _not(1), _not(2)]
            @test isempty(A[_not(1), _not(2), _not(1)])
            @test !isempty(A[_not(1), _not(2), _not(2)])
            I = Bool[0, 1, 0]
            J = Bool[1, 0, 1, 0]
            @test A[_not(I), _not(J)] ==
                A[.!I, .!J] ==
                A[_not(Base.to_index(I)), _not(Base.to_index(J))]
            @test OA[_not(1), _not(2)] == OA[axes(OA, 1).!=1, axes(OA, 2).!=2] == A[:, _not(3)]
            @test A[_not(2)] ==
                A[_not(CartesianIndex(2))] ==
                A[1:length(A).!=2] ==
                OA[_not(2)] ==
                OA[_not(CartesianIndex(2))] ==
                OA[1:length(A).!=2]
            @test A[_not(2, 3)] == A[_not(2:3)] == OA[_not(2, 3)] == OA[_not(2:3)]
            @test A[_not(2, 3), _not(1, 3)] ==
                A[_not(2:3), _not(1:2:3)] ==
                OA[_not(3, 4), _not(0, 2)] ==
                OA[_not(3:4), _not(0:2:2)]
            @test A[_not(CartesianIndices((1:2, 2:3)))] ==
                A[_not(1:2), _not(2:3)] ==
                OA[_not(CartesianIndices((2:3, 1:2)))] ==
                OA[_not(2:3), _not(1:2)]
            # adjoint
            AdjA = A'
            @test AdjA[_not(1), _not(2)] ==
                AdjA[axes(AdjA, 1).!=1, axes(AdjA, 2).!=2] ==
                A[_not(2), _not(1)]'
            # slice and colon
            slc1, slc2 = Base.to_indices(A, (:, :)) # slices
            @test A[_not(:), :] == A[_not(slc1), :] == A[[], :] == similar(A, 0, size(A, 2))
            @test A[:, _not(:)] == A[:, _not(slc2)] == A[:, []] == similar(A, size(A, 1), 0)
            @test A[_not(:), _not(:)] == A[_not(slc1), _not(slc2)] == A[[], []] == similar(A, 0, 0)
            # slice is _not equal to axe
            @test OA[_not(slc1), :] == OA[[4], :]
            @test OA[:, _not(slc2)] == OA[:, [0]]
            @test OA[_not(slc1), _not(slc2)] == OA[[4], [0]]
            # converted index
            I, J = to_indices(A, (_not([2, 3]), FI(iseven)))
            K, L = to_indices(A, (_not(1, 2), FI(isodd)))
            @test OA[_not(I), _not(J)] ==
                OA[[2, 3], FI(isodd)] ==
                A[_not(K), _not(L)] ==
                A[[1, 2], FI(iseven)]
        end

        @testset "_not for outbound index" begin
            @test A[_not(0)] == A[_not(20)] == OA[_not(0)] == OA[_not(20)] == vec(A) == vec(OA)
            @test A[_not(0:13)] == A[_not(1:12)] == OA[_not(0:13)] == OA[_not(1:12)]
            @test A[_not(-1:1)] == A[_not(1:1)] == OA[_not(-1:1)] == OA[_not(1:1)]
            @test A[_not(0:2), _not(0)] == A[_not(1:2), _not(5)] == OA[_not(1:3), _not(-1)] == OA[_not(1:3), _not(4)] == A[3:3, 1:4] == OA[4:4, 0:3]
        end

        @testset "not for StepRange" begin
            @test A[not(1:0)] == A[not(0:-1:1)] == OA[not(1:0)] == OA[not(0:-1:1)] == vec(A) == vec(OA)
            @test A[not(2:10)] == OA[not(2:10)] == A[not(2:1:10)] == OA[not(2:1:10)] == A[[1, 11, 12]] == OA[[1, 11, 12]]
            @test A[not(10:-1:2)] == OA[not(10:-1:2)] == A[[1, 11, 12]] == OA[[1, 11, 12]]
            @test A[not(4:2:10)] == OA[not(4:2:10)] == A[[1:3; 5:2:9; 11:12]] == OA[[1:3; 5:2:9; 11:12]]
            @test A[not(10:-2:4)] == OA[not(10:-2:4)] == A[[1:3; 5:2:9; 11:12]] == OA[[1:3; 5:2:9; 11:12]]
            @test A[not(1:2:3), not(1:3:4)] == OA[not(2:2:4), not(0:3:3)] == A[[2], 2:3] == OA[[3], 1:2]
            @test A[not(1:2:3), not(4:-3:1)] == OA[not(2:2:4), not(3:-3:0)] == A[[2], 2:3] == OA[[3], 1:2]
        end
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
