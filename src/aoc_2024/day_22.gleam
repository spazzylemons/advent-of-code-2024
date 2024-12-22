import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/set
import gleam/string

type ChangeSeq =
  #(Int, Int, Int, Int)

pub fn parse(input: String) -> List(Int) {
  input
  |> string.split("\n")
  |> list.filter_map(int.parse)
}

fn next_secret(num: Int) -> Int {
  let num = int.bitwise_exclusive_or(num * 64, num) % 16_777_216
  let num = int.bitwise_exclusive_or(num / 32, num) % 16_777_216
  let num = int.bitwise_exclusive_or(num * 2048, num) % 16_777_216
  num
}

fn run_secret(num: Int, count: Int) -> Int {
  use <- bool.guard(count == 0, num)
  let num = next_secret(num)
  run_secret(num, count - 1)
}

fn find_prices(num: Int, count: Int, acc: List(Int)) -> List(Int) {
  case count == 0 {
    True -> list.reverse(acc)
    False -> {
      let num = next_secret(num)
      let acc = [num % 10, ..acc]
      find_prices(num, count - 1, acc)
    }
  }
}

fn secret_2000(num: Int) -> Int {
  run_secret(num, 2000)
}

fn get_prices(num: Int) -> Dict(ChangeSeq, Int) {
  find_prices(num, 2000, [num % 10]) |> find_first_seqs(dict.new())
}

fn find_first_seqs(
  l: List(Int),
  seqs: Dict(ChangeSeq, Int),
) -> Dict(ChangeSeq, Int) {
  case l {
    [a, b, c, d, e, ..] -> {
      let seq = #(b - a, c - b, d - c, e - d)
      let assert [_, ..l] = l
      let seqs = case dict.has_key(seqs, seq) {
        True -> seqs
        False -> dict.insert(seqs, seq, e)
      }
      find_first_seqs(l, seqs)
    }
    _ -> seqs
  }
}

fn get_all_change_seqs(l: List(Dict(ChangeSeq, Int))) -> List(ChangeSeq) {
  let l = {
    use l, seqs <- list.fold(l, set.new())
    use l, key, _ <- dict.fold(seqs, l)
    set.insert(l, key)
  }
  set.to_list(l)
}

pub fn pt_1(input: List(Int)) -> Int {
  list.map(input, secret_2000) |> list.fold(0, int.add)
}

pub fn pt_2(input: List(Int)) -> Int {
  let prices = list.map(input, get_prices)
  let seqs = get_all_change_seqs(prices)
  use max, seq <- list.fold(seqs, 0)
  let sum = {
    use sum, l <- list.fold(prices, 0)
    case dict.get(l, seq) {
      Ok(v) -> sum + v
      Error(Nil) -> sum
    }
  }
  int.max(max, sum)
}
