using Test
using Mimi

@testset "Packagation" begin

    import MimiPAGE2020

    m = MimiPAGE2020.getpage()
    run(m)

    ## Just test that this was successful
    @test typeof(m) <: Mimi.Model

end
