#######################################################
# Main file to handle the optimization
#
# Author: Luis van Sandbergen
# Date: 17.12.2024
#######################################################

"""
    Results

Collection of optimization results.

# Fields
- `value::Float64`: Objective function value
- `x::Dict{String, Float64}`: Variable values keyed by variable name
- `duals::Dict`: Dual values (empty for MIP problems)
"""
mutable struct Results
    value::Float64
    x::Dict{String, Float64}
    duals::Dict
end

"""
    OptimProblem

Formulated MILP optimization problem (placeholder for future extensions).
"""
mutable struct OptimProblem
end

"""
    run_optimization(portfolio, tg, price_dict, solver) -> Results

Build the JuMP model from the portfolio, solve it, and return structured Results.

Throws an error if the solver does not find an optimal solution.
"""
function run_optimization(
    portfolio::Portfolio,
    tg::Timegrid,
    price_dict::Dict{String,Vector{Float64}},
    solver
)
    model = setup_optim_problem(portfolio, tg, price_dict, solver)
    #set_silent(model)
    optimize!(model)

    status = termination_status(model)
    if status != MOI.OPTIMAL
        error("Optimization did not find an optimal solution. Status: $status")
    end

    obj_val = objective_value(model)

    # Extract variable values keyed by name
    x_dict = Dict{String, Float64}()
    for v in all_variables(model)
        x_dict[name(v)] = value(v)
    end

    return Results(obj_val, x_dict, Dict())
end
