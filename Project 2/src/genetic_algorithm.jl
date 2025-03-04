module GeneticAlgorithm

using ..SolutionStructs
using Random
using StatsBase

export initialize_solution, initialize_population, solution_selection, crossover

function initialize_solution(n_nurses::Int, patients::Dict{String,Any}, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int)

    routes = [SolutionStructs.Route([], 0, 0.0) for _ in 1:n_nurses]
    solution = SolutionStructs.Solution([], 0.0)
    remaining_patients = Set{Int}(1:length(patients))

    for route in routes
        if isempty(patients)
            break
        end
        current_patient = 0
        current_time = 0.0
        current_demand = 0
        while true
            best_patient, current_time = greedy_shortest(current_patient, current_time, current_demand, remaining_patients, travel_matrix, nurse_capacity, depot_return_time, patients)
            if best_patient == 0
                break
            end
            push!(route.patients, best_patient)
            current_time += travel_matrix[current_patient+1][current_patient+1]
            current_demand += patients[string(best_patient)]["demand"]
            current_patient = best_patient
            delete!(remaining_patients, best_patient)
        end
        route.total_travel_time = current_time + travel_matrix[current_patient+1][1]
        route.total_demand = current_demand
    end

    solution.routes = routes
    solution.total_travel_time = sum([route.total_travel_time for route in routes])
    return solution
end

function initialize_population(n_nurses::Int, patients::Dict{String,Any}, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int, population_size::Int)
    return [initialize_solution(n_nurses, patients, travel_matrix, nurse_capacity, depot_return_time) for i in 1:population_size]
end

function solution_selection(population::Vector{Solution}, n_parents::Int, tournament_size::Int)
    selected_parents = []
    for i in 1:n_parents
        tournament = rand(1:length(population), tournament_size)
        winner = argmin([solution.total_travel_time for solution in population[tournament]])
        push!(selected_parents, population[tournament[winner]])
    end
    return selected_parents
end

function crossover(parent1::Solution, parent2::Solution, n_patients::Int, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int)
    all_patients = Set{Int}(1:n_patients)
    assigned_patients = Set{Int}()

    n_routes = max(length(parent1.routes), length(parent2.routes))
    child_routes = Vector{SolutionStructs.Route}()
    selected_routes = sample(parent1.routes, rand(1:n_routes))

    for route in selected_routes
        push!(child_routes, deepcopy(route))
        assigned_patients = assigned_patients ∪ Set(route.patients)
    end

    for route in parent2.routes
        if all(route.patients .∈ assigned_patients)
            push!(child_routes, deepcopy(route))
            assigned_patients = assigned_patients ∪ Set(route.patients)
        end
    end

    missing_patients = setdiff(all_patients, assigned_patients)
    leftover_routes = n_routes - length(child_routes)

    for i in 1:leftover_routes
        if isempty(missing_patients)
            break
        end
        current_patient = 0
        current_time = 0.0
        current_demand = 0
        route = SolutionStructs.Route([], 0, 0.0)
        while true
            best_patient, current_time = greedy_shortest(current_patient, current_time, current_demand, missing_patients, travel_matrix, nurse_capacity, depot_return_time, patients)
            if best_patient == 0
                break
            end
            push!(route.patients, best_patient)
            current_demand += patients[string(best_patient)]["demand"]
            current_patient = best_patient
            delete!(missing_patients, best_patient)
        end
        push!(child_routes, route)
    end

    child = SolutionStructs.Solution(child_routes, 0.0)
    child.total_travel_time = sum([route.total_travel_time for route in child.routes])
    return child
end

function greedy_shortest(current_patient::Int, current_time::Float64, current_demand::Int, available_patients::Set{Int}, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int, patients::Dict{String,Any})
    shortest = Inf
    best_patient = 0
    finish_time = current_time
    for patient in available_patients
        travel_time = travel_matrix[current_patient+1][patient+1]
        if travel_time < shortest
            potential_patient = patients[string(patient)]
            arrival_time = current_time + travel_time
            if arrival_time < potential_patient["start_time"]
                arrival_time = potential_patient["start_time"]
            end
            finish_time = arrival_time + potential_patient["care_time"]
            if finish_time > potential_patient["end_time"] || finish_time + travel_matrix[patient+1][1] > depot_return_time || current_demand + potential_patient["demand"] > nurse_capacity
                continue
            end
            shortest = travel_time
            best_patient = patient
        end
    end
    return best_patient, finish_time


end

end