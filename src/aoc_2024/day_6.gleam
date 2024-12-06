import gleam/list
import gleam/otp/task
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub type Point {
  Point(y: Int, x: Int)
}

type Dir {
  U
  D
  L
  R
}

pub type Map {
  Map(obs: Set(Point), w: Int, h: Int)
}

pub type Input {
  Input(pos: Point, map: Map)
}

type Guard {
  Guard(pos: Point, dir: Dir)
}

fn move_point(point: Point, dir: Dir) -> Point {
  case dir {
    U -> Point(y: point.y - 1, x: point.x)
    D -> Point(y: point.y + 1, x: point.x)
    L -> Point(y: point.y, x: point.x - 1)
    R -> Point(y: point.y, x: point.x + 1)
  }
}

fn clockwise(dir: Dir) -> Dir {
  case dir {
    U -> R
    D -> L
    L -> U
    R -> D
  }
}

fn in_bounds(map: Map, point: Point) -> Bool {
  point.x >= 0 && point.y >= 0 && point.x < map.w && point.y < map.h
}

pub fn parse(input: String) -> Input {
  let lines = string.split(input, "\n")

  let result =
    Input(
      pos: Point(0, 0),
      map: Map(
        obs: set.new(),
        w: list.first(lines) |> result.unwrap("") |> string.length(),
        h: list.length(lines),
      ),
    )

  use result, l, y <- list.index_fold(lines, result)
  use result, g, x <- list.index_fold(string.to_graphemes(l), result)

  case g {
    "^" -> Input(..result, pos: Point(y, x))
    "#" ->
      Input(
        ..result,
        map: Map(..result.map, obs: set.insert(result.map.obs, Point(y, x))),
      )
    _ -> result
  }
}

fn move_guard(map: Map, guard: Guard) -> Result(Guard, Nil) {
  let new_pos = move_point(guard.pos, guard.dir)
  case in_bounds(map, new_pos) {
    True ->
      Ok(case set.contains(map.obs, new_pos) {
        True -> Guard(..guard, dir: clockwise(guard.dir))
        False -> Guard(..guard, pos: new_pos)
      })
    False -> Error(Nil)
  }
}

fn get_guard_positions_loop(
  map: Map,
  guard: Guard,
  seen: List(Guard),
) -> List(Guard) {
  let seen = [guard, ..seen]
  case move_guard(map, guard) {
    Ok(guard) -> get_guard_positions_loop(map, guard, seen)
    Error(Nil) -> seen
  }
}

fn get_guard_positions(input: Input) -> List(Guard) {
  get_guard_positions_loop(input.map, Guard(pos: input.pos, dir: U), [])
}

pub fn pt_1(input: Input) -> Int {
  let positions = get_guard_positions(input)
  list.map(positions, fn(guard) { guard.pos }) |> list.unique() |> list.length()
}

fn check_for_loop_loop(map: Map, guard: Guard, seen: Set(Guard)) -> Bool {
  case set.contains(seen, guard) {
    True -> True
    False ->
      case move_guard(map, guard) {
        Ok(new_guard) -> {
          let seen = set.insert(seen, guard)
          check_for_loop_loop(map, new_guard, seen)
        }
        Error(Nil) -> False
      }
  }
}

fn check_for_loop(input: Input) -> Bool {
  check_for_loop_loop(input.map, Guard(pos: input.pos, dir: U), set.new())
}

pub fn pt_2(input: Input) -> Int {
  let positions = get_guard_positions(input)
  // Skip starting state when checking where to place obstructions
  let assert [_, ..positions] = list.reverse(positions)
  let positions = list.map(positions, fn(guard) { guard.pos }) |> list.unique()

  let tasks =
    list.map(positions, fn(o) {
      task.async(fn() {
        let obs = set.insert(input.map.obs, o)
        let map = Map(..input.map, obs: obs)
        let input = Input(..input, map: map)
        check_for_loop(input)
      })
    })

  use t <- list.count(tasks)
  let assert Ok(t) = task.try_await(t, 1000)
  t
}
