using Documenter

makedocs(
	sitename = "PAGE-ICE",
	pages = [
		"Home" => "index.md",
		"Getting started" => "gettingstarted.md",
		"Model Structure" => "model-structure.md",
		"Technical User Guide" => "technicaluserguide.md",
		"Model Validation" => "validation.md"]
)

deploydocs(
    repo = "github.com/openmodels/PAGE-ICE.git"
)
