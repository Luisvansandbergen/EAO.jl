#######################################################
# Test for EAO assets
# 
# Author: Luis van Sandbergen
# Date: 22.01.2025
#######################################################

using Test
using Dates
using EAO

@testset "Asset Tests" begin

@testset "SimpleContract Tests" begin
    # Test if the node is created correctly
    node_1 = EAO.Node("node_1")
    node_2 = EAO.Node("node_2")

    # Test if the contract is created correctly
    contract_1 = EAO.SimpleContract(
                    name = "contract_1", 
                    nodes = node_1, 
                    start = DateTime(2024, 1, 1), 
                    finish = DateTime(2024, 1, 2),
                    price = "rand_price",
                    min_cap = 0.0,
                    max_cap = 1.0
    )

    # Set up prices
    prices = Dict("rand_price" => ones(24)*1)

    @test contract_1.name == "contract_1"
    @test contract_1.nodes == node_1
    @test contract_1.start == DateTime(2024, 1, 1)
    @test contract_1.finish == DateTime(2024, 1, 2)
    @test contract_1.price == "rand_price"
    @test contract_1.min_cap == 0.0
    @test contract_1.max_cap == 1.0
end

@testset "Storage Tests" begin
    # Test if the node is created correctly
    node_1 = EAO.Node("node_1")
    node_2 = EAO.Node("node_2")

    # Test if the storage is created correctly
    storage_1 = EAO.Storage(
                    name = "storage_1", 
                    nodes = node_1, 
                    start = DateTime(2024, 1, 1), 
                    finish = DateTime(2024, 1, 2),
                    price = "rand_price",
                    cap_in = 10.0,
                    cap_out = 8.0,
                    size = 20.0,
                    discharge_eff = 0.95,
                    charge_eff = 0.95
    )

    @test storage_1.name == "storage_1"
    @test storage_1.nodes == node_1
    @test storage_1.start == DateTime(2024, 1, 1)
    @test storage_1.finish == DateTime(2024, 1, 2)
    @test storage_1.price == "rand_price"
    @test storage_1.cap_in == 10.0
    @test storage_1.cap_out == 8.0
    @test storage_1.size == 20.0
    @test storage_1.discharge_eff == 0.95
    @test storage_1.charge_eff == 0.95
end

@testset "PowerPlant Constructor" begin
    s = DateTime(2025,1,1)
    f = DateTime(2025,1,2)
    n1 = EAO.Node("1")
    n2 = EAO.Node("2")

    # Single node
    pp1 = EAO.PowerPlant("PP1", n1, s, f, "100", 10.0, 100.0)
    @test pp1.name == "PP1"
    @test pp1.nodes === n1
    @test pp1.start == s
    @test pp1.finish == f
    @test pp1.price == "100"
    @test pp1.min_cap == 10.0
    @test pp1.max_cap == 100.0

    # Multiple nodes
    pp2 = EAO.PowerPlant("PP2", [n1, n2], s, f, "200", 0.0, 50.0)
    @test isa(pp2.nodes, Vector{EAO.Node})
    @test pp2.nodes[1] === n1
    @test pp2.nodes[2] === n2

    # Invalid start > finish
    @test_throws ArgumentError EAO.PowerPlant("PP3", n1, f, s, "150", 5.0, 60.0)

    # Invalid min_cap > max_cap
    @test_throws ArgumentError EAO.PowerPlant("PP4", n1, s, f, "150", 100.0, 50.0)
end

end