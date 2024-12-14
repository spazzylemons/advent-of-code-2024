import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/regexp
import gleam/set.{type Set}

const width = 101

const height = 103

pub type Point {
  Point(x: Int, y: Int)
}

pub type Robot {
  Robot(p: Point, v: Point)
}

type Input =
  List(Robot)

type SafetyScores {
  SafetyScores(tl: Int, tr: Int, bl: Int, br: Int)
}

pub fn parse(input: String) -> Input {
  let assert Ok(r) =
    regexp.compile(
      "p=(\\d+),(\\d+) v=(-?\\d+),(-?\\d+)",
      regexp.Options(False, False),
    )
  let matches = regexp.scan(r, input)
  use match <- list.map(matches)
  let assert [px, py, vx, vy] =
    match.submatches
    |> list.map(fn(match) {
      let assert Some(value) = match
      let assert Ok(value) = int.parse(value)
      value
    })
  Robot(p: Point(px, py), v: Point(vx, vy))
}

fn posmod(x: Int, y: Int) -> Int {
  let value = x % y
  case value < 0 {
    True -> value + y
    False -> value
  }
}

fn move_robot(robot: Robot, seconds: Int) -> Point {
  Point(
    x: posmod(robot.p.x + robot.v.x * seconds, width),
    y: posmod(robot.p.y + robot.v.y * seconds, height),
  )
}

fn add_safety_scores(list: List(Point), acc: SafetyScores) -> SafetyScores {
  case list {
    [point, ..rest] -> {
      let acc = case int.compare(point.x, width / 2) {
        Eq -> acc
        Lt ->
          case int.compare(point.y, height / 2) {
            Eq -> acc
            Lt -> SafetyScores(..acc, tl: acc.tl + 1)
            Gt -> SafetyScores(..acc, bl: acc.bl + 1)
          }
        Gt ->
          case int.compare(point.y, height / 2) {
            Eq -> acc
            Lt -> SafetyScores(..acc, tr: acc.tr + 1)
            Gt -> SafetyScores(..acc, br: acc.br + 1)
          }
      }
      add_safety_scores(rest, acc)
    }
    [] -> acc
  }
}

fn safety_factor(s: SafetyScores) -> Int {
  s.tl * s.tr * s.bl * s.br
}

fn christmas_heuristic_column(
  d: Set(Point),
  x: Int,
  y_values: List(Int),
  count: Int,
) -> Bool {
  case count == 10 {
    True -> True
    False ->
      case y_values {
        [y, ..rest] -> {
          let count = case set.contains(d, Point(x, y)) {
            True -> count + 1
            False -> 0
          }
          christmas_heuristic_column(d, x, rest, count)
        }
        [] -> False
      }
  }
}

fn christmas_heuristic(d: Set(Point)) -> Bool {
  let x_values = list.range(0, width - 1)
  let y_values = list.range(0, height - 1)

  use x <- list.any(x_values)
  christmas_heuristic_column(d, x, y_values, 0)
}

fn check_for_tree(points: List(Point)) -> Bool {
  let d = list.fold(points, set.new(), set.insert)
  christmas_heuristic(d)
}

fn iterate_tree_check(robots: Input, seconds: Int) -> Int {
  case check_for_tree(list.map(robots, fn(robot) { robot.p })) {
    True -> seconds
    False -> {
      let robots =
        list.map(robots, fn(robot) { Robot(..robot, p: move_robot(robot, 1)) })
      iterate_tree_check(robots, seconds + 1)
    }
  }
}

pub fn pt_1(input: Input) -> Int {
  input
  |> list.map(fn(robot) { move_robot(robot, 100) })
  |> add_safety_scores(SafetyScores(0, 0, 0, 0))
  |> safety_factor
}

pub fn pt_2(input: Input) -> Int {
  iterate_tree_check(input, 0)
}
