import gleam/bool
import gleam/list
import gleam/string
import rememo/memo

pub type Input {
  Input(patterns: List(String), designs: List(String))
}

pub fn parse(input: String) -> Input {
  let assert [patterns, _, ..designs] = string.split(input, "\n")
  let patterns = string.split(patterns, ", ")
  Input(patterns, designs)
}

fn check_design(patterns: List(String), design: String, cache) -> Bool {
  use <- memo.memoize(cache, design)
  case design {
    "" -> True
    _ -> {
      let d = string.length(design)
      use pattern <- list.any(patterns)
      use <- bool.guard(!string.starts_with(design, pattern), False)
      let p = string.length(pattern)
      check_design(patterns, string.slice(design, p, d - p), cache)
    }
  }
}

fn count_designs(patterns: List(String), design: String, cache) -> Int {
  use <- memo.memoize(cache, design)
  case list.filter(patterns, fn(pattern) { string.starts_with(design, pattern) }) {
    [] -> 0
    matched_patterns -> {
      let d = string.length(design)
      use acc, pattern <- list.fold(matched_patterns, 0)
      let p = string.length(pattern)
      use <- bool.guard(p == d, acc + 1)
      let design = string.slice(design, p, d - p)
      acc + count_designs(patterns, design, cache)
    }
  }
}

pub fn pt_1(input: Input) {
  use cache <- memo.create()
  use design <- list.count(input.designs)
  check_design(input.patterns, design, cache)
}

pub fn pt_2(input: Input) {
  use cache <- memo.create()
  use acc, design <- list.fold(input.designs, 0)
  acc + count_designs(input.patterns, design, cache)
}
