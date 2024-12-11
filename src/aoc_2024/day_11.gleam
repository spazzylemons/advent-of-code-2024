import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string

type Input =
  Dict(Int, Int)

pub fn parse(input: String) -> Input {
  let stones =
    input
    |> string.split(" ")
    |> list.filter_map(int.parse)
  use state, stone <- list.fold(stones, dict.new())
  use old_value <- dict.upsert(state, stone)
  case old_value {
    Some(count) -> count + 1
    None -> 1
  }
}

fn count_digits(x: Int, acc: Int) -> Int {
  case x < 10 {
    True -> acc
    False -> count_digits(x / 10, acc + 1)
  }
}

fn digit_multiplier(count: Int, acc: Int) -> Int {
  case count {
    0 -> acc
    _ -> digit_multiplier(count - 1, acc * 10)
  }
}

fn step(state: Input) -> Input {
  dict.fold(state, dict.new(), fn(acc, k, v) {
    let new_values = case k {
      0 -> [#(1, v)]
      _ ->
        case count_digits(k, 1) {
          count if count % 2 == 0 -> {
            let m = digit_multiplier(count / 2, 1)
            [#(k / m, v), #(k % m, v)]
          }
          _ -> [#(2024 * k, v)]
        }
    }
    use acc, #(k, v) <- list.fold(new_values, acc)
    use o <- dict.upsert(acc, k)
    case o {
      Some(o) -> o + v
      None -> v
    }
  })
}

fn calculate(state: Input, count: Int) -> Int {
  case count {
    0 -> dict.fold(state, 0, fn(acc, _, v) { acc + v })
    _ -> calculate(step(state), count - 1)
  }
}

pub fn pt_1(input: Input) -> Int {
  calculate(input, 25)
}

pub fn pt_2(input: Input) -> Int {
  calculate(input, 75)
}
