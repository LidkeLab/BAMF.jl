## Generic types and methods

using CUDA
abstract type PSF end
abstract type BAMFState end
abstract type BAMFData end


## StateFlatBg-------------
abstract type StateFlatBg <: BAMFState end

mutable struct StateFlatBg_CUDA <: StateFlatBg # this gets saved in chain
    n::Int32
    x::CuArray{Float32}
    y::CuArray{Float32}
    photons::CuArray{Float32}
    bg::Float32
end
mutable struct StateFlatBg_CPU <: StateFlatBg # this gets saved in chain
    n::Int32
    x::Vector{Float32}
    y::Vector{Float32}
    photons::Vector{Float32}
    bg::Float32
end

mutable struct StateFlatBg_Results <: StateFlatBg # this gets saved in chain
    n::Int32
    x::Vector{Float32}
    y::Vector{Float32}
    photons::Vector{Float32}
    σ_x::Vector{Float32}
    σ_y::Vector{Float32}
    σ_photons::Vector{Float32}
    bg::Float32
end


StateFlatBg() = StateFlatBg_CPU(0, [0], [0], [0], 0)
StateFlatBg(n::Int32) = StateFlatBg_CPU(n, Vector{Float32}(undef,n),Vector{Float32}(undef,n), Vector{Float32}(undef,n), 0)
StateFlatBg(n::Int32, x::Vector{Float32},y::Vector{Float32}, photons::Vector{Float32},bg::Float32)=StateFlatBg_CPU(n, x,y,photons, bg)
StateFlatBg_CUDA(n::Int32) = StateFlatBg_CPU(n, CuArray{Float32}(undef,n), CuArray{Float32}(undef,n), CuArray{Float32}(undef,n), 0)
StateFlatBg_Results(n::Int32) = StateFlatBg_Results(n, Vector{Float32}(undef,n),
    Vector{Float32}(undef,n), Vector{Float32}(undef,n),Vector{Float32}(undef,n),Vector{Float32}(undef,n), Vector{Float32}(undef,n), 0)


function StateFlatBg_CUDACopy!(myempty,myfull)
    idx=threadIdx().x
    myempty[idx]=myfull[idx]
    return nothing
end
function StateFlatBg(sf::StateFlatBg_CUDA) # make a deep copy
    s = StateFlatBg_CUDA(sf.n)
    @cuda threads=s.n StateFlatBg_CUDACopy!(s.x,sf.x)
    @cuda threads=s.n StateFlatBg_CUDACopy!(s.y,sf.y)
    @cuda threads=s.n StateFlatBg_CUDACopy!(s.photons,sf.photons)
    return s
end
function StateFlatBg(sf::StateFlatBg_CPU) # make a deep copy
    s = StateFlatBg(sf.n)
    for nn=1:s.n
        s.x[nn]=sf.x[nn]
        s.y[nn]=sf.y[nn]
        s.photons[nn]=sf.photons[nn]
    end
    return s
end

function addemitter!(s::StateFlatBg,x::Float32,y::Float32,photons::Float32)
    s.n=s.n+1
    push!(s.x,x)
    push!(s.y,y)
    push!(s.photons,photons)
end

function removeemitter!(s::StateFlatBg,idx::Int32)
    s.n=s.n-1
    deleteat!(s.x,idx)
    deleteat!(s.y,idx)
    deleteat!(s.photons,idx)
end

function findclosest(s::StateFlatBg,idx::Int32)
    if (s.n<2)||(idx<1) return 0 end
    
    mindis=1f5 #big
    nn=1
    for nn=1:s.n
        if nn!=idx
            dis=(s.x[idx]-s.x[nn])^2+(s.y[idx]-s.y[nn])
            if dis<mindis
                mindis=dis
                idx=nn
            end
        end
    end
    return Int32(nn)
end

function findother(s::StateFlatBg,idx::Int32)
    if (s.n<2)||(idx<1) return 0 end
    
    nn=ceil(s.n*rand())
    while nn==idx
        nn=ceil(s.n*rand())
    end

    return Int32(nn)
end



## ------------------

## ------------------


## RJPrior -----------------
mutable struct RJPrior
    sz::Int32
    θ_start::Float32
    θ_step::Float32
    pdf::Vector{Float32}
end
RJPrior()=RJPrior(1,1,1,[1])

function priorrnd(rjp::RJPrior)
    r=rand()
    mysum=rjp.pdf[1] 
    nn=1
    while (mysum<r)&&(nn<rjp.sz)
        nn+=1
        mysum+=rjp.pdf[nn]
    end
    return Float32((nn-1)*rjp.θ_step+rjp.θ_start)
end

"Calculate PDF(θ)"
function priorpdf(rjp::RJPrior,θ)
nn=round((θ-rjp.θ_start)/rjp.θ_step)
nn=Int32(max(1,min(nn,rjp.sz)))
return rjp.pdf[nn]
end


## ------------------------



## RJStruct ------------
mutable struct RJStruct # contains data and all static info for Direct Detection passed to BAMF functions 
    sz::Int32
    psf::PSF
    xy_std::Float32
    I_std::Float32
    split_std::Float32
    data::BAMFData
    bndpixels::Int32
    prior_photons::RJPrior
end
RJStruct(sz,psf,xy_std,I_std,split_std) = RJStruct(sz, psf, xy_std, I_std, split_std,ArrayDD(sz),Int32(2),RJPrior())
RJStruct(sz,psf,xy_std,I_std,split_std,data::BAMFData) = RJStruct(sz, psf, xy_std, I_std, split_std,data,Int32(2),RJPrior())

## ------------------------------

"generate an empty BAMFData stucture for data type in RJStruct"
function genBAMFData(rjs::RJStruct)
    return genBAMFData(rjs.data)
end











