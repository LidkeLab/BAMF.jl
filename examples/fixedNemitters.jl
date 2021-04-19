## Demonstrates use of BAMF on a single region with fixed Number of emitters

using Revise
using Plots
println(pwd())
include("../src/RJMCMC.jl")
includet("../src/BAMF.jl")
using .RJMCMC

## create a dataset 
n=3
sz=Int32(16)
sigma=1.3f0
x=[sz/2,sz/2-3,sz/2+3]
y=[sz/2,sz/2+3,sz/2+3]
photons=[777,500,800]
bg=1f-4
datastate=BAMF.StateFlatBg(n,x,y,photons,bg)

##  create a model then make noisy
dataroi=BAMF.ArrayDD(sz)
BAMF.genmodel_2Dgauss!(datastate,sz,sigma,dataroi.data)
noisyroi=BAMF.poissrnd(dataroi)

## create a BAMF-type RJMCMC structure
xystd=sigma/10;
istd=10;
myRJ=BAMF.RJStructDD(sz,sigma,xystd,istd,noisyroi)

## setup the RJMCMC.jl model
#Jumptypes are: move, bg, add, remove, split, merge
njumptypes=6
jumpprobability=[1,0,0,0,0,0] #Move only
jumpprobability=jumpprobability/sum(jumpprobability)

# create an RJMCMC structure with all model info
iterations=5000
burnin=1000
acceptfuns=[BAMF.accept_move] #array of functions
propfuns=[BAMF.propose_move] #array of functions
myRJMCMC=RJMCMC.RJMCMCStruct(burnin,iterations,njumptypes,jumpprobability,propfuns,acceptfuns)

#create an intial state
state1=BAMF.calcintialstate(myRJ)

## run chain
@time mychain=RJMCMC.buildchain(myRJMCMC,myRJ,datastate)

## Display
zoom=Int32(20)
jts=mychain.jumptypes
plotly()
BAMF.histogram2D(mychain.states,sz,zoom,noisyroi,datastate)
