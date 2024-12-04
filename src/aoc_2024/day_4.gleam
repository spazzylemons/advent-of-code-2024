import gleam/dict
import gleam/list
import gleam/string

pub type Letter {
  X
  M
  A
  S
}

type Key =
  #(Int, Int)

type Input =
  dict.Dict(Key, Letter)

const directions: List(Key) = [
  #(-1, -1), #(0, -1), #(1, -1), #(1, 0), #(1, 1), #(0, 1), #(-1, 1), #(-1, 0),
]

pub fn parse(input: String) -> Input {
  let lines = string.split(input, "\n")
  let result = dict.new()
  use result, line, y <- list.index_fold(lines, result)
  use result, grapheme, x <- list.index_fold(string.to_graphemes(line), result)
  dict.insert(result, #(x, y), case grapheme {
    "X" -> X
    "M" -> M
    "A" -> A
    "S" -> S
    _ -> panic
  })
}

fn add_delta(key: Key, delta: Key) -> Key {
  let #(x, y) = key
  let #(dx, dy) = delta
  #(x + dx, y + dy)
}

fn check_xmas_direction(
  input: Input,
  key: Key,
  delta: Key,
  remaining: List(Letter),
) -> Bool {
  case remaining {
    [x, ..xs] ->
      case dict.get(input, key) {
        Ok(y) if y == x -> {
          let key = add_delta(key, delta)
          check_xmas_direction(input, key, delta, xs)
        }
        _ -> False
      }
    [] -> True
  }
}

fn check_xmas(input: Input, keys: List(Key), delta: Key) -> Int {
  use matching_keys <- list.count(keys)
  let key = add_delta(matching_keys, delta)
  check_xmas_direction(input, key, delta, [M, A, S])
}

fn check_x_mas(input: Input, key: Key) -> Bool {
  let a = add_delta(key, #(-1, -1))
  let b = add_delta(key, #(1, 1))
  case dict.get(input, a), dict.get(input, b) {
    Ok(M), Ok(S) | Ok(S), Ok(M) -> {
      let a = add_delta(key, #(-1, 1))
      let b = add_delta(key, #(1, -1))
      case dict.get(input, a), dict.get(input, b) {
        Ok(M), Ok(S) | Ok(S), Ok(M) -> True
        _, _ -> False
      }
    }
    _, _ -> False
  }
}

fn find_locs(input: Input, letter: Letter) -> List(Key) {
  use matching_keys <- list.filter(dict.keys(input))
  dict.get(input, matching_keys) == Ok(letter)
}

pub fn pt_1(input: Input) -> Int {
  let locs = find_locs(input, X)
  use acc, delta <- list.fold(directions, 0)
  acc + check_xmas(input, locs, delta)
}

pub fn pt_2(input: Input) -> Int {
  let locs = find_locs(input, A)
  use matching_keys <- list.count(locs)
  check_x_mas(input, matching_keys)
}
