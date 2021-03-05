

using Markdown
using InteractiveUtils

"""
Package is in my julia dev folder. If it isn't replace the bottom with

include("OpenFOAM.jl")
using .OpenFOAM, Plots, LaTeXStrings
"""
using Pkg
Pkg.develop("OpenFOAM")
using OpenFOAM, Plots, LaTeXStrings

"""
All folders are discretized as NxNx1
"""
N = 160

"""
Input: base folder path
Output: value for ν

Reads "constant/transportProperties" into String
Strips each line of trailing and leading spaces
Finds line starting with "nu"
Gets last value split by spaces
Removes last character (gets rid of semi-colon)
Parse as Float
"""
function nuvalue(x)
	first(map(y -> parse(Float64, split(strip(y))[end][1:end-1]), filter(startswith("nu"), split(read(joinpath(x, "constant/transportProperties"), String), "\n"))))
end

"""
Input: base folder path
Output: value for Re

L is assumed 0.1, U is assumed 1
"""
function reynolds(x)
	0.1 / nuvalue(x)
end

"""
Input: base folder path
Output: unstructured internal field

Note that the field is unstructured. For this case, the 
field is an NxNx1, but in future cases should be careful
about reshaping.
"""
function forcevalue(x)
	OpenFOAM.parse_internal_field(joinpath(x, "0.5/U"))
end

"""
Input: unstructured internal field
Output: normalized structured internal field values
"""
ỹ(x) = reshape(map(x -> x[1] / .1, x), (N, N))'

"""
Base directory used in this case. Note that only the folders starting with "cavitynu" were used in the figures seen in the paper. Other folders in "folder" will cause different figures to generate.
"""
folder = joinpath(dirname(@__FILE__), "foamfiles")

"""
Produces pairs of Re, ỹ

For each folder
	- Get absolute path
	- Get internal field
	- Normalize internal field
	- Get Reynolds number
	- Emit pair Re, ỹ
"""
rawdata = map(y -> reynolds(y) => ỹ(forcevalue(y)), map(x -> joinpath(folder, x), readdir(folder)))

"""
Input: x and y values
Output: integration of y over the domain of x

Perform trapezoidal integration
"""
function integrate(x, y)
	sum(map(i -> (y[i - 1] + y[i]) * (x[i] - x[i - 1]) / 2, 2:length(x)))
end

"""
For each folder
	- take the finite difference at the lid wrt y
	- integrate it over domain of [0, 1]
	- create pair of Re, F̃
"""
pldata = map(x -> x[1] => integrate((1:N)./N,(x[2][end, 1:end] .- x[2][end-1, 1:end]) * N / .1), rawdata)

"""
Get normalized internal field for Re = 10
"""
ux = filter(x -> x[1] == 10, rawdata)[1][2]

"""
Take finite difference of ux wrt ỹ
"""
tau = (ux[end, 1:end] .- ux[end-1, 1:end]) * N / .1

"""
Plot normalized shear stress vs normalized horizontal distance along lid
"""
tout = plot(range(0, 1, length=length(tau)), tau, xlabel=L"\widetilde{x}", ylabel=L"\widetilde{\tau}", legend=nothing, title=L"\textrm{Shear Stress on Lid } (Re = 10)")
savefig(tout, "/home/watson/tau.png")

"""
Plot Normalized Force vs Reynolds number
"""
lf = scatter(map(x -> x[1], pldata), map(x -> x[2], pldata), xlabel=L"Re", ylabel=L"\widetilde{F}", legend=nothing, title=L"\textrm{Lid Force}")
savefig(lf, "/home/watson/lf.png")