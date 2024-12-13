import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp

pub type Point {
  Point(x: Int, y: Int)
}

pub type ClawMachine {
  ClawMachine(a: Point, b: Point, prize: Point)
}

pub type Input = List(ClawMachine)

pub fn parse(input: String) -> Input {
  let assert Ok(r) = regexp.compile("Button A: X\\+(\\d+), Y\\+(\\d+)\nButton B: X\\+(\\d+), Y\\+(\\d+)\nPrize: X=(\\d+), Y=(\\d+)", regexp.Options(False, False))
  let matches = regexp.scan(r, input)
  use match <- list.map(matches)
  let assert [ax, ay, bx, by, px, py] = match.submatches |> list.map(fn(match) {
    let assert Some(value) = match
    let assert Ok(value) = int.parse(value)
    value
  })
  ClawMachine(
    a: Point(ax, ay),
    b: Point(bx, by),
    prize: Point(px, py),
  )
}

fn optimize(m: ClawMachine) -> Int {
  case m.b.x == m.b.y {
    True -> {
      let num = { m.prize.y * m.a.x } - { m.prize.x * m.a.y }
      let den = { m.b.y * m.a.x } - { m.b.x * m.a.y }
      case num % den {
        0 -> {
          let b = num / den
          let a = m.prize.x - { b * m.b.x }
          let a = a / m.a.x
          { 3 * a } + b
        }
        _ -> 0
      }
    }

    False -> {
      let num = { m.prize.y * m.b.x } - { m.prize.x * m.b.y }
      let den = { m.a.y * m.b.x } - { m.a.x * m.b.y }
      case num % den {
        0 -> {
          let a = num / den
          let b = m.prize.x - { a * m.a.x }
          let b = b / m.b.x
          { 3 * a } + b
        }
        _ -> 0
      }
    }
  }
}

fn adjust(m: ClawMachine) -> ClawMachine {
  ClawMachine(
    ..m,
    prize: Point(x: m.prize.x + 10000000000000, y: m.prize.y + 10000000000000),
  )
}

pub fn pt_1(input: Input) -> Int {
  list.map(input, optimize) |> list.fold(0, int.add)
}

pub fn pt_2(input: Input) -> Int {
  list.map(input, adjust)
  |> list.map(optimize)
  |> list.fold(0, int.add)
}
