open Dsbs.Logging

let parse_arguments () =
  let files = ref [] in
  let speclist =
    [ ( "-logging"
      , Arg.Int (fun n -> _GLOBAL_LOG_LEVEL := log_of_int n)
      , "Index of logging level to use \
         [0=None|1=Debug|2=Info|3=Warning|4=Error|5=Critical]" ) ]
  in
  let usage_msg = "Usage: dsbs <top-level file(s)>" in
  Arg.parse speclist (fun f -> files := !files @ [f]) usage_msg ;
  !files
