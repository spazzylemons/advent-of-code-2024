import gleam/bool
import gleam/dict.{type Dict}
import gleam/result

pub opaque type PQueue(v) {
  PQueue(values: Dict(Int, Node(v)), indices: Dict(v, Int))
}

type Node(v) {
  Node(value: v, prio: Int)
}

pub fn new() -> PQueue(v) {
  PQueue(dict.new(), dict.new())
}

fn cmp_paths(a: Node(v), b: Node(v)) -> Bool {
  a.prio <= b.prio
}

fn sift_up(pq: PQueue(v), child_pos: Int) -> PQueue(v) {
  let parent_pos = { child_pos - 1 } / 2
  let assert Ok(child) = dict.get(pq.values, child_pos)
  let assert Ok(parent) = dict.get(pq.values, parent_pos)
  use <- bool.guard(cmp_paths(parent, child), pq)
  let values =
    pq.values
    |> dict.insert(child_pos, parent)
    |> dict.insert(parent_pos, child)
  let indices =
    pq.indices
    |> dict.insert(parent.value, child_pos)
    |> dict.insert(child.value, parent_pos)
  sift_up(PQueue(values, indices), parent_pos)
}

fn do_insert(pq: PQueue(v), value: v, prio: Int) -> PQueue(v) {
  let pos = dict.size(pq.values)
  let values = dict.insert(pq.values, pos, Node(value, prio))
  let indices = dict.insert(pq.indices, value, pos)
  sift_up(PQueue(values, indices), pos)
}

pub fn insert(pq: PQueue(v), value: v, prio: Int) -> PQueue(v) {
  case dict.get(pq.indices, value) {
    Ok(old_index) -> {
      let assert Ok(old) = dict.get(pq.values, old_index)
      use <- bool.guard(prio > old.prio, pq)
      pq_remove_at(pq, old_index) |> do_insert(value, prio)
    }
    Error(Nil) -> do_insert(pq, value, prio)
  }
}

fn sift_down(pq: PQueue(v), pos: Int) -> PQueue(v) {
  let assert Ok(v) = dict.get(pq.values, pos)
  let l_pos = { pos * 2 } + 1
  let r_pos = l_pos + 1
  let l_small =
    dict.get(pq.values, l_pos)
    |> result.try(fn(l) {
      case cmp_paths(v, l) {
        True -> Error(Nil)
        False -> Ok(#(l_pos, l))
      }
    })
  let r_small =
    dict.get(pq.values, r_pos)
    |> result.try(fn(r) {
      case cmp_paths(v, r) {
        True -> Error(Nil)
        False -> Ok(#(r_pos, r))
      }
    })
  let smallest = case l_small, r_small {
    Error(Nil), Error(Nil) -> Error(Nil)
    Ok(s), Error(Nil) -> Ok(s)
    Error(Nil), Ok(s) -> Ok(s)
    Ok(#(_, l)), Ok(#(_, r)) ->
      case cmp_paths(l, r) {
        True -> Ok(#(l_pos, l))
        False -> Ok(#(r_pos, r))
      }
  }
  case smallest {
    Ok(#(child_pos, child)) -> {
      let values =
        pq.values
        |> dict.insert(child_pos, v)
        |> dict.insert(pos, child)
      let indices =
        pq.indices
        |> dict.insert(child.value, pos)
        |> dict.insert(v.value, child_pos)
      sift_down(PQueue(values, indices), child_pos)
    }
    Error(Nil) -> pq
  }
}

fn pq_remove_at(pq: PQueue(v), pos: Int) -> PQueue(v) {
  let last_pos = dict.size(pq.values) - 1
  let assert Ok(old_value) = dict.get(pq.values, pos)
  let assert Ok(new_value) = dict.get(pq.values, last_pos)
  let values =
    pq.values
    |> dict.insert(pos, new_value)
    |> dict.delete(last_pos)
  let indices =
    pq.indices
    |> dict.insert(new_value.value, pos)
    |> dict.delete(old_value.value)
  let pq = PQueue(values: values, indices: indices)
  case dict.has_key(pq.values, pos) {
    True -> sift_down(pq, pos)
    False -> pq
  }
}

pub fn remove(pq: PQueue(v)) -> Result(#(v, PQueue(v)), Nil) {
  use path <- result.try(dict.get(pq.values, 0))
  let pq = pq_remove_at(pq, 0)
  Ok(#(path.value, pq))
}
