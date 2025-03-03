mutable struct Route
    patients::Vector{Int}
    total_demand::Int
    total__travel_time::Float64
end

mutable struct Solution
    routes::Vector{Route}
    total_travel_time::Float64
end