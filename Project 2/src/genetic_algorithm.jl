module GeneticAlgorithm

using ..SolutionStructs
using Random
using StatsBase

export genetic_algorithm

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
            best_patient, current_time = greedy_shortest(current_patient, Float64(current_time), current_demand, remaining_patients, travel_matrix, nurse_capacity, depot_return_time, patients)
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
    selected_parents = Vector{Solution}()
    for i in 1:n_parents
        tournament = rand(1:length(population), tournament_size)
        winner = argmin([solution.total_travel_time for solution in population[tournament]])
        push!(selected_parents, population[tournament[winner]])
    end
    return selected_parents
end

function crossover(parent1::Solution, parent2::Solution, n_patients::Int, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int, patients::Dict{String,Any}, n_routes::Int=2)
    child_routes = [SolutionStructs.Route([], 0, 0.0) for _ in 1:n_routes]
    parent1_copy = deepcopy(parent1)
    parent2_copy = deepcopy(parent2)
    remaining_patients = Set{Int}(1:n_patients)

    for route in child_routes
        if rand() < 0.5
            potential_route = popat!(parent1_copy.routes, rand(1:length(parent1_copy.routes)))
            if union(remaining_patients, Set{Int}(potential_route.patients)) == remaining_patients
                route.patients = potential_route.patients
                for patient in route.patients
                    delete!(remaining_patients, patient)
                end
            end
        else
            potential_route = popat!(parent2_copy.routes, rand(1:length(parent2_copy.routes)))
            if union(remaining_patients, Set{Int}(potential_route.patients)) == remaining_patients
                route.patients = potential_route.patients
                for patient in route.patients
                    delete!(remaining_patients, patient)
                end
            end
        end
    end

    for route in child_routes
        if isempty(route.patients)
            current_patient = 0
            current_time = 0.0
            current_demand = 0
            while current_time + travel_matrix[current_patient+1][1] < depot_return_time && current_demand < nurse_capacity && !isempty(remaining_patients)
                best_patient, current_time = greedy_shortest(current_patient, Float64(current_time), current_demand, remaining_patients, travel_matrix, nurse_capacity, depot_return_time, patients)
                if best_patient == 0
                    break
                end
                push!(route.patients, best_patient)
                current_time += travel_matrix[current_patient+1][best_patient+1]
                current_demand += patients[string(best_patient)]["demand"]
                current_patient = best_patient
                delete!(remaining_patients, best_patient)
            end
            route.total_demand = current_demand
        end
    end

    for route in child_routes
        route.total_travel_time = update_travel_time(route, travel_matrix)
    end

    if sum([route.total_demand for route in child_routes]) > nurse_capacity || isempty(remaining_patients)
        child = initialize_solution(n_routes, patients, travel_matrix, nurse_capacity, depot_return_time)
        return child
    end

    child = SolutionStructs.Solution(child_routes, sum([route.total_travel_time for route in child_routes]))
    return child
end

function mutation(solution::Solution, mutation_rate::Float64, nurse_capacity::Int, depot_return_time::Int, patients::Dict{String,Any}, travel_matrix::Vector{Any})
    mutated_routes = deepcopy(solution.routes)
    route1, route2 = randperm(length(mutated_routes))[1:2]

    if !isempty(mutated_routes[route1].patients)
        i = rand(1:length(mutated_routes[route1].patients))
        patient = popat!(mutated_routes[route1].patients, i)

        if length(mutated_routes[route2].patients) == 0
            push!(mutated_routes[route2].patients, patient)
        else
            for i in 1:length(mutated_routes[route2].patients)
                route_copy = deepcopy(mutated_routes[route2])
                insert!(route_copy.patients, i, patient)
                if check_constraints(route_copy, travel_matrix, depot_return_time, nurse_capacity, patients)
                    mutated_routes[route2].patients = route_copy.patients

                    mutated_routes[route1].total_demand -= patients[string(patient)]["demand"]
                    mutated_routes[route1].total_travel_time = update_travel_time(mutated_routes[route1], travel_matrix)

                    mutated_routes[route2].total_demand += patients[string(patient)]["demand"]
                    mutated_routes[route1].total_travel_time = update_travel_time(mutated_routes[route2], travel_matrix)

                    solution.routes = mutated_routes
                    solution.total_travel_time = sum([route.total_travel_time for route in solution.routes])
                    break
                end
            end
        end
    end
    return solution
end


function crossover_mutation(parent1::Solution, parent2::Solution, n_patients::Int, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int, mutation_rate::Float64, patients::Dict{String,Any}, n_routes::Int)
    child = crossover(parent1, parent2, n_patients, travel_matrix, nurse_capacity, depot_return_time, patients, n_routes)
    if rand() < mutation_rate
        mutated = mutation(child, mutation_rate, nurse_capacity, depot_return_time, patients, travel_matrix)
        return mutated
    end
    return child
end

function genetic_algorithm(n_nurses::Int, patients::Dict{String,Any}, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int, population_size::Int, n_generations::Int, n_parents::Int, tournament_size::Int, mutation_rate::Float64)
    population = initialize_population(n_nurses, patients, travel_matrix, nurse_capacity, depot_return_time, population_size)
    for i in 1:n_generations
        selected_parents = solution_selection(population, n_parents, tournament_size)
        children = Vector{Solution}()
        for j in 1:population_size
            parent1, parent2 = sample(selected_parents, 2, replace=false)
            push!(children, crossover_mutation(parent1, parent2, length(patients), travel_matrix, nurse_capacity, depot_return_time, mutation_rate, patients, n_nurses))
        end
        population = select_survivors(selected_parents, children, population_size)
        if i % 10 == 0
            println("Generation $i: $(population[1].total_travel_time)")
        end
    end
    sort!(population, by=x -> x.total_travel_time)
    return population[1]
end

function select_survivors(old_gen::Vector{Solution}, new_gen::Vector{Solution}, n_survivors::Int)
    population = vcat(old_gen, new_gen)
    return sort(population, by=x -> x.total_travel_time)[1:n_survivors]
end




function check_constraints(route::SolutionStructs.Route, travel_matrix::Vector{Any}, depot_return_time::Int, nurse_capacity::Int, patients::Dict{String,Any})
    current_patient = 0
    current_time = 0.0
    current_demand = 0
    for patient in route.patients
        travel_time = travel_matrix[current_patient+1][patient+1]
        arrival_time = current_time + travel_time
        if arrival_time < patients[string(patient)]["start_time"]
            arrival_time = patients[string(patient)]["start_time"]
        end
        finish_time = arrival_time + patients[string(patient)]["care_time"]
        if finish_time > patients[string(patient)]["end_time"] || finish_time + travel_matrix[patient+1][1] > depot_return_time || current_demand + patients[string(patient)]["demand"] > nurse_capacity
            return false
        end
        current_time = finish_time
        current_demand += patients[string(patient)]["demand"]
        current_patient = patient
    end
    return true
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


function update_travel_time(route::SolutionStructs.Route, travel_matrix::Vector{Any})
    if isempty(route.patients)
        return Inf
    else
        route.total_travel_time = 0.0
        route.total_travel_time = travel_matrix[1][route.patients[1]]
        for i in 1:length(route.patients)-1
            route.total_travel_time += travel_matrix[route.patients[i]][route.patients[i+1]]
        end
        route.total_travel_time += travel_matrix[route.patients[end]][1]
    end
    return route.total_travel_time
end

end