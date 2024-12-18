import aoc_2024/pqueue.{type PQueue}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/set.{type Set}
import gleam/string

pub type Point {
  Point(x: Int, y: Int)
}

fn can_go_to(space: Space, point: Point) -> Bool {
  !set.contains(space.bytes, point)
  && point.x >= 0
  && point.x < space.w
  && point.y >= 0
  && point.y < space.h
}

fn find_next_paths(space: Space, point: Point) -> List(Point) {
  [
    Point(point.x, point.y - 1),
    Point(point.x, point.y + 1),
    Point(point.x - 1, point.y),
    Point(point.x + 1, point.y),
  ]
  |> list.filter(fn(p) { can_go_to(space, p) })
}

fn do_dijkstra(
  space: Space,
  dist: Dict(Point, Int),
  pq: PQueue(Point),
) -> Result(Int, Nil) {
  case pqueue.remove(pq) {
    Ok(#(u, pq)) -> {
      let assert Ok(du) = dict.get(dist, u)
      let alt = du + 1
      let #(dist, pq) =
        list.fold(find_next_paths(space, u), #(dist, pq), fn(acc, v) {
          let #(dist, pq) = acc
          let insert_alt = case dict.get(dist, v) {
            Ok(dv) -> alt < dv
            Error(Nil) -> True
          }
          case insert_alt {
            True -> {
              let dist = dict.insert(dist, v, alt)
              let pq = pqueue.insert(pq, v, alt)
              #(dist, pq)
            }
            False -> #(dist, pq)
          }
        })
      do_dijkstra(space, dist, pq)
    }
    Error(Nil) -> dict.get(dist, space.goal)
  }
}

fn fast_queue_concat(next: List(Point), queue: List(Point)) -> List(Point) {
  case next {
    [x, ..xs] -> fast_queue_concat(xs, [x, ..queue])
    [] -> queue
  }
}

fn flood_fill(space: Space, queue: List(Point)) -> Bool {
  case set.contains(space.bytes, space.goal) {
    True -> True
    False ->
      case queue {
        [] -> False
        [point, ..queue] ->
          case set.contains(space.bytes, point) {
            True -> flood_fill(space, queue)
            False -> {
              let space = Space(..space, bytes: set.insert(space.bytes, point))
              let queue =
                fast_queue_concat(find_next_paths(space, point), queue)
              flood_fill(space, queue)
            }
          }
      }
  }
}

fn dijkstra(space: Space) -> Result(Int, Nil) {
  let source = Point(0, 0)
  let pq = pqueue.new()
  let dist = dict.from_list([#(source, 0)])
  let pq = pqueue.insert(pq, source, 0)
  do_dijkstra(space, dist, pq)
}

type Space {
  Space(w: Int, h: Int, goal: Point, bytes: Set(Point))
}

type Input =
  List(Point)

pub fn parse(input: String) -> Input {
  let lines = string.split(input, "\n")
  use line <- list.map(lines)
  let assert [x, y] = string.split(line, ",") |> list.filter_map(int.parse)
  Point(x, y)
}

fn input_to_space(input: Input) -> Space {
  let bytes = list.fold(input, set.new(), set.insert)
  Space(w: 71, h: 71, goal: Point(70, 70), bytes: bytes)
}

fn find_first_cutoff(l: List(Point), acc: List(Point)) -> Point {
  let assert [x, ..xs] = l
  let space = input_to_space(acc)
  case flood_fill(space, [Point(0, 0)]) {
    True -> find_first_cutoff(xs, [x, ..acc])
    False -> {
      let assert [x, ..] = acc
      x
    }
  }
}

pub fn pt_1(input: Input) {
  let first_kb = list.take(input, 1024)
  let space = input_to_space(first_kb)
  let assert Ok(v) = dijkstra(space)
  v
}

pub fn pt_2(input: Input) {
  let Point(x, y) = find_first_cutoff(input, [])
  int.to_string(x) <> "," <> int.to_string(y)
}
