# [Performance comparing](@id performance)

This is a performance comparing of "Invert Indexing" for different methods.
There are four methods:

- `bymap`: test if it is not in given `no` for each index of `A` by `map`,
- `byfilter`: removing `no` from index by `filter`,
- `byNot`: by `InvertedIndices.Not`,
- `bynot`: by `not` of this package.

This is the detail of benchmark.
the minimum time of each methods for different type of index were compared:

```@example performance
using BenchmarkTools
using InvertedIndices
using FunctionIndices
using Latexify

# Linear
bynot(A, no) = A[not(no)]
byfi(A, no) = A[FI(!in(no))]
bymap(A, no) = A[map(!in(no), begin:end)]
byfilter(A, no) = A[filter(!in(no), begin:end)]
byNot(A, no) = A[Not(no)]

# Cartesian
bynot(A, nos...) = A[ntuple(i -> not(nos[i]), Val(length(nos)))...]
byfi(A, nos...) = A[ntuple(i -> FI(!in(nos[i])), Val(length(nos)))...]
bymap(A, nos...) = A[ntuple(i -> map(!in(nos[i]), axes(A, i)), Val(length(nos)))...]
byfilter(A, nos...) = A[ntuple(i -> filter(!in(nos[i]), axes(A, i)), Val(length(nos)))...]
byNot(A, nos...) = A[ntuple(i -> Not(nos[i]), Val(length(nos)))...]

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

### Multi-dimensional Indexing

```@example performance
maketable() do f, A
    inds = ntuple(i -> rand(axes(A, i)), Val(ndims(A)))
    @benchmark $f($A, $inds...)
end
```

## Indexing with `UnitRange`

A random inbound `UnitRange` with half length of axe.

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

### Multi-dimensional Indexing

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

A `StepRange` with step `2` and half length of axe.

### Linear Indexing

```@example performance
maketable() do f, A
    ind = firstindex(A):2:lastindex(A)
    @benchmark $f($A, $ind)
end
```

### Multi-dimensional Indexing

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

### Multi-dimensional Indexing

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
