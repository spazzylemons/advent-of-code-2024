import gleam/string
import simplifile

pub fn read_sample() -> String {
  let assert Ok(content) = simplifile.read("sample.txt")
  content
}

pub fn read_sample_lines() -> List(String) {
  read_sample() |> string.trim() |> string.split("\n")
}

pub fn read_input() -> String {
  let assert Ok(content) = simplifile.read("input.txt")
  content
}

pub fn read_input_lines() -> List(String) {
  read_input() |> string.trim() |> string.split("\n")
}
