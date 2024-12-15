import gleam/dict.{type Dict}
import gleam/list
import gleam/string

pub type Point {
  Point(x: Int, y: Int)
}

pub type Tile {
  Wall
  Box
  LBox
  RBox
}

pub type Maze =
  Dict(Point, Tile)

pub type Dir {
  U
  D
  L
  R
}

pub type Input {
  Input(robot: Point, maze: Maze, moves: List(Dir))
}

type MoveState {
  MoveState(maze: Maze, pushed: Maze)
}

fn parse_maze(input: String) -> #(Point, Maze) {
  let result = #(Point(0, 0), dict.new())
  let lines = string.split(input, "\n")
  use result, l, y <- list.index_fold(lines, result)
  use result, g, x <- list.index_fold(string.to_graphemes(l), result)
  let #(robot, maze) = result
  let robot = case g {
    "@" -> Point(x, y)
    _ -> robot
  }
  let maze = case g {
    "#" -> dict.insert(maze, Point(x, y), Wall)
    "O" -> dict.insert(maze, Point(x, y), Box)
    _ -> maze
  }
  #(robot, maze)
}

fn parse_moves(input: String) -> List(Dir) {
  use g <- list.filter_map(string.to_graphemes(input))
  case g {
    "^" -> Ok(U)
    "v" -> Ok(D)
    "<" -> Ok(L)
    ">" -> Ok(R)
    _ -> Error(Nil)
  }
}

pub fn parse(input: String) -> Input {
  let assert [maze, moves] = string.split(input, "\n\n")
  let #(robot, maze) = parse_maze(maze)
  let moves = parse_moves(moves)
  Input(robot, maze, moves)
}

fn move_point(point: Point, dir: Dir) -> Point {
  case dir {
    U -> Point(point.x, point.y - 1)
    D -> Point(point.x, point.y + 1)
    L -> Point(point.x - 1, point.y)
    R -> Point(point.x + 1, point.y)
  }
}

fn do_find_movable_tiles(state: MoveState, point: Point, dir: Dir) -> MoveState {
  case dict.get(state.maze, point) {
    Ok(Box) -> {
      MoveState(
        maze: state.maze |> dict.delete(point),
        pushed: state.pushed |> dict.insert(point, Box),
      )
      |> do_find_movable_tiles(move_point(point, dir), dir)
    }
    Ok(LBox) -> {
      let other = move_point(point, R)
      MoveState(
        maze: state.maze |> dict.delete(point) |> dict.delete(other),
        pushed: state.pushed
          |> dict.insert(point, LBox)
          |> dict.insert(other, RBox),
      )
      |> do_find_movable_tiles(move_point(point, dir), dir)
      |> do_find_movable_tiles(move_point(other, dir), dir)
    }
    Ok(RBox) -> {
      let other = move_point(point, L)
      MoveState(
        maze: state.maze |> dict.delete(point) |> dict.delete(other),
        pushed: state.pushed
          |> dict.insert(point, RBox)
          |> dict.insert(other, LBox),
      )
      |> do_find_movable_tiles(move_point(point, dir), dir)
      |> do_find_movable_tiles(move_point(other, dir), dir)
    }
    _ -> state
  }
}

fn find_movable_tiles(maze: Maze, point: Point, dir: Dir) -> MoveState {
  do_find_movable_tiles(MoveState(maze, dict.new()), point, dir)
}

fn try_push_tiles(
  maze: Maze,
  tiles: List(#(Point, Tile)),
  dir: Dir,
) -> Result(Maze, Nil) {
  case tiles {
    [#(point, tile), ..tiles] -> {
      let next_point = move_point(point, dir)
      case dict.has_key(maze, next_point) {
        True -> Error(Nil)
        False -> {
          let maze = dict.insert(maze, next_point, tile)
          try_push_tiles(maze, tiles, dir)
        }
      }
    }
    [] -> Ok(maze)
  }
}

fn push_tiles(maze: Maze, point: Point, dir: Dir) -> Result(Maze, Nil) {
  let state = find_movable_tiles(maze, move_point(point, dir), dir)
  try_push_tiles(state.maze, dict.to_list(state.pushed), dir)
}

fn run_move(robot: Point, maze: Maze, dir: Dir) -> #(Point, Maze) {
  let next_point = move_point(robot, dir)
  case dict.get(maze, next_point) {
    Ok(Wall) -> #(robot, maze)
    _ ->
      case push_tiles(maze, robot, dir) {
        Ok(maze) -> #(next_point, maze)
        Error(Nil) -> #(robot, maze)
      }
  }
}

fn do_run_moves(input: Input) -> #(Point, Maze) {
  use #(robot, maze), dir <- list.fold(input.moves, #(input.robot, input.maze))
  run_move(robot, maze, dir)
}

fn run_moves(input: Input) -> Int {
  do_run_moves(input).1 |> gps_sum()
}

fn gps_sum(maze: Maze) -> Int {
  use sum, Point(x, y), tile <- dict.fold(maze, 0)
  case tile {
    Box | LBox -> { y * 100 + x } + sum
    _ -> sum
  }
}

pub fn pt_1(input: Input) -> Int {
  run_moves(input)
}

fn scale_up_maze(maze: Maze) -> Maze {
  use maze, Point(x, y), tile <- dict.fold(maze, dict.new())
  let l = Point(2 * x, y)
  let r = Point(2 * x + 1, y)
  case tile {
    Box -> maze |> dict.insert(l, LBox) |> dict.insert(r, RBox)
    _ -> maze |> dict.insert(l, tile) |> dict.insert(r, tile)
  }
}

fn scale_up_input(input: Input) -> Input {
  let maze = scale_up_maze(input.maze)
  let robot = Point(2 * input.robot.x, input.robot.y)
  Input(robot, maze, input.moves)
}

pub fn pt_2(input: Input) -> Int {
  scale_up_input(input) |> run_moves()
}
