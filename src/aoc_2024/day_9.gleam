import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string

pub type Entry {
  File(size: Int, id: Int)
  Free(size: Int)
}

pub type Input =
  List(Entry)

type ParseState {
  ParseState(id: Int, file: Bool, input: Input)
}

type Node {
  Node(prev: Int, next: Int, index: Int, size: Int, id: Int)
}

type Pt2State =
  Dict(Int, Node)

pub fn parse(input: String) -> Input {
  let graphemes = string.to_graphemes(input)
  let state =
    list.fold(graphemes, ParseState(0, True, []), fn(state, g) {
      let assert Ok(size) = int.parse(g)
      case state.file {
        True -> {
          let entry = File(size, state.id)
          ParseState(id: state.id + 1, file: False, input: [
            entry,
            ..state.input
          ])
        }
        False -> {
          let entry = Free(size)
          ParseState(id: state.id, file: True, input: [entry, ..state.input])
        }
      }
    })
  list.reverse(state.input)
}

fn do_pt_1(
  state: Dict(Int, Int),
  start_ptr: Int,
  end_ptr: Int,
) -> Dict(Int, Int) {
  let size = dict.size(state)
  case end_ptr < size {
    True -> state
    False ->
      case dict.get(state, end_ptr) {
        Ok(num) ->
          case dict.get(state, start_ptr) {
            Error(Nil) -> {
              let state = dict.insert(state, start_ptr, num)
              let state = dict.delete(state, end_ptr)
              do_pt_1(state, start_ptr + 1, end_ptr - 1)
            }
            Ok(_) -> do_pt_1(state, start_ptr + 1, end_ptr)
          }
        Error(Nil) -> do_pt_1(state, start_ptr, end_ptr - 1)
      }
  }
}

fn remove_node(state: Pt2State, node: Node) -> Pt2State {
  let state = case dict.get(state, node.prev) {
    Ok(prev) -> dict.insert(state, node.prev, Node(..prev, next: node.next))
    Error(Nil) -> state
  }

  let state = case dict.get(state, node.next) {
    Ok(next) -> dict.insert(state, node.next, Node(..next, prev: node.prev))
    Error(Nil) -> state
  }

  dict.delete(state, node.id)
}

fn insert_node(
  state: Pt2State,
  after: Int,
  space: Int,
  size: Int,
  id: Int,
) -> Pt2State {
  let node = Node(prev: after, next: -1, index: space, size: size, id: id)

  case dict.get(state, after) {
    Ok(after) -> {
      let node =
        Node(
          ..node,
          next: after.next,
          index: after.index + after.size + node.index,
        )

      let before = dict.get(state, after.next)
      let after = Node(..after, next: id)

      let state = case before {
        Ok(before) -> dict.insert(state, before.id, Node(..before, prev: id))
        Error(Nil) -> state
      }

      let state = dict.insert(state, after.id, after)
      let state = dict.insert(state, node.id, node)
      state
    }

    Error(Nil) -> dict.insert(state, node.id, node)
  }
}

fn do_fill_free_space(state: Pt2State, node: Node, iter: Node) -> Pt2State {
  case iter.id == node.id {
    True -> state
    False -> {
      let assert Ok(next) = dict.get(state, iter.next)
      let free_space = next.index - { iter.index + iter.size }
      case free_space >= node.size {
        True -> {
          let state = remove_node(state, node)
          let state = insert_node(state, iter.id, 0, node.size, node.id)
          state
        }
        False -> do_fill_free_space(state, node, next)
      }
    }
  }
}

fn fill_free_space(state: Pt2State, node: Node) -> Pt2State {
  let assert Ok(iter) = dict.get(state, 0)
  do_fill_free_space(state, node, iter)
}

fn calculate_result_pt_2(state: Pt2State) -> Int {
  use acc, k, node <- dict.fold(state, 0)
  let _ = k

  let sum = { node.size * { node.size - 1 } } / 2
  { node.size * node.index + sum } * node.id + acc
}

fn do_pt_2(state: Pt2State, index: Int) -> Pt2State {
  let assert Ok(node) = dict.get(state, index)
  let state = fill_free_space(state, node)
  case index {
    0 -> state
    _ -> do_pt_2(state, index - 1)
  }
}

fn prepare_pt_1(
  input: Input,
  state: Dict(Int, Int),
  index: Int,
) -> #(Dict(Int, Int), Int) {
  case input {
    [Free(size), ..rest] -> prepare_pt_1(rest, state, index + size)
    [File(size, id), ..rest] ->
      case size {
        0 -> prepare_pt_1(rest, state, index)
        _ ->
          prepare_pt_1(
            [File(size - 1, id), ..rest],
            dict.insert(state, index, id),
            index + 1,
          )
      }
    [] -> #(state, index)
  }
}

fn prepare_pt_2(input: Input, state: Pt2State, space: Int) -> Pt2State {
  case input {
    [File(file_size, id), Free(free_size), ..rest] -> {
      let state = insert_node(state, id - 1, space, file_size, id)
      prepare_pt_2(rest, state, free_size)
    }
    [File(file_size, id)] -> {
      let state = insert_node(state, id - 1, space, file_size, id)
      state
    }
    [] -> state
    _ -> panic
  }
}

pub fn pt_1(input: Input) -> Int {
  let #(state, end_ptr) = prepare_pt_1(input, dict.new(), 0)
  let defrag = do_pt_1(state, 0, end_ptr)
  dict.fold(defrag, 0, fn(acc, k, v) { acc + { k * v } })
}

pub fn pt_2(input: Input) -> Int {
  let last_node_id = list.length(input) / 2
  let state = prepare_pt_2(input, dict.new(), 0)
  let state = do_pt_2(state, last_node_id)
  calculate_result_pt_2(state)
}
