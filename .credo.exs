%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/"],
        excluded: []
      },
      strict: true,
      checks: [
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Readability.AliasOrder, false},
        {Credo.Check.Warning.IoInspect, priority: :high},
        {Credo.Check.Readability.Specs, []}
      ]
    }
  ]
}
