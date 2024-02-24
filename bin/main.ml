open Dsbs.Deps
open Dsbs.Logging
open Argparse

let () =
  let top_level_files = parse_arguments () in
  _log Log_Info "Building dependency graph" ;
  let graph =
    List.concat
      (List.map
         (fun fn -> dep_graph (Filename.basename fn) (Filename.dirname fn) 0)
         top_level_files )
  in
  _log Log_Info "Generating compiler commands" ;
  let cmds = gen_cmds graph top_level_files in
  List.iter print_endline cmds ;
  ()
