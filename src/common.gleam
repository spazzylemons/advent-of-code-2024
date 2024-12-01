import simplifile

pub fn read_sample() -> String {
  let assert Ok(content) = simplifile.read("sample.txt")
  content
}

pub fn read_input() -> String {
  let assert Ok(content) = simplifile.read("input.txt")
  content
}
