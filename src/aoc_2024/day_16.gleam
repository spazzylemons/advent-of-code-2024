import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

type PQueue {
  PQueue(values: Dict(Int, Path), indices: Dict(State, Int))
}

pub type Point {
  Point(x: Int, y: Int)
}

pub type Dir {
  U
  D
  L
  R
}

type State {
  State(pos: Point, dir: Dir)
}

type Path {
  Path(cost: Int, heuristic: Int, state: State, seen: Set(Point))
}

pub type Maze {
  Maze(start: Point, end: Point, walls: Set(Point))
}

fn pq_new() -> PQueue {
  PQueue(dict.new(), dict.new())
}

fn cmp_paths(a: Path, b: Path) -> Bool {
  a.cost + a.heuristic <= b.cost + b.heuristic
}

fn sift_up(pq: PQueue, child_pos: Int) -> PQueue {
  let parent_pos = { child_pos - 1 } / 2
  let assert Ok(child) = dict.get(pq.values, child_pos)
  let assert Ok(parent) = dict.get(pq.values, parent_pos)
  use <- bool.guard(cmp_paths(parent, child), pq)
  let values =
    pq.values
    |> dict.insert(child_pos, parent)
    |> dict.insert(parent_pos, child)
  let indices =
    pq.indices
    |> dict.insert(parent.state, child_pos)
    |> dict.insert(child.state, parent_pos)
  sift_up(PQueue(values, indices), parent_pos)
}

fn do_insert(pq: PQueue, path: Path) -> PQueue {
  let pos = dict.size(pq.values)
  let values = dict.insert(pq.values, pos, path)
  let indices = dict.insert(pq.indices, path.state, pos)
  sift_up(PQueue(values, indices), pos)
}

fn pq_insert(pq: PQueue, path: Path) -> PQueue {
  case dict.get(pq.indices, path.state) {
    Ok(old_index) -> {
      let assert Ok(old) = dict.get(pq.values, old_index)
      use <- bool.guard(path.cost > old.cost, pq)
      let pq = pq_remove_at(pq, old_index)
      let path = Path(..path, seen: set.union(path.seen, old.seen))
      do_insert(pq, path)
    }
    Error(Nil) -> do_insert(pq, path)
  }
}

