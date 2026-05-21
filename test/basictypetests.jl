#######################################################
# Test for basic types
# 
# Author: Luis van Sandbergen
# Date: 16.04.2025
#######################################################

using Test
using Dates
using EAO

@testset "Basic Types Tests" begin

    @testset "Node Tests" begin
        # Test if the node is created correctly
        node_1 = EAO.Node("node_1")
        node_2 = EAO.Node("node_2")

        @test node_1.name == "node_1"
        @test node_2.name == "node_2"
    end

    @testset "Timegrid Construction" begin
        # Simple hourly grid
        s = DateTime(2025, 1, 1, 0, 0)
        f = DateTime(2025, 1, 1, 3, 0)
        tg = EAO.Timegrid(start=s, finish=f, freq="H")
        @test tg.start == s
        @test tg.finish == f
        @test tg.dt == Hour(1)
        @test tg.times == [DateTime(2025,1,1,0,0),
                           DateTime(2025,1,1,1,0),
                           DateTime(2025,1,1,2,0),
                           DateTime(2025,1,1,3,0)]
        @test tg.T == 4
    
        # Non-aligned finish -- should append final point
        f2 = DateTime(2025, 1, 1, 2, 30)
        tg2 = EAO.Timegrid(start=s, finish=f2, freq="H")
        @test last(tg2.times) == f2
        @test tg2.T == 4  # 0:00,1:00,2:00 plus appended 3:00
    
        # 15-minute frequency
        f3 = DateTime(2025, 1, 1, 1, 0)
        tg3 = EAO.Timegrid(start=s, finish=f3, freq="15min")
        @test tg3.dt == Minute(15)
        @test tg3.T == 5  # 0:00,0:15,0:30,0:45,1:00
    
        # Invalid frequency should throw ErrorException
        @test_throws ErrorException EAO.Timegrid(start=s, finish=f, freq="X")
    end

    @testset "dt_in_hours" begin
        @test EAO.dt_in_hours(Minute(15)) == 0.25
        @test EAO.dt_in_hours(Minute(30)) == 0.5
        @test EAO.dt_in_hours(Minute(60)) == 1.0
        @test EAO.dt_in_hours(Hour(1))    == 1.0
        @test EAO.dt_in_hours(Hour(2))    == 2.0
        @test EAO.dt_in_hours(Day(1))     == 24.0
        @test EAO.dt_in_hours(Day(2))     == 48.0
        @test_throws ErrorException EAO.dt_in_hours(Month(1))
        @test_throws ErrorException EAO.dt_in_hours(Year(1))
    end

end