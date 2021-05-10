module BAMF

using Plots
using ImageView
using Distributions 
using CUDA

include("RJMCMC.jl")
include("bamftypes.jl")
include("helpers.jl")
include("gauss2D.jl")
include("airy2D.jl")
include("propose.jl")
include("accept.jl")
include("directdetection.jl")
include("sliver.jl")
include("analysis.jl")
include("display.jl")

function likelihoodratio(sz,m::CuArray{Float32,2}, mtest::CuArray{Float32,2}, d::CuArray{Float32,2})
    LLR=CUDA.zeros(1)
    # LLR[1]=0;
    @cuda threads=sz blocks=sz likelihoodratio_CUDA!(sz,m,mtest,d,LLR)
    L = exp(LLR[1])
    return L
end

function likelihoodratio_CUDA!(sz::Int32,m, mtest, d,LLR)
    ii = blockIdx().x
    jj = threadIdx().x 
    idx=(ii-1)*sz+jj
    llr=m[idx] - mtest[idx] + d[idx] * log(mtest[idx] / m[idx])
    CUDA.atomic_add!(pointer(LLR,1), llr)
    return nothing
end


end


