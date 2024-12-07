import gleam/int
import gleam/list
import gleam/string

pub type Equation {
  Equation(goal: Int, values: List(Int))
}

pub type Input =
  List(Equation)

pub fn parse(input: String) -> Input {
  let lines = string.split(input, "\n")
  use line <- list.map(lines)

  let assert [goal, values] = string.split(line, ": ")
  let assert Ok(goal) = int.parse(goal)
  let values = string.split(values, " ") |> list.filter_map(int.parse)

  Equation(goal: goal, values: values)
}

fn digit_multiply(v: Int, acc: Int) -> Int {
  case v < 10 {
    True -> acc
    False -> digit_multiply(v / 10, acc * 10)
  }
}

fn concat(a: Int, b: Int) -> Int {
  let n = digit_multiply(b, 10)
  a * n + b
}

fn pt_1_loop(goal: Int, values: List(Int), acc: Int) -> Bool {
  case values {
    [value, ..rest] ->
      acc < goal
      && pt_1_loop(goal, rest, acc + value)
      || pt_1_loop(goal, rest, acc * value)
    [] -> acc == goal
  }
}

fn pt_1_check(equation: Equation) -> Bool {
  pt_1_loop(equation.goal, equation.values, 0)
}

fn pt_2_loop(goal: Int, values: List(Int), acc: Int) -> Bool {
  case values {
    [value, ..rest] ->
      acc < goal
      && pt_2_loop(goal, rest, acc + value)
      || pt_2_loop(goal, rest, acc * value)
      || pt_2_loop(goal, rest, concat(acc, value))
    [] -> acc == goal
  }
}

fn pt_2_check(equation: Equation) -> Bool {
  pt_2_loop(equation.goal, equation.values, 0)
}

fn add_equation(acc: Int, equation: Equation) -> Int {
  acc + equation.goal
}

pub fn pt_1(input: Input) -> Int {
  list.filter(input, pt_1_check) |> list.fold(0, add_equation)
}

pub fn pt_2(input: Input) -> Int {
  list.filter(input, pt_2_check) |> list.fold(0, add_equation)
}
