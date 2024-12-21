import carpenter/table
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleam/set.{type Set}
import gleam/string
import rememo/memo

type Point {
  Point(x: Int, y: Int)
}

type KeyMap =
  Dict(#(Point, Point), List(List(Point)))

type Cache =
  table.Set(#(Int, Point, Point), Int)

type State {
  State(
    numpad: KeyMap,
    arrow: KeyMap,
    remaining: Int,
    cache: table.Set(#(Int, Point, Point), Int),
  )
}

fn state_new(remaining: Int, cache: Cache) -> State {
  State(
    numpad: key_map_new([
      Point(0, 0),
      Point(1, 0),
      Point(2, 0),
      Point(0, 1),
      Point(1, 1),
      Point(2, 1),
      Point(0, 2),
      Point(1, 2),
      Point(2, 2),
      Point(1, 3),
      Point(2, 3),
    ]),
    arrow: key_map_new([
      Point(1, 0),
      Point(2, 0),
      Point(0, 1),
      Point(1, 1),
      Point(2, 1),
    ]),
    remaining: remaining,
    cache: cache,
  )
}

fn key_map_new(b: List(Point)) -> KeyMap {
  let points = set.from_list(b)
  use acc, from <- list.fold(b, dict.new())
  use acc, to <- list.fold(b, acc)
  dict.insert(acc, #(from, to), find_paths(points, from, to))
}

fn find_paths(points: Set(Point), from: Point, to: Point) -> List(List(Point)) {
  let p = case int.compare(from.x, to.x) {
    Gt -> [#(Point(0, 1), Point(from.x - 1, from.y))]
    Lt -> [#(Point(2, 1), Point(from.x + 1, from.y))]
    Eq -> []
  }
  let p = case int.compare(from.y, to.y) {
    Lt -> [#(Point(1, 1), Point(from.x, from.y + 1)), ..p]
    Gt -> [#(Point(1, 0), Point(from.x, from.y - 1)), ..p]
    Eq -> p
  }
  case p {
    [] -> [[Point(2, 0)]]
    _ -> {
      let p = list.filter(p, fn(x) { set.contains(points, x.1) })
      use acc, path <- list.fold(p, [])
      let new_paths = find_paths(points, path.1, to)
      use acc, new_path <- list.fold(new_paths, acc)
      [[path.0, ..new_path], ..acc]
    }
  }
}

fn do_total_cost(
  state: State,
  from: Point,
  sequence: List(Point),
  km: KeyMap,
) -> #(Int, Point) {
  use #(sum, from), to <- list.fold(sequence, #(0, from))
  let sum =
    sum
    + {
      use <- memo.memoize(state.cache, #(state.remaining, from, to))
      let assert Ok(paths) = dict.get(km, #(from, to))
      case state.remaining {
        0 -> {
          let assert [p, ..] = paths
          list.length(p)
        }
        _ -> {
          let state = State(..state, remaining: state.remaining - 1)
          let from = Point(2, 0)
          use min, path <- list.fold(paths, -1)
          let value = total_cost(state, from, path, state.arrow)
          case min == -1 || value < min {
            True -> value
            False -> min
          }
        }
      }
    }
  #(sum, to)
}

fn total_cost(
  state: State,
  from: Point,
  sequence: List(Point),
  km: KeyMap,
) -> Int {
  do_total_cost(state, from, sequence, km).0
}

fn bingus(state: State, x: List(Point)) -> Int {
  total_cost(state, Point(2, 3), x, state.numpad)
}

fn code_to_points(line: String) -> List(Point) {
  use c <- list.map(string.to_graphemes(line))
  case c {
    "7" -> Point(0, 0)
    "8" -> Point(1, 0)
    "9" -> Point(2, 0)
    "4" -> Point(0, 1)
    "5" -> Point(1, 1)
    "6" -> Point(2, 1)
    "1" -> Point(0, 2)
    "2" -> Point(1, 2)
    "3" -> Point(2, 2)
    "0" -> Point(1, 3)
    "A" -> Point(2, 3)
    _ -> panic
  }
}

fn total_costs(state: State, lines: List(String)) -> Int {
  use sum, line <- list.fold(lines, 0)
  let length = bingus(state, code_to_points(line))
  let assert Ok(numeric) =
    string.slice(line, 0, string.length(line) - 1) |> int.parse()
  sum + { length * numeric }
}

pub fn parse(input: String) -> List(String) {
  input |> string.split("\n")
}

pub fn pt_1(input: List(String)) -> Int {
  use cache <- memo.create()
  let state = state_new(2, cache)
  total_costs(state, input)
}

pub fn pt_2(input: List(String)) -> Int {
  use cache <- memo.create()
  let state = state_new(25, cache)
  total_costs(state, input)
}
