# Performance of `not`

## Optimizations for `not` with special index types

For faster indexing, this package provides optimizations for `not` with some special index types,
which means `not(x)` is not equivalent to `FI(!in(x))` for `x` belonging to those index types,
and will be converted to different index types by `to_indices` function.

There are two list of those index types, both of which are enabled for `not`,
but for customized `NotIndex` types, optimizations in second list is enabled
when `indextype` returns `Vector{Int}`.

There optimizations are enabled for any `AbstractNotIndex` types by default:

- `x::Colon` will be converted to an empty `Int` array: `Int[]`;
- `x::AbstractArray{Bool}` will be converted to a `LogicalIndex` with mask `mappedarray(!, x)`;
- `x::AbstractArray` will be converted like `FI(!in(x′))`,
  while `x′` is a `Set` like array converted from `x` with faster `in`;
- For `I′, J′ = to_indices(A, (not(I), not(J)))`, `not(I′)` and `not(I′)` will revert to `I`, `J`.

There optimizations are enabled only if `indextype` is defined as `Vector{Int}`:

- `x::Integer or x::OrdinalRange{<:Integer}` will be converted to an `Int` array
   where `x` is removed from given axis.
- `x::Base.Slice` will be converted to an empty `Int` array,
  when the slice represents the given axis,
  Otherwise, it will be treated as a normal `AbstractUnitRange`.

## Performance tips for `not`

For small array, the optimized `not(x)` might be slower in some case,
because of the overhead for creating a `Set`, see below.

There are some tips for better performance:

- Use `FI(!in(x))` instead of `not(x)`.
- Create your own "Not" type, see [below example](@ref example) for details.
- For a small array of indices, `not(1, 2, 3)` will faster than `not([1, 2, 3])`.

## [Performance comparing](@id performance)

This is a performance comparing of "Inverted Indexing" for different methods.
There are five methods:

- `bynot`: by `not` of this package;
- `byfi`: by function index `FI(!in(I))`;
- `bymap`: by logical indices which test `map(!in(I), axis)`;
- `byfilter`: by removing `I` from axes by `filter`;
- `byNot`: by `InvertedIndices.Not`.

The minimum time and allocation of each method for different type of index were compared:

```@example performance
using BenchmarkTools
using InvertedIndices
using FunctionIndices
using Latexify

# Linear
bynot(A, I) = A[not(I)]
byfi(A, I) = A[FI(!in(I))]
bymap(A, I) = A[map(!in(I), begin:end)]
byfilter(A, I) = A[filter(!in(I), begin:end)]
byNot(A, I) = A[Not(I)]

# Cartesian
bynot(A, Is...) = A[ntuple(i -> not(Is[i]), Val(length(Is)))...]
byfi(A, Is...) = A[ntuple(i -> FI(!in(Is[i])), Val(length(Is)))...]
bymap(A, Is...) = A[ntuple(i -> map(!in(Is[i]), axes(A, i)), Val(length(Is)))...]
byfilter(A, Is...) = A[ntuple(i -> filter(!in(Is[i]), axes(A, i)), Val(length(Is)))...]
byNot(A, Is...) = A[ntuple(i -> Not(Is[i]), Val(length(Is)))...]

const As = (rand(10), rand(10, 10), rand(10, 10, 10))
const fs = (bynot, byfi, bymap, byfilter, byNot)

# convert tuple of tuple to matrix
tt2mt(trs) = hcat(map(tr -> vcat(tr...), trs)...)

maketable(bench, As::Tuple=As, fs::Tuple=fs) = mdtable(
    # use map of map instead of for loop for typle stable
    map(
        f -> map(
            A -> begin
                trial = bench(f, A)
                trialmin = minimum(trial)
                trialallocs = allocs(trialmin)
                string(
                    BenchmarkTools.prettytime(time(trialmin)),
                    " (", trialallocs , " alloc",
                    trialallocs == 1 ? "" : "s", ": ",
                    BenchmarkTools.prettymemory(memory(trialmin)), ")"
                )
            end,
            As
        ),
        fs
    ) |> tt2mt;
    head=fs, side=[:Size; size.(As)...], latex=false,
);
```

## Indexing with `Int`

A random inbounds `Int` index.

### Linear Indexing

```@example performance
maketable() do f, A
    ind = rand(firstindex(A):lastindex(A))
    @benchmark $f($A, $ind)
end
```

### Multidimensional Indexing

```@example performance
maketable() do f, A
    inds = ntuple(i -> rand(axes(A, i)), Val(ndims(A)))
    @benchmark $f($A, $inds...)
end
```

## Indexing with `UnitRange`

A random inbound `UnitRange` with half-length of axe.

### Linear Indexing

```@example performance
maketable() do f, A
    axe = firstindex(A):lastindex(A)
    half = length(axe) ÷ 2
    b = rand(axe[begin:(end - half)])
    e = b + half
    @benchmark $f($A, $(b:e))
end
```

### Multidimensional Indexing

```@example performance
maketable() do f, A
    inds = ntuple(
        i -> begin
            axe = axes(A, i)
            half = length(axe) ÷ 2
            b = rand(axe[begin:(end - half)])
            e = b + half
            b:e
        end,
        Val(ndims(A))
    )
    @benchmark $f($A, $inds...)
end
```

## Indexing with `StepRange`

A `StepRange` with step `2`.

### Linear Indexing

```@example performance
maketable() do f, A
    ind = firstindex(A):2:lastindex(A)
    @benchmark $f($A, $ind)
end
```

### Multidimensional Indexing

```@example performance
maketable() do f, A
    inds = ntuple(
        i -> begin
            axe = axes(A, i)
            axe[begin:2:end]
        end,
        Val(ndims(A))
    )
    @benchmark $f($A, $inds...)
end
```

## Indexing with `Vector{Int}`

A `Vector{Int}` which is a `collect`ed `StepRange`.

### Linear Indexing

```@example performance
maketable() do f, A
    ind = collect(firstindex(A):2:lastindex(A))
    @benchmark $f($A, $ind)
end
```

### Multidimensional Indexing

```@example performance
maketable() do f, A
    inds = ntuple(
        i -> begin
            axe = axes(A, i)
            collect(axe[begin:2:end])
        end,
        Val(ndims(A))
    )
    @benchmark $f($A, $inds...)
end
```
