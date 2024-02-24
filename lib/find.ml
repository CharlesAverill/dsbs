(* Finding import statements in Coq source code *)

open Import

let rec handle basedir dir in_channel =
  try
    let l = input_line in_channel in
    match import_option_of_string basedir dir l with
    | None ->
        handle basedir dir in_channel
    | Some i ->
        i :: handle basedir dir in_channel
  with End_of_file -> []

let imports_of_fn basedir fn =
  let dir = Filename.dirname fn in
  let in_channel = open_in fn in
  let imports = handle basedir dir in_channel in
  close_in in_channel ; imports
