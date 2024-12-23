import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string

type Graph =
  Dict(String, Set(String))

type Trio =
  #(String, String, String)

fn graph_new() -> Graph {
  dict.new()
}

fn insert_half(g: Graph, a: String, b: String) -> Graph {
  use v <- dict.upsert(g, a)
  case v {
    Some(v) -> set.insert(v, b)
    None -> set.from_list([b])
  }
}

fn graph_insert(g: Graph, a: String, b: String) -> Graph {
  g |> insert_half(a, b) |> insert_half(b, a)
}

fn graph_delete(g: Graph, a: String) -> Graph {
  let neighbors = graph_neighbors(g, a)
  let g = dict.delete(g, a)
  use g, b <- set.fold(neighbors, g)
  let assert Ok(s) = dict.get(g, b)
  let s = set.delete(s, a)
  dict.insert(g, b, s)
}

fn graph_contains(g: Graph, a: String, b: String) -> Bool {
  case dict.get(g, a) {
    Ok(v) -> set.contains(v, b)
    Error(Nil) -> False
  }
}

fn graph_nodes(g: Graph) -> List(String) {
  dict.keys(g)
}

fn graph_neighbors(g: Graph, a: String) -> Set(String) {
  use <- result.lazy_unwrap(dict.get(g, a))
  set.new()
}

pub fn parse(input: String) -> Graph {
  use g, line <- list.fold(string.split(input, "\n"), graph_new())
  let assert [a, b] = string.split(line, "-")
  graph_insert(g, a, b)
}

fn sort_trio(a: String, b: String, c: String) {
  let l = [a, b, c] |> list.sort(string.compare)
  let assert [a, b, c] = l
  #(a, b, c)
}

fn find_trios_of(input: Graph, a: String, s: Set(Trio)) -> Set(Trio) {
  let neighbors = graph_neighbors(input, a) |> set.to_list()
  let pairs = list.combinations(neighbors, 2)
  use s, p <- list.fold(pairs, s)
  let assert [b, c] = p
  use <- bool.guard(!graph_contains(input, a, b), s)
  use <- bool.guard(!graph_contains(input, b, c), s)
  use <- bool.guard(!graph_contains(input, c, a), s)
  set.insert(s, sort_trio(a, b, c))
}

fn find_trios(input: Graph) -> List(Trio) {
  let keys = graph_nodes(input)
  let s = {
    use s, a <- list.fold(keys, set.new())
    find_trios_of(input, a, s)
  }
  set.to_list(s)
}

fn filter_t(l: Trio) -> Bool {
  let #(a, b, c) = l
  string.starts_with(a, "t")
  || string.starts_with(b, "t")
  || string.starts_with(c, "t")
}

fn build_connected_to_all(g: Graph, acc: Set(String)) -> Set(String) {
  let new_node =
    acc
    |> set.map(fn(a) { graph_neighbors(g, a) })
    |> set.fold(set.new(), set.union)
    |> set.to_list()
    |> list.find(fn(a) {
      !set.contains(acc, a) && set.is_subset(acc, graph_neighbors(g, a))
    })
  case new_node {
    Ok(node) -> build_connected_to_all(g, set.insert(acc, node))
    Error(Nil) -> acc
  }
}

pub fn pt_1(g: Graph) -> Int {
  find_trios(g) |> list.filter(filter_t) |> list.length()
}

pub fn pt_2(g: Graph) -> String {
  let #(_, l) = {
    use g, a <- list.map_fold(graph_nodes(g), g)
    let l = build_connected_to_all(g, set.from_list([a]))
    let g = set.fold(l, g, graph_delete)
    #(g, l)
  }
  let assert Ok(l) =
    l |> list.max(fn(a, b) { int.compare(set.size(a), set.size(b)) })
  l |> set.to_list() |> list.sort(string.compare) |> string.join(",")
}
