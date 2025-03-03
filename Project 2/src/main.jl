using Revise

Base.include(Main, "solution_representation.jl")
using .SolutionStructs

Base.include(Main, "problem_instance.jl")
Base.include(Main, "genetic_algorithm.jl")
Base.include(Main, "save_solution.jl")

using .ProblemInstance
using .GeneticAlgorithm
using .SaveSolution

function run_program(instance_no::Int)
    instance = ProblemInstance.load_problem_instance("train/train_$instance_no.json")
    population = GeneticAlgorithm.initialize_population(instance["nbr_nurses"], instance["patients"], instance["travel_times"], instance["capacity_nurse"], instance["depot"]["return_time"], 1)

    sorted_population = sort(population, by=x -> x.total_travel_time)
    solution = sorted_population[1]
    SaveSolution.save_solution(solution, instance_no)
end

run_program(2)