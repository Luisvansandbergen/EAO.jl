#######################################################
# Main file to handel the optimization
# 
# Author: Luis van Sandbergen
# Date: 17.12.2024
#######################################################

"""
Results

Collection of optimization results
"""
mutable struct Results
    value::Float64
    x::Array
    duals::Dict
end

"""
OptimProblem

Formulated MILP optimization problem.

"""
mutable struct OptimProblem
end