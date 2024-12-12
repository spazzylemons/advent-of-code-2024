import gleam/dict.{type Dict}
import gleam/list
import gleam/set.{type Set}
import gleam/string

pub type Point {
  Point(y: Int, x: Int)
}

type Region =
  Set(Point)

pub type Input =
  Dict(Point, Int)

type Dir {
  U
  D
  L
  R
}

type Fence {
  Fence(point: Point, dir: Dir)
}

pub fn parse(input: String) -> Input {
  let lines = string.split(input, "\n")
  let input = dict.new()
  use input, l, y <- list.index_fold(lines, input)
  use input, g, x <- list.index_fold(string.to_graphemes(l), input)
  let assert [i] = string.to_utf_codepoints(g)
  dict.insert(input, Point(y, x), string.utf_codepoint_to_int(i))
}

fn neighbor_by_dir(p: Point, d: Dir) -> Point {
  case d {
    U -> Point(y: p.y - 1, x: p.x)
    D -> Point(y: p.y + 1, x: p.x)
    L -> Point(y: p.y, x: p.x - 1)
    R -> Point(y: p.y, x: p.x + 1)
  }
}

fn perp_dir(d: Dir) -> Dir {
  case d {
    U -> R
    D -> L
    L -> U
    R -> D
  }
}

fn find_region(
  id: Int,
  state: Input,
  queue: List(Point),
  result: Region,
) -> #(Input, Region) {
  case queue {
    [] -> #(state, result)
    [point, ..rest] ->
      case dict.get(state, point) {
        Ok(i) if i == id -> {
          let state = dict.delete(state, point)
          let queue = [
            neighbor_by_dir(point, U),
            neighbor_by_dir(point, D),
            neighbor_by_dir(point, L),
            neighbor_by_dir(point, R),
            ..rest
          ]
          let result = set.insert(result, point)
          find_region(id, state, queue, result)
        }
        _ -> find_region(id, state, rest, result)
      }
  }
}

fn find_regions(state: Input, regions: List(Region)) -> List(Region) {
  case dict.keys(state) {
    [p, ..] -> {
      let assert Ok(id) = dict.get(state, p)
      let #(state, region) = find_region(id, state, [p], set.new())
      find_regions(state, [region, ..regions])
    }
    [] -> regions
  }
}

fn find_fences(region: Region) -> Set(Fence) {
  use result, point <- set.fold(region, set.new())
  use result, dir <- list.fold([U, D, L, R], result)
  let neighbor = neighbor_by_dir(point, dir)
  case set.contains(region, neighbor) {
    True -> result
    False -> set.insert(result, Fence(neighbor, dir))
  }
}

fn region_perimeter(region: Region, discount: Bool) -> Int {
  let fences = find_fences(region)
  let fences = case discount {
    True ->
      set.filter(fences, fn(fence) {
        let neighbor = neighbor_by_dir(fence.point, perp_dir(fence.dir))
        !set.contains(fences, Fence(neighbor, fence.dir))
      })
    False -> fences
  }
  set.size(fences)
}

fn region_area(region: Region) -> Int {
  set.size(region)
}

fn region_price(region: Region) -> Int {
  region_perimeter(region, False) * region_area(region)
}

fn discounted_region_price(region: Region) -> Int {
  region_perimeter(region, True) * region_area(region)
}

fn region_prices(input: Input, f: fn(Region) -> Int) -> Int {
  let regions = find_regions(input, [])
  use acc, region <- list.fold(regions, 0)
  acc + f(region)
}

pub fn pt_1(input: Input) -> Int {
  region_prices(input, region_price)
}

pub fn pt_2(input: Input) -> Int {
  region_prices(input, discounted_region_price)
}
