using Documenter

makedocs(
	sitename = "mimi-page-2020.jl",
	pages = [
		"Home" => "index.md",
		"Getting started" => "gettingstarted.md",
		"Model Structure" => "model-structure.md",
		"Technical User Guide" => "technicaluserguide.md",
		"Model Validation" => "validation.md"]
)

deploydocs(
    repo = "github.com/openmodels/mimi-page-2020.jl.git"
)
