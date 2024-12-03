import gleam/int
import gleam/list
import gleam/option
import gleam/regexp

pub type Instruction {
  Do
  Dont
  Mul(a: Int, b: Int)
}

pub type Pt2State {
  Pt2State(doing: Bool, sum: Int)
}

type Input = List(Instruction)

pub fn parse(input: String) -> Input {
  let assert Ok(r) = regexp.compile("do\\(\\)|don't\\(\\)|mul\\((\\d{1,3}),(\\d{1,3})\\)", regexp.Options(False, False))
  let matches = regexp.scan(r, input)
  list.map(matches, fn(match) {
    case match.content {
      "do()" -> Do
      "don't()" -> Dont
      _ -> {
        let assert [option.Some(a), option.Some(b)] = match.submatches
        let assert Ok(a) = int.parse(a)
        let assert Ok(b) = int.parse(b)
        Mul(a, b)
      }
    }
  })
}

pub fn pt_1(input: Input) -> Int {
  list.fold(input, 0, fn(acc, ins) {
    case ins {
      Mul(a, b) -> acc + { a * b }
      _ -> acc
    }
  })
}

pub fn pt_2(input: Input) -> Int {
  list.fold(input, Pt2State(True, 0), fn(acc, ins) {
    case ins {
      Do -> Pt2State(..acc, doing: True)
      Dont -> Pt2State(..acc, doing: False)
      Mul(a, b) -> Pt2State(..acc,
        sum: acc.sum + case acc.doing {
          True -> a * b
          False -> 0
        }
      )
    }
  }).sum
}
