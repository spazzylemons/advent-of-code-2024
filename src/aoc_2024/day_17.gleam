import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Machine {
  Machine(a: Int, b: Int, c: Int, p: Dict(Int, Int), ip: Int)
}

fn parse_program(p: String) -> Dict(Int, Int) {
  let program = dict.new()
  use program, opcode, index <- list.index_fold(string.split(p, ","), program)
  let assert Ok(opcode) = int.parse(opcode)
  dict.insert(program, index, opcode)
}

pub fn parse(input: String) -> Machine {
  let assert [a, b, c, _, p] = string.split(input, "\n")
  let assert Ok(a) =
    string.split(a, " ") |> list.last() |> result.try(int.parse)
  let assert Ok(b) =
    string.split(b, " ") |> list.last() |> result.try(int.parse)
  let assert Ok(c) =
    string.split(c, " ") |> list.last() |> result.try(int.parse)
  let assert Ok(p) = string.split(p, " ") |> list.last()
  let p = parse_program(p)
  Machine(a, b, c, p, 0)
}

fn combo(m: Machine, i: Int) -> Int {
  case i {
    4 -> m.a
    5 -> m.b
    6 -> m.c
    _ -> i
  }
}

fn divide(m: Machine, value: Int, operand: Int) -> Int {
  int.bitwise_shift_right(value, combo(m, operand))
}

fn run(m: Machine, acc: List(Int)) -> List(Int) {
  case dict.get(m.p, m.ip), dict.get(m.p, m.ip + 1) {
    Ok(opcode), Ok(operand) -> {
      let acc = case opcode {
        5 -> [int.bitwise_and(combo(m, operand), 7), ..acc]
        _ -> acc
      }
      let m = case opcode {
        // adv
        0 -> Machine(..m, a: divide(m, m.a, operand), ip: m.ip + 2)
        // bxl
        1 ->
          Machine(..m, b: int.bitwise_exclusive_or(m.b, operand), ip: m.ip + 2)
        // bst
        2 ->
          Machine(..m, b: int.bitwise_and(combo(m, operand), 7), ip: m.ip + 2)
        // jnz
        3 ->
          Machine(
            ..m,
            ip: case m.a {
              0 -> m.ip + 2
              _ -> operand
            },
          )
        // bxc
        4 -> Machine(..m, b: int.bitwise_exclusive_or(m.b, m.c), ip: m.ip + 2)
        // out
        5 -> Machine(..m, ip: m.ip + 2)
        // bdv
        6 -> Machine(..m, b: divide(m, m.a, operand), ip: m.ip + 2)
        // bdv
        7 -> Machine(..m, c: divide(m, m.a, operand), ip: m.ip + 2)
        _ -> panic
      }
      run(m, acc)
    }
    _, _ -> list.reverse(acc)
  }
}

fn check_accum(m: Machine, compare: List(Int)) -> Int {
  case run(m, []) == compare {
    True -> m.a
    False -> check_accum(Machine(..m, a: m.a + 1), compare)
  }
}

fn find_quine(m: Machine, before: List(Int), after: List(Int)) -> Int {
  case after {
    [out, ..after] -> {
      let before = [out, ..before]
      let m = Machine(..m, a: int.bitwise_shift_left(m.a, 3))
      let m = Machine(..m, a: check_accum(m, before))
      find_quine(m, before, after)
    }
    [] -> m.a
  }
}

fn program_to_list(p: Dict(Int, Int)) -> List(Int) {
  use i <- list.map(list.range(0, dict.size(p) - 1))
  let assert Ok(v) = dict.get(p, i)
  v
}

pub fn pt_1(m: Machine) -> String {
  run(m, []) |> list.map(int.to_string) |> string.join(",")
}

pub fn pt_2(m: Machine) {
  let m = Machine(..m, a: 0)
  let program = program_to_list(m.p)
  find_quine(m, [], list.reverse(program))
}
