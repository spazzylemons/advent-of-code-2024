import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/set.{type Set}
import gleam/string

pub type Point {
  Point(x: Int, y: Int)
}

pub type Input {
  Input(start: Point, end: Point, path: Set(Point))
}

pub fn parse(input: String) -> Input {
  let result = Input(Point(0, 0), Point(0, 0), set.new())
  let lines = string.split(input, "\n")
  use result, l, y <- list.index_fold(lines, result)
  use result, g, x <- list.index_fold(string.to_graphemes(l), result)
  let p = Point(x, y)
  case g {
    "#" -> result
    _ -> {
      let result = Input(..result, path: set.insert(result.path, p))
      case g {
        "S" -> Input(..result, start: p)
        "E" -> Input(..result, end: p)
        _ -> result
      }
    }
  }
}

fn try_directions(
  input: Input,
  positions: List(Point),
  acc: List(Point),
) -> List(Point) {
  case positions {
    [pos, ..positions] ->
      case set.contains(input.path, pos) {
        True -> do_time_path(input, pos, acc)
        False -> try_directions(input, positions, acc)
      }
    [] -> panic
  }
}

fn do_time_path(input: Input, pos: Point, acc: List(Point)) -> List(Point) {
  let acc = [pos, ..acc]
  let input = Input(..input, path: set.delete(input.path, pos))
  case pos == input.end {
    True -> list.reverse(acc)
    False ->
      try_directions(
        input,
        [
          Point(pos.x + 1, pos.y),
          Point(pos.x - 1, pos.y),
          Point(pos.x, pos.y + 1),
          Point(pos.x, pos.y - 1),
        ],
        acc,
      )
  }
}

fn time_path(input: Input) -> Dict(Point, Int) {
  let path = do_time_path(input, input.start, [])
  list.index_fold(path, dict.new(), dict.insert)
}

fn check_cheats(times: Dict(Point, Int)) -> Int {
  use acc, pos, time <- dict.fold(times, 0)
  use acc, new_pos <- list.fold(
    [
      Point(pos.x + 2, pos.y),
      Point(pos.x - 2, pos.y),
      Point(pos.x, pos.y + 2),
      Point(pos.x, pos.y - 2),
      Point(pos.x + 1, pos.y + 1),
      Point(pos.x - 1, pos.y + 1),
      Point(pos.x + 1, pos.y - 1),
      Point(pos.x - 1, pos.y - 1),
    ],
    acc,
  )
  case dict.get(times, new_pos) {
    Ok(new_time) -> {
      case new_time - time - 2 >= 100 {
        True -> acc + 1
        False -> acc
      }
    }
    Error(Nil) -> acc
  }
}

fn distance(a: Point, b: Point) -> Int {
  let dx = int.absolute_value(a.x - b.x)
  let dy = int.absolute_value(a.y - b.y)
  dx + dy
}

fn find_all_cheat_points(pos: Point, times: Dict(Point, Int)) -> List(Point) {
  use new_pos <- list.filter(dict.keys(times))
  distance(pos, new_pos) <= 20
}

fn check_new_cheats(times: Dict(Point, Int)) -> Int {
  use acc, pos, time <- dict.fold(times, 0)
  use acc, new_pos <- list.fold(find_all_cheat_points(pos, times), acc)
  let assert Ok(new_time) = dict.get(times, new_pos)
  case new_time - time - distance(pos, new_pos) >= 100 {
    True -> acc + 1
    False -> acc
  }
}

pub fn pt_1(input: Input) -> Int {
  time_path(input) |> check_cheats()
}

pub fn pt_2(input: Input) -> Int {
  time_path(input) |> check_new_cheats()
}
