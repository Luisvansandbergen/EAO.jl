#######################################################
# Test for the Portfolio setup
# 
# Author: Luis van Sandbergen
# Date: 19.01.2025
#######################################################

using Test
using Dates
using JuMP
using EAO
using DataFrames
import HiGHS

@testset "Portfolio Tests" begin

@testset "Node Tests" begin  
    # Test if the node is created correctly
    node_1 = EAO.Node("node_1")
    node_2 = EAO.Node("node_2")

    @test node_1.name == "node_1"
    @test node_2.name == "node_2"
end

@testset "Portfolio creation" begin

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

# @testset "SimpleContract Tests" begin
#     # Test if the node is created correctly
#     node_1 = EAO.Node("node_1")
#     node_2 = EAO.Node("node_2")

#     # Set up timegrid
#     timegrid = EAO.Timegrid(DateTime(2024, 1, 1), DateTime(2024, 1, 2), "H", "H")

#     # Set up contract
#     a1 = EAO.Contract(name = "contract_1", 
#                       nodes = node_1, 
#                       start = DateTime(2024, 1, 1), 
#                       finish = DateTime(2024, 1, 2),
#                       price = "rand_price",
#                       min_cap = 0.0,
#                       max_cap = 1.0
#                       )

#     # Set up prices
#     prices = Dict("rand_price" => ones(24)*1)

#     # Set up portfolio
#     portf = EAO.Portfolio(assets = [a1])

#     # Set up optimization problem
#     op_std = setup_optim_problem(portf, prices = prices, timegrid = timegrid)

#     # Solve optimization problem
#     res_std = optimize(op_std)

#     @test res_std.value == 1.0

# end

end