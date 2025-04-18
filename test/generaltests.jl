#######################################################
# Test for general usage of EAO.jl
# 
# Author: Luis van Sandbergen
# Date: 18.04.2025
#######################################################

using Test
using Dates
using JuMP
using EAO
using DataFrames
import HiGHS

@testset "General Tests" begin

    @testset "SimpleContract creation" begin

        # 1) create nodes
    nodeA = EAO.Node("NodeA", nothing)
    nodeB = EAO.Node("NodeB", "Power")

    # 2) create assets
    powerplant = EAO.PowerPlant(
        "PP", 
        nodeA,
        DateTime(2024, 1, 1, 0),
        DateTime(2024, 1, 1, 3),
        "market_price",
        0.0,
        10.0
    )

    contract = EAO.SimpleContract(
        name = "SC", 
        nodes = nodeA, 
        start = DateTime(2024, 1, 1, 0), 
        finish = DateTime(2024, 1, 1, 3),
        price = "market_price",
        min_cap = -10.0,
        max_cap = 10.0
    )

    # 3) create portfolio
    portf = EAO.Portfolio([powerplant, contract])

    # 4) define timegrid steps
    timegrid = EAO.Timegrid(
        start = DateTime(2024, 1, 1, 0),
        finish = DateTime(2024, 1, 1, 3),
        freq = "H"
    )

    # 5) define prices
    prices = Dict(
        "market_price" => [50.0, 40.0, 60.0, 55.0]  # z.B. €/MWh
    )

    # 6) build JuMP model
    solver = HiGHS.Optimizer
    op = EAO.setup_optim_problem(portf, timegrid, prices, solver)

    print(op)

    # 7) solve
    JuMP.optimize!(op)

    println("Solver status: ", termination_status(op))
    println("Objective Value: ", objective_value(op))

    # after solve!
    all_vars = all_variables(op)
    println("All variables: ", all_vars)

    x = all_variables(op)
    res = DataFrame(
    Value = value.(x),
    )

    println("=== Results ===")
    println(res)

    # dispatch_contract = contract.variables[:dispatch]
    # println("=== Ergebnisse Contract ===")
    # for t in 1:T
    #     println(" t = $t : dispatch = ", value(dispatch_contract[t]))
    # end

    end

end