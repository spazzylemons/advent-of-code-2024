import gleam/dict
import gleam/list
import gleam/string

pub type Schematic {
  Lock(heights: List(Int))
  Key(heights: List(Int))
}

type Input =
  List(Schematic)

fn line_heights(lines: List(String)) -> List(Int) {
  let assert [h, ..] = lines
  let length = string.length(h)
  let map = {
    use map, l, y <- list.index_fold(lines, dict.new())
    use map, g, x <- list.index_fold(string.to_graphemes(l), map)
    case g {
      "#" -> dict.insert(map, x, y)
      _ -> map
    }
  }
  use i <- list.map(list.range(0, length - 1))
  let assert Ok(height) = dict.get(map, i)
  height
}

pub fn parse(input: String) -> Input {
  let schematics = string.split(input, "\n\n")
  use schematic <- list.map(schematics)
  let schematic = string.split(schematic, "\n")
  case schematic {
    ["#####", ..] -> {
      Lock(line_heights(schematic))
    }
    [".....", ..] -> {
      Key(line_heights(list.reverse(schematic)))
    }
    _ -> panic
  }
}

fn check_overlap(pairs: List(#(Int, Int))) -> Bool {
  case pairs {
    [#(lock, key), ..pairs] -> {
      case lock <= 5 - key {
        True -> check_overlap(pairs)
        False -> False
      }
    }
    [] -> True
  }
}

pub fn pt_1(input: Input) -> Int {
  let locks =
    list.filter_map(input, fn(schem) {
      case schem {
        Lock(heights) -> Ok(heights)
        Key(_) -> Error(Nil)
      }
    })
  let keys =
    list.filter_map(input, fn(schem) {
      case schem {
        Key(heights) -> Ok(heights)
        Lock(_) -> Error(Nil)
      }
    })
  list.fold(locks, 0, fn(acc, lock) {
    acc + list.count(keys, fn(key) { check_overlap(list.zip(lock, key)) })
  })
}

pub fn pt_2(_input: Input) -> Nil {
  Nil
}
