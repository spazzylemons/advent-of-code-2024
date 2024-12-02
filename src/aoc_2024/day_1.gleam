import gleam/dict
import gleam/list
import gleam/int
import gleam/result
import gleam/string

type Input = #(List(Int), List(Int))

fn split_halves(lines: List(String), accum: Input) -> Input {
  case lines {
    [line, ..rest] -> {
      let assert [x, y] = string.split(line, "   ")
      let assert Ok(x) = int.parse(x)
      let assert Ok(y) = int.parse(y)

      let #(a, b) = accum
      let a = [x, ..a]
      let b = [y, ..b]
      split_halves(rest, #(a, b))
    }
    [] -> accum
  }
}

fn sum_sorted(list: List(#(Int, Int)), accum: Int) -> Int {
  case list {
    [#(x, y), ..rest] -> {
      let d = int.absolute_value(x - y)
      sum_sorted(rest, d + accum)
    }
    [] -> accum
  }
}

fn list_to_counts(a: List(Int), d: dict.Dict(Int, Int)) -> dict.Dict(Int, Int) {
  case a {
    [x, ..xs] -> {
      let count = dict.get(d, x) |> result.unwrap(0)
      let d = d |> dict.insert(x, count + 1)
      list_to_counts(xs, d)
    }
    [] -> d
  }
}

fn sim_score(a: List(Int), counts: dict.Dict(Int, Int), accum: Int) -> Int {
  case a {
    [x, ..xs] -> {
      let count = dict.get(counts, x) |> result.unwrap(0)
      let accum = accum + x * count
      sim_score(xs, counts, accum)
    }
    [] -> accum
  }
}

pub fn parse(input: String) -> Input {
  let lines = input |> string.split("\n")
  split_halves(lines, #([], []))
}

pub fn pt_1(input: Input) -> Int {
  let #(a, b) = input
  let a = list.sort(a, int.compare)
  let b = list.sort(b, int.compare)
  sum_sorted(list.zip(a, b), 0)
}

pub fn pt_2(input: Input) -> Int {
  let #(a, b) = input
  let counts = list_to_counts(b, dict.new())
  sim_score(a, counts, 0)
}
