import common
import gleam/dict
import gleam/list
import gleam/io
import gleam/int
import gleam/string

fn split_halves(lines: List(String)) -> #(List(Int), List(Int)) {
  case lines {
    [line, ..rest] -> {
      let assert [x, y] = string.split(line, "   ")
      let assert Ok(x) = int.parse(x)
      let assert Ok(y) = int.parse(y)

      let #(a, b) = split_halves(rest)
      let a = [x, ..a]
      let b = [y, ..b]
      #(a, b)
    }
    [] -> #([], [])
  }
}

fn sum_sorted(a: List(Int), b: List(Int), accum: Int) -> Int {
  case a {
    [x, ..xs] -> {
      let assert [y, ..ys] = b
      let d = x - y
      let d = case d < 0 {
        True -> -d
        False -> d
      }
      sum_sorted(xs, ys, d + accum)
    }
    [] -> accum
  }
}

fn list_to_counts(a: List(Int), d: dict.Dict(Int, Int)) -> dict.Dict(Int, Int) {
  case a {
    [x, ..xs] -> {
      let count = case dict.get(d, x) {
        Ok(count) -> count
        Error(Nil) -> 0
      } + 1

      let d = d |> dict.insert(x, count)
      list_to_counts(xs, d)
    }
    [] -> d
  }
}

fn sim_score(a: List(Int), counts: dict.Dict(Int, Int), accum: Int) -> Int {
  case a {
    [x, ..xs] -> {
      let count = case dict.get(counts, x) {
        Ok(count) -> count
        Error(Nil) -> 0
      }
      let score = x * count

      let accum = accum + score
      sim_score(xs, counts, accum)
    }
    [] -> accum
  }
}

pub fn run() {
  let lines = common.read_input() |> string.trim() |> string.split(on: "\n")
  let #(a, b) = split_halves(lines)

  // Part 1
  let a = list.sort(a, int.compare)
  let b = list.sort(b, int.compare)
  let result = sum_sorted(a, b, 0)
  io.println(int.to_string(result))

  // Part 2
  let counts = list_to_counts(b, dict.new())
  let result = sim_score(a, counts, 0)
  io.println(int.to_string(result))
}
