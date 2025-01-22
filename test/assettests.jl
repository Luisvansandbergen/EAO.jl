#######################################################
# Test for EAO assets
# 
# Author: Luis van Sandbergen
# Date: 22.01.2025
#######################################################

using Test
using Dates

@testset "Asset Tests" begin

    # Test if the node is created correctly
    node_1 = EAO.Node("node_1")
    node_2 = EAO.Node("node_2")

    # Test if the contract is created correctly
    contract_1 = EAO.SimpleContract(name = "contract_1", 
                      nodes = node_1, 
                      start = DateTime(2024, 1, 1), 
                      finish = DateTime(2024, 1, 2),
                      price = "rand_price",
                      min_cap = 0.0,
                      max_cap = 1.0)

    # Set up prices
    prices = Dict("rand_price" => ones(24)*1)

    @test contract_1.name == "contract_1"
    @test contract_1.nodes == node_1
    @test contract_1.start == DateTime(2024, 1, 1)
    @test contract_1.finish == DateTime(2024, 1, 2)
    @test contract_1.price == "1"
    @test contract_1.min_cap == 0.0
    @test contract_1.max_cap == 1.0

end