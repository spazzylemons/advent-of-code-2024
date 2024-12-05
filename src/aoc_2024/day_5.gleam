import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub type Rule {
  Rule(before: Int, after: Int)
}

pub type Ruleset =
  Set(Rule)

pub type Input {
  Input(rules: Ruleset, updates: List(List(Int)))
}

fn parse_updates(lines: List(String), input: Input) -> Input {
  case lines {
    [x, ..xs] -> {
      let update =
        string.split(x, ",")
        |> list.filter_map(int.parse)
      let input = Input(..input, updates: [update, ..input.updates])
      parse_updates(xs, input)
    }
    [] -> input
  }
}

fn parse_rules(lines: List(String), input: Input) -> Input {
  let assert [x, ..xs] = lines
  case x {
    "" -> parse_updates(xs, input)
    _ -> {
      let assert [before, after] = string.split(x, "|")
      let assert Ok(before) = int.parse(before)
      let assert Ok(after) = int.parse(after)
      let rule = Rule(before, after)
      let input = Input(..input, rules: set.insert(input.rules, rule))
      parse_rules(xs, input)
    }
  }
}

pub fn parse(input: String) -> Input {
  parse_rules(string.split(input, "\n"), Input(rules: set.new(), updates: []))
}

fn is_update_ordered(rules: Ruleset, update: List(Int)) -> Bool {
  case update {
    [page, ..rest] -> {
      case
        list.all(rest, fn(other_page) {
          !set.contains(rules, Rule(other_page, page))
        })
      {
        True -> is_update_ordered(rules, rest)
        False -> False
      }
    }
    [] -> True
  }
}

fn reorder_update(
  rules: Ruleset,
  update: List(Int),
  accum: List(Int),
  reordered: Bool,
) -> Result(List(Int), Nil) {
  case update {
    [page, ..rest] -> {
      case
        list.pop(rest, fn(other_page) {
          set.contains(rules, Rule(other_page, page))
        })
      {
        Ok(#(removed_page, new_list)) ->
          reorder_update(rules, [removed_page, page, ..new_list], accum, True)
        Error(Nil) -> reorder_update(rules, rest, [page, ..accum], reordered)
      }
    }
    [] ->
      case reordered {
        True -> Ok(accum)
        False -> Error(Nil)
      }
  }
}

fn select_middle_element_loop(index: Int, match: Int, update: List(Int)) -> Int {
  let assert [page, ..rest] = update
  case index == match {
    True -> page
    False -> select_middle_element_loop(index + 1, match, rest)
  }
}

fn select_middle_element(update: List(Int)) -> Int {
  let l = list.length(update) / 2
  select_middle_element_loop(0, l, update)
}

pub fn pt_1(input: Input) -> Int {
  let updates =
    list.filter_map(input.updates, fn(update) {
      case is_update_ordered(input.rules, update) {
        True -> Ok(select_middle_element(update))
        False -> Error(Nil)
      }
    })

  list.fold(updates, 0, int.add)
}

pub fn pt_2(input: Input) -> Int {
  let updates =
    list.filter_map(input.updates, fn(update) {
      use update <- result.try(reorder_update(input.rules, update, [], False))
      Ok(select_middle_element(update))
    })

  list.fold(updates, 0, int.add)
}
