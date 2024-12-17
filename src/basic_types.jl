## TODO: File with Objects for Timegrid and Optimization

# Define struct for Node
"""
Node

Struct to define a node in the optimization problem. A node is a (virtual) point, where
assets are located. In a node, the sum of all commodity flows must be zero.
Only one commodity may be present in each node. 
Per node we also define the units to be used for capacity (volume/energy and flow/capacity).
Examples are MWh and MW or liters and liters per minute.

"""
struct Node
    name::String
    commodity::Union{String, Nothing}  # Allow `commodity` to be `nothing`
end

# Constructor for Node with default value for commodity
Node(name::String) = Node(name, nothing)

"""
Timegrid

Struct to manage the timegrid used for the optimization.

"""
struct Timegrid
    start::DateTime
    finish::DateTime
    freq::String
    main_time_unit::String
end

# Constructor for Timegrid
#Timegrid(start::DateTime, finish::DateTime, freq, main_time_unit)