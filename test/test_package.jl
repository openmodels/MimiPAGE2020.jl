using Test
using Mimi

@testset "Packagation" begin

    using MimiPAGE2020

    m = getpage()
    run(m)

    ## Just test that this was successful
    @test typeof(m) <: Mimi.Model

end
