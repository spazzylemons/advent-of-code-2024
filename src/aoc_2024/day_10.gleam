import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string

pub type Point {
  Point(y: Int, x: Int)
}

pub type Input =
  Dict(Point, Int)

pub fn parse(input: String) -> Input {
  let lines = string.split(input, "\n")
  let input = dict.new()
  use input, l, y <- list.index_fold(lines, input)
  use input, g, x <- list.index_fold(string.to_graphemes(l), input)
  let assert Ok(i) = int.parse(g)
  dict.insert(input, Point(y, x), i)
}

fn find_starting_points(input: Input) -> List(Point) {
  input
  |> dict.filter(fn(_, v) { v == 0 })
  |> dict.keys()
}

fn find_next_locations(input: Input, p: Point, height: Int) -> List(Point) {
  let neighbors = [
    Point(p.y - 1, p.x),
    Point(p.y + 1, p.x),
    Point(p.y, p.x - 1),
    Point(p.y, p.x + 1),
  ]
  use p <- list.filter(neighbors)
  dict.get(input, p) == Ok(height)
}

fn iterate(
  state: Dict(Point, a),
  input: Input,
  height: Int,
  f: fn(a, a) -> a,
) -> Dict(Point, a) {
  case height {
    10 -> state
    _ -> {
      let state =
        dict.fold(state, dict.new(), fn(acc, p, v) {
          let next =
            find_next_locations(input, p, height) |> list.map(fn(n) { #(n, v) })
          use acc, p <- list.fold(next, acc)
          let #(n, v) = p
          use o <- dict.upsert(acc, n)
          case o {
            Some(o) -> f(o, v)
            None -> v
          }
        })
      iterate(state, input, height + 1, f)
    }
  }
}

pub fn pt_1(input: Input) -> Int {
  find_starting_points(input)
  |> list.map(fn(v) { #(v, set.from_list([v])) })
  |> dict.from_list()
  |> iterate(input, 1, set.union)
  |> dict.fold(0, fn(acc, _, v) { acc + set.size(v) })
}

pub fn pt_2(input: Input) -> Int {
  find_starting_points(input)
  |> list.map(fn(v) { #(v, 1) })
  |> dict.from_list()
  |> iterate(input, 1, int.add)
  |> dict.fold(0, fn(acc, _, v) { acc + v })
}
