import gleam/bool
import gleam/int
import gleam/list
import gleam/order
import gleam/string

type Input = List(List(Int))

fn are_numbers_safe(a: Int, b: Int, direction: order.Order) -> Bool {
  use <- bool.guard(a == b, False)

  let diff = int.absolute_value(b - a)
  use <- bool.guard(diff == 0 || diff > 3, False)

  direction == order.Eq || direction == int.compare(b, a)
}

fn safety_check(l: List(Int), direction: order.Order, can_remove: Bool) -> Bool {
  case l {
    [a, b, c, ..xs] -> {
      let new_direction = int.compare(b, a)
      let is_safe = are_numbers_safe(a, b, direction) && are_numbers_safe(b, c, new_direction)
      case is_safe, can_remove {
        True, _ -> safety_check([b, c, ..xs], new_direction, can_remove)
        False, True -> {
          { safety_check([a, c, ..xs], direction, False) } ||
          { safety_check([a, b, ..xs], direction, False) } ||
          { safety_check([b, c, ..xs], direction, False) }
        }
        False, False -> False
      }
    }
    [a, b] -> are_numbers_safe(a, b, direction)
    _ -> True
  }
}

fn run_part1(numbers: List(Int)) -> Bool {
  safety_check(numbers, order.Eq, False)
}

fn run_part2(numbers: List(Int)) -> Bool {
  safety_check(numbers, order.Eq, True)
}

fn parse_line(report: String) -> List(Int) {
  report |> string.split(" ") |> list.filter_map(int.parse)
}

pub fn parse(input: String) -> Input {
  input |> string.split("\n") |> list.map(parse_line)
}

pub fn pt_1(input: Input) -> Int {
  list.count(input, run_part1)
}

pub fn pt_2(input: Input) -> Int {
  list.count(input, run_part2)
}
