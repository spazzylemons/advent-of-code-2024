import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub type Point {
  Point(y: Int, x: Int)
}

pub type Input {
  Input(w: Int, h: Int, groups: Dict(String, List(Point)))
}

fn add_point(a: Point, b: Point) -> Point {
  Point(y: a.y + b.y, x: a.x + b.x)
}

fn sub_point(a: Point, b: Point) -> Point {
  Point(y: a.y - b.y, x: a.x - b.x)
}

fn in_bounds(w: Int, h: Int, p: Point) -> Bool {
  p.x >= 0 && p.x < w && p.y >= 0 && p.y < h
}

pub fn parse(input: String) -> Input {
  let lines = string.split(input, "\n")
  let input =
    Input(
      w: list.first(lines) |> result.unwrap("") |> string.length(),
      h: list.length(lines),
      groups: dict.new(),
    )
  use input, l, y <- list.index_fold(lines, input)
  use input, g, x <- list.index_fold(string.to_graphemes(l), input)
  case g {
    "." -> input
    _ -> {
      let p = Point(y, x)
      let groups =
        dict.upsert(input.groups, g, fn(l) {
          case l {
            Some(l) -> [p, ..l]
            None -> [p]
          }
        })
      Input(..input, groups: groups)
    }
  }
}

fn iterate_pairs(
  points: List(Point),
  f: fn(Set(Point), Point, Point) -> Set(Point),
) -> Set(Point) {
  let p = list.combinations(points, 2)
  use acc, pair <- list.fold(p, set.new())
  let assert [a, b] = pair
  f(acc, a, b)
}

fn find_pt1_antinodes(w: Int, h: Int, points: List(Point)) -> Set(Point) {
  use antinodes, a, b <- iterate_pairs(points)
  let diff = sub_point(a, b)
  let anti_a = add_point(a, diff)
  let anti_b = sub_point(b, diff)

  let antinodes = case in_bounds(w, h, anti_a) {
    True -> set.insert(antinodes, anti_a)
    False -> antinodes
  }
  let antinodes = case in_bounds(w, h, anti_b) {
    True -> set.insert(antinodes, anti_b)
    False -> antinodes
  }
  antinodes
}

fn find_harmonics(
  w: Int,
  h: Int,
  point: Point,
  delta: Point,
  acc: Set(Point),
) -> Set(Point) {
  case in_bounds(w, h, point) {
    True -> {
      let acc = set.insert(acc, point)
      let point = add_point(point, delta)
      find_harmonics(w, h, point, delta, acc)
    }
    False -> acc
  }
}

fn find_pt2_antinodes(w: Int, h: Int, points: List(Point)) -> Set(Point) {
  use antinodes, a, b <- iterate_pairs(points)
  let antinodes = find_harmonics(w, h, a, sub_point(a, b), antinodes)
  let antinodes = find_harmonics(w, h, b, sub_point(b, a), antinodes)
  antinodes
}

fn count_antinodes(
  input: Input,
  filter: fn(Int, Int, List(Point)) -> Set(Point),
) -> Int {
  let antinodes =
    dict.fold(input.groups, set.new(), fn(antinodes, k, v) {
      let _ = k
      antinodes |> set.union(filter(input.w, input.h, v))
    })
  set.size(antinodes)
}

pub fn pt_1(input: Input) -> Int {
  count_antinodes(input, find_pt1_antinodes)
}

pub fn pt_2(input: Input) -> Int {
  count_antinodes(input, find_pt2_antinodes)
}
