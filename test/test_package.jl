using Test
using Mimi
##import Pkg

@testset "Packagation" begin

    # Pkg.activate("..")
    # Pkg.instantiate()

    using MimiPAGE2020

    m = getpage()
    run(m)

    ## Just test that this was successful
    @test typeof(m) <: Mimi.Model

end
