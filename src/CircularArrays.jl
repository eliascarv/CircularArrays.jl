"""
Arrays with fixed size and circular indexing.
"""
module CircularArrays

export CircularArray, CircularVector

"""
    CircularArray{T, N, A} <: AbstractArray{T, N}

`N`-dimensional array backed by an `AbstractArray{T, N}` of type `A` with fixed size and circular indexing.

    array[index...] == array[mod1.(index, size)...]
"""
struct CircularArray{T, N, A <: AbstractArray{T,N}} <: AbstractArray{T,N}
    data::A
    CircularArray{T,N}(data::A) where A <: AbstractArray{T,N} where {T,N} = new{T,N,A}(data)
    CircularArray{T,N,A}(data::A) where A <: AbstractArray{T,N} where {T,N} = new{T,N,A}(data)
end

"""
    CircularVector{T,A} <: AbstractVector{T}

One-dimensional array backed by an `AbstractArray{T, 1}` of type `A` with fixed size and circular indexing.
Alias for [`CircularArray{T,1,A}`](@ref).

    array[index] == array[mod1(index, length)]
"""
const CircularVector{T} = CircularArray{T, 1}

"""
    CircularArray(data)

Create a `CircularArray` wrapping the array `data`.
"""
CircularArray(data::AbstractArray{T,N}) where {T,N} = CircularArray{T,N}(data)
CircularArray{T}(data::AbstractArray{T,N}) where {T,N} = CircularArray{T,N}(data)

"""
    CircularArray(def, size)

Create a `CircularArray` of size `size` filled with value `def`.
"""
CircularArray(def::T, size) where T = CircularArray(fill(def, size))

Base.IndexStyle(::Type{CircularArray{T,N,A}}) where {T,N,A} = IndexCartesian()
Base.IndexStyle(::Type{<:CircularVector}) = IndexLinear()

@inline Base.getindex(arr::CircularArray, i::Int) = @inbounds getindex(arr.data, mod(i, eachindex(IndexLinear(), arr.data)))
@inline Base.getindex(arr::CircularArray{T,N,A}, I::Vararg{Int,N}) where {T,N,A} = @inbounds getindex(arr.data, mod.(I, axes(arr.data))...)

@inline Base.setindex!(arr::CircularArray, v, i::Int) = @inbounds setindex!(arr.data, v, mod(i, eachindex(IndexLinear(), arr.data)))
@inline Base.setindex!(arr::CircularArray{T,N,A}, v, I::Vararg{Int,N}) where {T,N,A} = @inbounds setindex!(arr.data, v, mod.(I, axes(arr.data))...)

@inline Base.size(arr::CircularArray) = size(arr.data)
@inline Base.axes(arr::CircularArray) = axes(arr.data)
@inline Base.parent(arr::CircularArray) = arr.data

@inline Base.iterate(arr::CircularArray, i...) = iterate(parent(arr), i...)

@inline Base.in(x, arr::CircularArray) = in(x, parent(arr))
@inline Base.copy(arr::CircularArray) = CircularArray(copy(parent(arr)))

@inline function Base.checkbounds(arr::CircularArray, I...)
    J = Base.to_indices(arr, I)
    length(J) == 1 || length(J) >= ndims(arr) || throw(BoundsError(arr, I))
    nothing
end

@inline _similar(arr::CircularArray, ::Type{T}, dims) where T = CircularArray(similar(parent(arr), T, dims))
@inline Base.similar(arr::CircularArray, ::Type{T}, dims::Tuple{Base.DimOrInd, Vararg{Base.DimOrInd}}) where T = _similar(arr, T, dims)
# Ambiguity resolution with Base
@inline Base.similar(arr::CircularArray, ::Type{T}, dims::Dims) where T = _similar(arr, T, dims)
@inline Base.similar(arr::CircularArray, ::Type{T}, dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo}}}) where T = _similar(arr, T, dims)

@inline _similar(::Type{CircularArray{T,N,A}}, dims) where {T,N,A} = CircularArray{T,N}(similar(A, dims))
@inline Base.similar(CA::Type{CircularArray{T,N,A}}, dims::Tuple{Base.DimOrInd, Vararg{Base.DimOrInd}}) where {T,N,A} = _similar(CA, dims)
# Ambiguity resolution with Base
@inline Base.similar(CA::Type{CircularArray{T,N,A}}, dims::Dims) where {T,N,A} = _similar(CA, dims)
@inline Base.similar(CA::Type{CircularArray{T,N,A}}, dims::Tuple{Union{Integer, Base.OneTo}, Vararg{Union{Integer, Base.OneTo}}}) where {T,N,A} = _similar(CA, dims)

@inline Broadcast.BroadcastStyle(::Type{CircularArray{T,N,A}}) where {T,N,A} = Broadcast.ArrayStyle{CircularArray{T,N,A}}()
@inline Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{CircularArray{T,N,A}}}, ::Type{ElType}) where {T,N,A,ElType} = CircularArray(similar(convert(Broadcast.Broadcasted{typeof(Broadcast.BroadcastStyle(A))}, bc), ElType))

@inline Base.dataids(arr::CircularArray) = Base.dataids(parent(arr))

function Base.showarg(io::IO, arr::CircularArray, toplevel)
    print(io, ndims(arr) == 1 ? "CircularVector(" : "CircularArray(")
    Base.showarg(io, parent(arr), false)
    print(io, ')')
    # toplevel && print(io, " with eltype ", eltype(arr))
end

"""
    CircularVector(data)

Create a `CircularVector` wrapping the array `data`.
"""
CircularVector(data::AbstractArray{T, 1}) where T = CircularVector{T}(data)

"""
    CircularVector(def, size)

Create a `CircularVector` of size `size` filled with value `def`.
"""
CircularVector(def::T, size::Int) where T = CircularVector{T}(fill(def, size))

function Base.deleteat!(a::CircularVector, i::Integer)
    deleteat!(a.data, mod(i, eachindex(IndexLinear(), a.data)))
    a
end

function Base.deleteat!(a::CircularVector, inds)
    deleteat!(a.data, sort!(unique(map(i -> mod(i, eachindex(IndexLinear(), a.data)), inds))))
    a
end

function Base.insert!(a::CircularVector, i::Integer, item)
    insert!(a.data, mod(i, eachindex(IndexLinear(), a.data)), item)
    a
end

end
