open Dsbs.Deps
open Dsbs.Logging
open Argparse

let () =
  let args = parse_arguments () in
  _log Log_Info "Building dependency graph" ;
  let graph =
    List.concat
      (List.map
         (fun fn -> dep_graph (Filename.basename fn) (Filename.dirname fn) 0)
         args.files )
  in
  _log Log_Info "Generating compiler commands" ;
  let cmds = gen_cmds graph args.files args.build_toplevel in
  List.iter (_log Log_Info) cmds ;
  _log Log_Info "Saving commands to file" ;
  let out = open_out args.out_fn in
  List.iter (fun cmd -> output_string out (cmd ^ "\n")) cmds ;
  close_out out
