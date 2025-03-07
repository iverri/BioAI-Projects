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
    instance = ProblemInstance.load_problem_instance("test/test_$instance_no.json")
    solution = GeneticAlgorithm.genetic_algorithm(instance["nbr_nurses"], instance["patients"], instance["travel_times"], instance["capacity_nurse"], instance["depot"]["return_time"], 1000, 100, 50, 10, 0.3)
    SaveSolution.save_solution(solution, instance_no)
end

run_program(0)