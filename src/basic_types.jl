## TODO: File with Objects for Timegrid and Optimization

# Define struct for Node
"""
Node

"""
struct Node
    name::String
    commodity::Union{String, Nothing}  # Allow `commodity` to be `nothing`
end

# Constructor for Node with default value for commodity
Node(name::String) = Node(name, nothing)

"""
Timegrid

"""
mutable struct Timegrid
    start::DateTime
    finish::DateTime
    freq::String
    main_time_unit::String
end