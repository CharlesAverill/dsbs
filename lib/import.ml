(* Semantic meaning for various imports *)

open Logging

(*
   https://coq.inria.fr/doc/V8.16.1/refman/proof-engine/vernacular-commands.html#compiled-files
   https://coq.inria.fr/doc/V8.16.1/refman/language/core/modules.html#coq:cmd.Import
*)

type qualid = string

type dirpath = string

type mode = NoMode | Import | Export

let string_of_mode : mode -> string = function
  | Import ->
      "Import"
  | Export ->
      "Export"
  | NoMode ->
      ""

let mode_of_string : string -> mode = function
  | "Import" ->
      Import
  | "Export" ->
      Export
  | _ ->
      NoMode

type import =
  { require: bool
  ; mode: mode
  ; dirpath: dirpath option
  ; qualid: qualid
  ; dependencies: import list
  ; is_standard_library: bool }

let string_of_import = function
  | {require; mode; dirpath; qualid; dependencies; is_standard_library} ->
      String.concat " "
        (List.filter
           (fun s -> s <> "")
           [ (match dirpath with None -> "" | Some d -> "From " ^ d)
           ; (if require then "Require" else "")
           ; string_of_mode mode
           ; qualid
           ; "."
           ; ( if dependencies <> [] then
                 "(* "
                 ^ String.concat " " (List.map (fun i -> i.qualid) dependencies)
                 ^ " - STL: "
                 ^ string_of_bool is_standard_library
                 ^ "*)"
               else "" ) ] )

let keywords = ["Require"; "From"; "Import"; "Export"]

let is_keyword s = List.exists (fun i -> i = s) keywords

let import_option_of_string (basedir : dirpath) (dir : dirpath) (s : string) :
    import option =
  (*
        I'm not too happy with this regex... mostly due to the fact that groups
        are numbered and not explicitly named. To keep the numbering consistent,
        instead of using '?' as the canonical "optional" regex operator, I'm
        hijacking binary-OR '\|' at the beginning of each group to match the
        target string or the empty string.
   *)
  let matched =
    Str.string_match
      (Str.regexp
         {|\(\|^From *\([a-zA-Z_][a-zA-Z0-9\|'\|_]*\) \)\(\|Require \)\(Import\|Export\|\) \([a-zA-Z_][a-zA-Z0-9\|'\|_]*\).$|} )
      s 0
  in
  _log Log_Debug ("Searching for matches: " ^ s) ;
  if not matched then (
    _log Log_Debug "No matches found" ;
    None )
  else
    let dirpath =
      (if basedir <> dir then Filename.concat dir else fun x -> x)
        ( if String.starts_with ~prefix:"From" s then Str.matched_group 2 s
          else "" )
    in
    _log Log_Debug ("Dirpath: " ^ dirpath) ;
    let require = Str.matched_group 3 s <> "" in
    _log Log_Debug ("Require: " ^ string_of_bool require) ;
    let mode = mode_of_string (Str.matched_group 4 s) in
    _log Log_Debug ("Mode: " ^ string_of_mode mode) ;
    let qualid = Str.matched_group 5 s in
    _log Log_Debug ("Qualid: " ^ qualid) ;
    match (is_keyword dirpath, is_keyword qualid) with
    | false, false ->
        Some
          { require
          ; mode
          ; dirpath= (if dirpath = "" then None else Some dirpath)
          ; qualid
          ; dependencies= []
          ; is_standard_library= false }
    | _ ->
        None
