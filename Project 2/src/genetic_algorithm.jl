using .ProblemInstance
using .SolutionStructs
using Random


function initialize_solution(n_nurses::Int, patients::Dict{String,Any}, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int)

    randomized_patients = shuffle(1:length(patients))
    routes = [SolutionStructs.Route([1], 0, 0.0) for _ in 1:n_nurses]

    for patient_number in randomized_patients

        patient = patients[string(patient_number)]

        for route in routes

            if route.total_demand + patient["demand"] > nurse_capacity # check capacity constraint
                continue
            end

            travel_time = travel_matrix[route.patients[end]+1][patient_number+1] # time from last patient in route to potential new patient
            arrival_time = route.total_travel_time + travel_time
            if arrival_time < patient["start_time"] # cannot start before patient's start time -> wait
                arrival_time = patient["start_time"]
            end

            finish_time = arrival_time + patient["care_time"] # time to care for patient

            if finish_time > patient["end_time"] || finish_time + travel_matrix[patient_number+1][1] > depot_return_time # check time window constraint
                continue
            end

            push!(route.patients, patient_number)
            route.total_demand += patient["demand"]
            route.total_travel_time += travel_time + finish_time
            break

        end
    end

    for route in routes
        push!(route.patients, 1) # return to depot
        route.total_travel_time += travel_matrix[route.patients[end-1]][1] # time from last patient to depot

    end

    total_travel_time = sum([route.total_travel_time for route in routes])
    return SolutionStructs.Solution(routes, total_travel_time)
end

function initialize_population(n_nurses::Int, patients::Dict{String,Any}, travel_matrix::Vector{Any}, nurse_capacity::Int, depot_return_time::Int, population_size::Int)
    return [initialize_solution(n_nurses, patients, travel_matrix, nurse_capacity, depot_return_time) for i in 1:population_size]
end

instance = ProblemInstance.load_problem_instance("train/train_0.json")
population = initialize_population(instance["nbr_nurses"], instance["patients"], instance["travel_times"], instance["capacity_nurse"], instance["depot"]["return_time"], 10)
