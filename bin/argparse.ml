open Dsbs.Logging

type arguments = {files: string list; build_toplevel: bool; out_fn: string}

let parse_arguments () =
  let files = ref [] in
  let build_toplevel = ref false in
  let out_fn = ref "dsbs.sh" in
  let speclist =
    [ ( "-logging"
      , Arg.Int (fun n -> _GLOBAL_LOG_LEVEL := log_of_int n)
      , "Index of logging level to use \
         [0=None|1=Debug|2=Info|3=Warning|4=Error|5=Critical]" )
    ; ( "-build-toplevel"
      , Arg.Set build_toplevel
      , "Whether or not to generate commands to compile the passed top-level \
         files" )
    ; ( "-o"
      , Arg.Set_string out_fn
      , "Where to save the output script to (default is dsbs.sh)" ) ]
  in
  let usage_msg = "Usage: dsbs <top-level file(s)>" in
  Arg.parse speclist (fun f -> files := !files @ [f]) usage_msg ;
  {files= !files; build_toplevel= !build_toplevel; out_fn= !out_fn}
