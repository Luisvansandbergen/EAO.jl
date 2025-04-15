#######################################################
# Test for EAO assets
# 
# Author: Luis van Sandbergen
# Date: 22.01.2025
#######################################################

using Test
using Dates

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

end