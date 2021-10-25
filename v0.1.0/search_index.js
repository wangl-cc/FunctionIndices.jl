var documenterSearchIndex = {"docs":
[{"location":"performance/#performance","page":"Performance comparing","title":"Performance comparing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"This is a performance comparing of \"Invert Indexing\" for different methods. There are four methods:","category":"page"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"bymap: test if it is not in given no for each index of A by map,\nbyfilter: removing no from index by filter,\nbyNot: by InvertedIndices.Not,\nbynot: by not of this package.","category":"page"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"This is the detail of benchmark. the minimum time of each methods for different type of index were compared:","category":"page"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"using BenchmarkTools\nusing InvertedIndices\nusing FunctionIndices\nusing Latexify\n\n# Linear\nbynot(A, no) = A[not(no)]\nbyfi(A, no) = A[FI(!in(no))]\nbymap(A, no) = A[map(!in(no), begin:end)]\nbyfilter(A, no) = A[filter(!in(no), begin:end)]\nbyNot(A, no) = A[Not(no)]\n\n# Cartesian\nbynot(A, nos...) = A[ntuple(i -> not(nos[i]), Val(length(nos)))...]\nbyfi(A, nos...) = A[ntuple(i -> FI(!in(nos[i])), Val(length(nos)))...]\nbymap(A, nos...) = A[ntuple(i -> map(!in(nos[i]), axes(A, i)), Val(length(nos)))...]\nbyfilter(A, nos...) = A[ntuple(i -> filter(!in(nos[i]), axes(A, i)), Val(length(nos)))...]\nbyNot(A, nos...) = A[ntuple(i -> Not(nos[i]), Val(length(nos)))...]\n\nconst As = (rand(10), rand(10, 10), rand(10, 10, 10))\nconst fs = (bynot, byfi, bymap, byfilter, byNot)\n\n# convert tuple of tuple to matrix\ntt2mt(trs) = hcat(map(tr -> vcat(tr...), trs)...)\n\nmaketable(bench, As::Tuple=As, fs::Tuple=fs) = mdtable(\n    # use map of map instead of for loop for typle stable\n    map(\n        f -> map(\n            A -> begin\n                trial = bench(f, A)\n                trialmin = minimum(trial)\n                trialallocs = allocs(trialmin)\n                string(\n                    BenchmarkTools.prettytime(time(trialmin)),\n                    \" (\", trialallocs , \" alloc\",\n                    trialallocs == 1 ? \"\" : \"s\", \": \",\n                    BenchmarkTools.prettymemory(memory(trialmin)), \")\"\n                )\n            end,\n            As\n        ),\n        fs\n    ) |> tt2mt;\n    head=fs, side=[:Size; size.(As)...], latex=false,\n);","category":"page"},{"location":"performance/#Indexing-with-Int","page":"Performance comparing","title":"Indexing with Int","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"A random inbounds Int index.","category":"page"},{"location":"performance/#Linear-Indexing","page":"Performance comparing","title":"Linear Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    ind = rand(firstindex(A):lastindex(A))\n    @benchmark $f($A, $ind)\nend","category":"page"},{"location":"performance/#Multi-dimensional-Indexing","page":"Performance comparing","title":"Multi-dimensional Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    inds = ntuple(i -> rand(axes(A, i)), Val(ndims(A)))\n    @benchmark $f($A, $inds...)\nend","category":"page"},{"location":"performance/#Indexing-with-UnitRange","page":"Performance comparing","title":"Indexing with UnitRange","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"A random inbound UnitRange with half length of axe.","category":"page"},{"location":"performance/#Linear-Indexing-2","page":"Performance comparing","title":"Linear Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    axe = firstindex(A):lastindex(A)\n    half = length(axe) ÷ 2\n    b = rand(axe[begin:(end - half)])\n    e = b + half\n    @benchmark $f($A, $(b:e))\nend","category":"page"},{"location":"performance/#Multi-dimensional-Indexing-2","page":"Performance comparing","title":"Multi-dimensional Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    inds = ntuple(\n        i -> begin\n            axe = axes(A, i)\n            half = length(axe) ÷ 2\n            b = rand(axe[begin:(end - half)])\n            e = b + half\n            b:e\n        end,\n        Val(ndims(A))\n    )\n    @benchmark $f($A, $inds...)\nend","category":"page"},{"location":"performance/#Indexing-with-StepRange","page":"Performance comparing","title":"Indexing with StepRange","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"A StepRange with step 2 and half length of axe.","category":"page"},{"location":"performance/#Linear-Indexing-3","page":"Performance comparing","title":"Linear Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    ind = firstindex(A):2:lastindex(A)\n    @benchmark $f($A, $ind)\nend","category":"page"},{"location":"performance/#Multi-dimensional-Indexing-3","page":"Performance comparing","title":"Multi-dimensional Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    inds = ntuple(\n        i -> begin\n            axe = axes(A, i)\n            axe[begin:2:end]\n        end,\n        Val(ndims(A))\n    )\n    @benchmark $f($A, $inds...)\nend","category":"page"},{"location":"performance/#Indexing-with-Vector{Int}","page":"Performance comparing","title":"Indexing with Vector{Int}","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"A Vector{Int} which is a collected StepRange.","category":"page"},{"location":"performance/#Linear-Indexing-4","page":"Performance comparing","title":"Linear Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    ind = collect(firstindex(A):2:lastindex(A))\n    @benchmark $f($A, $ind)\nend","category":"page"},{"location":"performance/#Multi-dimensional-Indexing-4","page":"Performance comparing","title":"Multi-dimensional Indexing","text":"","category":"section"},{"location":"performance/","page":"Performance comparing","title":"Performance comparing","text":"maketable() do f, A\n    inds = ntuple(\n        i -> begin\n            axe = axes(A, i)\n            collect(axe[begin:2:end])\n        end,\n        Val(ndims(A))\n    )\n    @benchmark $f($A, $inds...)\nend","category":"page"},{"location":"#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"A small package allows to access array elements by a function via a simple wrapper FI. As a special case, for indexing with !=(n), !in(itr), there is another wrapper not providing a convenient and optimized way. The not is similar to Not of InvertedIndices, but faster in some cases. Besides, this package also provides ways to change the behavior for special array types and function index types.","category":"page"},{"location":"#Quick-start","page":"Introduction","title":"Quick start","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"1-d indexing A[FI(f)] is equivalent to A[map(f, begin:end)], multi-dimensional indexing A[FI(f1), ..., FI(fn)] is equivalent to A[map(FI(f1), axes(A, 1)), ..., map(FI(fn), axes(A, n))].","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"using FunctionIndices\nA = reshape(0:11, 3, 4)\nA[FI(iseven)]\nA[map(iseven, begin:end)]\nA[FI(isodd), FI(iseven)]\nA[map(isodd, begin:end), map(iseven, begin:end)]","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"not is an alternative to Not and in most cases they are equivalent:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"using InvertedIndices\nA[not(1)] == A[Not(1)]\nA[not(1, 2)] == A[Not(1, 2)]\nA[not(1:2)] == A[Not(1:2)]\nlet bools = similar(Bool, A); A[not(bools)] == A[Not(bools)] end","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"But for CartesianIndex, A[not(CartesianIndex(i, j,..., n))] is equivalent to A[not(i), not(j), ..., not(n)] and will return a array with same dimension but A[Not(CartesianIndex(i, j,..., n))] will convert the CartesianIndex to a linear index and return a vector:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"A[not(CartesianIndex(1, 2))] # equivalent to A[not(1), not(2)]\nA[Not(CartesianIndex(1, 2))] # equivalent to A[Not(3)]","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"Besides, for out of bounds index like A[4, 5], A[not(4), not(5)] is equivalent to A[:, :], because inbounds indices are not equal to the given value, while A[Not[4], Not(5)] causes an error.","category":"page"},{"location":"#Performant-tips-for-not","page":"Introduction","title":"Performant tips for not","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"For small array, the optimized not(x) might be slower in some case, see performance comparing for details.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"There are some tips for better performance:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"Use FI(!in(x)) instead of not(x).\nCreate your own \"Not\" type, see below example for details.\nFor a small array of indices like not([1, 2, 3]), not(1, 2, 3) will faster.","category":"page"},{"location":"#Mechanism","page":"Introduction","title":"Mechanism","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"This package define a type AbstractFunctionIndex (AFI for short) which can be convert ed to a array index by Base.to_indices.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"There are three methods determining how to convert AFI to array index:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"FunctionIndices.to_index: this function is the direct method converting AFI. The default method of to_index converting AFI to a function and map it for ind. Besides, the to_index also accepts a Type argument, which is determining call which method of to_index to convert AFI.\nFunctionIndices.to_function: this function is called in default method to_index and convert the given AFI to a function.\nFunctionIndices.indextype: this function is called in to_indices and returns a type as the Type argument of to_index. The indextype accepts two arguments, the type of array and type of a AFI.","category":"page"},{"location":"#intro-define","page":"Introduction","title":"Example to define \"Not\"","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"If you don't like the default behavior of not, creating a new \"Not\" index type is easy:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"using FunctionIndices\nstruct YatAnotherNotIndex{T} <: FunctionIndices.AbstractNotIndex{T}\n    parent::T\nend\nconst YANI = YatAnotherNotIndex\nBase.parent(I::YatAnotherNotIndex) = I.parent\nreshape(1:10, 2, 5)[YANI(1), YANI(2)]","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"info: Info\nto_function for AbstractNotIndex is defined as !in(parent(I)).","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"If a big array of linear indices I should be exclude, create a new index array by setdiff might faster than map(!in(I)). You can do this by Defining indextype and to_index for YANI:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"FunctionIndices.indextype(::Type{<:AbstractArray}, ::Type{<:YANI{<:Array{<:Integer}}}) = Vector{Int}\nFunctionIndices.to_index(::Type{Vector{Int}}, ind, I::YANI{<:Array{<:Integer}}) = setdiff(ind, parent(I))::Vector{Int}\ntypeof(to_indices(0:10, (YANI([1, 2, 3]),))[1]), typeof(to_indices(0:10, (not([1, 2, 3]),))[1])","category":"page"},{"location":"#References","page":"Introduction","title":"References","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Modules = [FunctionIndices]","category":"page"},{"location":"#FunctionIndices.AbstractFunctionIndex","page":"Introduction","title":"FunctionIndices.AbstractFunctionIndex","text":"AbstractFunctionIndex\n\nSupertype of all function index types.\n\n\n\n\n\n","category":"type"},{"location":"#FunctionIndices.AbstractNotIndex","page":"Introduction","title":"FunctionIndices.AbstractNotIndex","text":"AbstractNotIndex{T}\n\nSupertype of all not types which create by not.\n\n\n\n\n\n","category":"type"},{"location":"#FunctionIndices.FunctionIndex","page":"Introduction","title":"FunctionIndices.FunctionIndex","text":"FunctionIndex{F} <: AbstractFunctionIndex\nFI\n\nA implementation of function index, which make indexing with function possible. 1-d indexing A[FI(f)] is equivalent to A[map(f, begin:end)], multi-dimensional indexing A[FI(f1), ..., FI(fn)] is equivalent to A[map(FI(f1), axes(A, 1)), ..., map(FI(fn), axes(A, n))].\n\n\n\n\n\n","category":"type"},{"location":"#FunctionIndices.NotIndex","page":"Introduction","title":"FunctionIndices.NotIndex","text":"NotIndex{T} <: AbstractNotIndex{T}\n\nThe default implementation of not. There are some optimization for NotIndex(x) comparing to FI(!in(x)). For large arrays, this implementation may be faster. but for small arrays this implementation may be slower. See performance comparing for more details.\n\n\n\n\n\n","category":"type"},{"location":"#FunctionIndices.indextype-Tuple{AbstractArray, FunctionIndices.AbstractFunctionIndex}","page":"Introduction","title":"FunctionIndices.indextype","text":"indextype([A::AbstractArray,] I::AbstractFunctionIndex)\nindextype([::Type{TA},] ::Type{TI})\n\nDetermine the index type which the function index type TI will be converted to by Base.to_indices for array type TA. By default, it's AbstractArray.\n\nnote: Note\nIf you define a methods indextype(::Type{TA}, ::Type{TI}) = T, while to_index(::Type{T}, inds, I::TI) is not defined, the to_indices will not convert a index of type TI to a T, but a Base.LogicalIndex, the default return type of to_index.\n\n\n\n\n\n","category":"method"},{"location":"#FunctionIndices.not-Tuple{Any}","page":"Introduction","title":"FunctionIndices.not","text":"not(x)\n\nCreate a NotIndex with given x, which is similar to Not of InvertedIndices. In most cases, not is much faster than Not. See performance comparing for more details.\n\nMain differences between not and Not\n\nFor CartesianIndex, A[not(CartesianIndex(i, j,..., n))] is equivalent to A[not(i), not(j), ..., not(n)] and will return a array with same dimension, but A[Not(CartesianIndex(i, j,..., n))] will convert the CartesianIndex to a linear index and return a vector:\n\njulia> A = reshape(1:12, 3, 4)\n3×4 reshape(::UnitRange{Int64}, 3, 4) with eltype Int64:\n 0  3  6   9\n 1  4  7  10\n 2  5  8  11\n\njulia> A[not(CartesianIndex(1, 2))] # equivalent to A[not(1), not(2)]\n2×3 Matrix{Int64}:\n 1  7  10\n 2  8  11\n\njulia> A[Not(CartesianIndex(1, 2))] # equivalent to A[Not(3)]\n11-element Vector{Int64}:\n  0\n  1\n  2\n  4\n  5\n  ⋮\n  8\n  9\n 10\n 11\n\nBesides, for index like A[4, 5] which is out of bounds, A[not(4), not(5)] is equivalent to A[:, :], because inbounds indices are always not equal to the given value, while A[Not[4], Not(5)] causes an error.\n\n\n\n\n\n","category":"method"},{"location":"#FunctionIndices.to_function","page":"Introduction","title":"FunctionIndices.to_function","text":"to_function(I::AbstractFunctionIndex)\n\nConverts a AbstractFunctionIndex to a Function. By default, to_function(I::AbstractNotIndex) returns !in(parent(I)).\n\n\n\n\n\n","category":"function"},{"location":"#FunctionIndices.to_index-Union{Tuple{T}, Tuple{Type{T}, Any, Any}} where T<:AbstractArray","page":"Introduction","title":"FunctionIndices.to_index","text":"FunctionIndices.to_index(::Type{T<:AbstractArray}, ind, i)\n\nConvert a AbstractFunctionIndex i to a array index of type T with ind. By default, to_index(::AbstractArray, ind, i) will return a Base.LogicalIndex{Bool, ReadonlyMappedArray{Bool...}}.\n\n\n\n\n\n","category":"method"}]
}
