import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/order
import gleam/set.{type Set}
import gleam/string
import rememo/memo

pub type Gate {
  And
  Or
  Xor
}

type ConnectionMap =
  Dict(String, Connection)

pub type Connection {
  Connection(a: String, b: String, gate: Gate)
}

pub type Input {
  Input(values: Dict(String, Int), connections: ConnectionMap)
}

pub fn parse(input: String) -> Input {
  let assert [values, connections] = string.split(input, "\n\n")
  let values = {
    use values, value <- list.fold(string.split(values, "\n"), dict.new())
    let assert [name, state] = string.split(value, ": ")
    let assert Ok(state) = int.parse(state)
    dict.insert(values, name, state)
  }
  let connections = {
    use connections, connection <- list.fold(
      string.split(connections, "\n"),
      dict.new(),
    )
    let assert [a, gate, b, "->", out] = string.split(connection, " ")
    let assert [a, b] = list.sort([a, b], string.compare)
    let gate = case gate {
      "AND" -> And
      "OR" -> Or
      "XOR" -> Xor
      _ -> panic
    }
    dict.insert(connections, out, Connection(a, b, gate))
  }
  Input(values, connections)
}

fn solve(input: Input, v: String, cache) -> Int {
  use <- memo.memoize(cache, v)
  case dict.get(input.values, v) {
    Ok(v) -> v
    Error(Nil) -> {
      let assert Ok(connection) = dict.get(input.connections, v)
      let a = solve(input, connection.a, cache)
      let b = solve(input, connection.b, cache)
      case connection.gate {
        And -> int.bitwise_and(a, b)
        Or -> int.bitwise_or(a, b)
        Xor -> int.bitwise_exclusive_or(a, b)
      }
    }
  }
}

fn find_z_values(d: ConnectionMap) -> List(String) {
  dict.keys(d) |> list.filter(fn(v) { string.starts_with(v, "z") })
}

pub fn pt_1(input: Input) -> Int {
  use cache <- memo.create()

  input.connections
  |> find_z_values()
  |> list.sort(string.compare)
  |> list.map(fn(v) { solve(input, v, cache) })
  |> list.index_fold(0, fn(acc, v, index) {
    acc + int.bitwise_shift_left(v, index)
  })
}

fn is_valid_xor_input(c: Connection) -> Bool {
  case c {
    Connection("x00", "y00", And) -> True
    Connection(_, _, And) -> False
    Connection(x, y, Xor) ->
      string.starts_with(x, "x") && string.starts_with(y, "y")
    _ -> True
  }
}

fn do_find_invalid_gates(d: ConnectionMap) -> Set(String) {
  use s, k, v <- dict.fold(d, set.new())
  let s = case v.gate {
    Or -> {
      let s = case dict.get(d, v.a) {
        Ok(Connection(_, _, And)) -> s
        _ -> set.insert(s, v.a)
      }
      let s = case dict.get(d, v.b) {
        Ok(Connection(_, _, And)) -> s
        _ -> set.insert(s, v.b)
      }
      s
    }
    Xor -> {
      let s = case dict.get(d, v.a) {
        Ok(c) ->
          case is_valid_xor_input(c) {
            True -> s
            False -> set.insert(s, v.a)
          }
        Error(Nil) -> s
      }
      let s = case dict.get(d, v.b) {
        Ok(c) ->
          case is_valid_xor_input(c) {
            True -> s
            False -> set.insert(s, v.b)
          }
        Error(Nil) -> s
      }
      s
    }
    And -> s
  }
  case string.starts_with(k, "z") && v.gate != Xor {
    True -> set.insert(s, k)
    False -> s
  }
}

fn find_invalid_gates(d: ConnectionMap) -> Set(String) {
  let s = do_find_invalid_gates(d)
  let assert [highest_z, ..] =
    d
    |> find_z_values()
    |> list.sort(order.reverse(string.compare))
  set.delete(s, highest_z)
}

pub fn pt_2(input: Input) -> String {
  find_invalid_gates(input.connections)
  |> set.to_list()
  |> list.sort(string.compare)
  |> string.join(",")
}