fn sift_down(pq: PQueue, pos: Int) -> PQueue {
  let assert Ok(v) = dict.get(pq.values, pos)
  let l_pos = { pos * 2 } + 1
  let r_pos = l_pos + 1
  let l_small =
    dict.get(pq.values, l_pos)
    |> result.try(fn(l) {
      case cmp_paths(v, l) {
        True -> Error(Nil)
        False -> Ok(#(l_pos, l))
      }
    })
  let r_small =
    dict.get(pq.values, r_pos)
    |> result.try(fn(r) {
      case cmp_paths(v, r) {
        True -> Error(Nil)
        False -> Ok(#(r_pos, r))
      }
    })
  let smallest = case l_small, r_small {
    Error(Nil), Error(Nil) -> Error(Nil)
    Ok(s), Error(Nil) -> Ok(s)
    Error(Nil), Ok(s) -> Ok(s)
    Ok(#(_, l)), Ok(#(_, r)) ->
      case cmp_paths(l, r) {
        True -> Ok(#(l_pos, l))
        False -> Ok(#(r_pos, r))
      }
  }
  case smallest {
    Ok(#(child_pos, child)) -> {
      let values =
        pq.values
        |> dict.insert(child_pos, v)
        |> dict.insert(pos, child)
      let indices =
        pq.indices
        |> dict.insert(child.state, pos)
        |> dict.insert(v.state, child_pos)
      sift_down(PQueue(values, indices), child_pos)
    }
    Error(Nil) -> pq
  }
}

fn pq_remove_at(pq: PQueue, pos: Int) -> PQueue {
  let last_pos = dict.size(pq.values) - 1
  let assert Ok(old_value) = dict.get(pq.values, pos)
  let assert Ok(new_value) = dict.get(pq.values, last_pos)
  let values =
    pq.values
    |> dict.insert(pos, new_value)
    |> dict.delete(last_pos)
  let indices =
    pq.indices
    |> dict.insert(new_value.state, pos)
    |> dict.delete(old_value.state)
  let pq = PQueue(values: values, indices: indices)
  case dict.has_key(pq.values, pos) {
    True -> sift_down(pq, pos)
    False -> pq
  }
}

fn pq_remove(pq: PQueue) -> Result(#(Path, PQueue), Nil) {
  use path <- result.try(dict.get(pq.values, 0))
  let pq = pq_remove_at(pq, 0)
  Ok(#(path, pq))
}

fn cw(dir: Dir) -> Dir {
  case dir {
    U -> R
    D -> L
    L -> U
    R -> D
  }
}

fn ccw(dir: Dir) -> Dir {
  case dir {
    U -> L
    D -> R
    L -> D
    R -> U
  }
}

fn flip(dir: Dir) -> Dir {
  case dir {
    U -> D
    D -> U
    L -> R
    R -> L
  }
}

fn move_point(point: Point, dir: Dir) -> Point {
  case dir {
    U -> Point(point.x, point.y - 1)
    D -> Point(point.x, point.y + 1)
    L -> Point(point.x - 1, point.y)
    R -> Point(point.x + 1, point.y)
  }
}

fn heuristic(maze: Maze, pos: Point) -> Int {
  let dx = int.absolute_value(maze.end.x - pos.x)
  let dy = int.absolute_value(maze.end.y - pos.y)
  dx + dy
}

fn path_new(maze: Maze, cost: Int, state: State, seen: Set(Point)) -> Path {
  Path(
    cost: cost,
    heuristic: heuristic(maze, state.pos),
    state: state,
    seen: seen,
  )
}

fn try_next_path(
  acc: List(Path),
  maze: Maze,
  path: Path,
  dir: Dir,
  cost: Int,
) -> List(Path) {
  let next_pos = move_point(path.state.pos, dir)
  use <- bool.guard(
    set.contains(path.seen, next_pos) || set.contains(maze.walls, next_pos),
    acc,
  )
  let new_path =
    path_new(
      maze,
      path.cost + cost,
      State(next_pos, dir),
      set.insert(path.seen, next_pos),
    )
  [new_path, ..acc]
}

fn find_next_paths(maze: Maze, path: Path) -> List(Path) {
  []
  |> try_next_path(maze, path, path.state.dir, 1)
  |> try_next_path(maze, path, cw(path.state.dir), 1001)
  |> try_next_path(maze, path, ccw(path.state.dir), 1001)
  |> try_next_path(maze, path, flip(path.state.dir), 2001)
}

fn do_astar(maze: Maze, pq: PQueue) -> Int {
  let assert Ok(#(path, pq)) = pq_remove(pq)
  use <- bool.guard(path.state.pos == maze.end, path.cost)
  let pq = list.fold(find_next_paths(maze, path), pq, pq_insert)
  do_astar(maze, pq)
}

fn do_astar_pt2(
  maze: Maze,
  pq: PQueue,
  best_cost: Result(Int, Nil),
  accum: Set(Point),
) -> Int {
  case pq_remove(pq) {
    Error(Nil) -> set.size(accum)
    Ok(#(path, pq)) -> {
      case path.state.pos == maze.end {
        True -> {
          let best_cost = case best_cost {
            Ok(_) -> best_cost
            Error(Nil) -> Ok(path.cost)
          }
          do_astar_pt2(maze, pq, best_cost, set.union(accum, path.seen))
        }
        False -> {
          let folder = case best_cost {
            Ok(best_cost) -> fn(pq: PQueue, path: Path) {
              case path.cost <= best_cost {
                True -> pq_insert(pq, path)
                False -> pq
              }
            }
            Error(Nil) -> pq_insert
          }
          let pq = list.fold(find_next_paths(maze, path), pq, folder)
          do_astar_pt2(maze, pq, best_cost, accum)
        }
      }
    }
  }
}

pub fn parse(input: String) -> Maze {
  let result = Maze(Point(0, 0), Point(0, 0), set.new())
  let lines = string.split(input, "\n")
  use result, l, y <- list.index_fold(lines, result)
  use result, g, x <- list.index_fold(string.to_graphemes(l), result)
  let p = Point(x, y)
  case g {
    "S" -> Maze(..result, start: p)
    "E" -> Maze(..result, end: p)
    "#" -> Maze(..result, walls: set.insert(result.walls, p))
    _ -> result
  }
}

pub fn pt_1(maze: Maze) -> Int {
  let pq = pq_new()
  let pq =
    pq_insert(
      pq,
      path_new(maze, 0, State(maze.start, R), set.from_list([maze.start])),
    )
  do_astar(maze, pq)
}

pub fn pt_2(maze: Maze) -> Int {
  let pq = pq_new()
  let pq =
    pq_insert(
      pq,
      path_new(maze, 0, State(maze.start, R), set.from_list([maze.start])),
    )
  do_astar_pt2(maze, pq, Error(Nil), set.new())
}
