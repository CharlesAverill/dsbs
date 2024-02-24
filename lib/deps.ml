(* Building dependency graphs from imports *)

open Find
open Import
open Logging

(* https://coq.inria.fr/doc/V8.16.1/refman/proof-engine/vernacular-commands.html#compiled-files *)

let logpath_of_physpath p = Str.global_replace (Str.regexp {|/|}) "." p

let rec dep_graph (top_level_file : string) (dir : dirpath) (depth : int) :
    import list =
  let full_path = Filename.concat dir top_level_file in
  (* If file doesn't exist, assume it's a Coq library, warn, and ignore *)
  if not (Sys.file_exists full_path) then (
    _log Log_Warning
      ( "Ignoring "
      ^ Filename.basename full_path
      ^ ", I can't find the file so I think it's a Coq library" ) ;
    [] )
  else (
    _log Log_Info ("Reading imports of " ^ top_level_file) ;
    let base_imports =
      List.map ref (imports_of_fn (Filename.basename top_level_file) full_path)
    in
    List.iter (fun i -> _log Log_Debug (string_of_import !i)) base_imports ;
    (* For each qualid, the command looks in the loadpath for a compiled file
          ident.vo
        in the file system whose logical name has the form
          dirpath.ident.*qualid
       (if From dirpath is given) or
          ident.*qualid
       (if the optional From clause is absent). *)
    (* Find all of the dependency files to visit *)
    let to_visit =
      List.map
        (fun i ->
          ((match !i.dirpath with None -> "" | Some d -> d), !i.qualid ^ ".v")
          )
        base_imports
    in
    (* Recursively visit dependency files to get all sub-dependencies *)
    let rec_imports =
      List.concat
        (List.map
           (fun ((d, q), i) ->
             let r = dep_graph q d (depth + 1) in
             if r = [] then i := {!i with is_standard_library= true} ;
             List.iter
               (fun dep -> i := {!i with dependencies= dep :: !i.dependencies})
               r ;
             r )
           (List.combine to_visit base_imports) )
    in
    (* Return recursive dependencies as well as those of the current file *)
    rec_imports @ List.map (fun x -> !x) base_imports )

let remove_oldest_parent fn =
  let split = Str.split (Str.regexp_string Filename.dir_sep) fn in
  match split with [] -> fn | _ :: t -> String.concat Filename.dir_sep t

let remove_duplicates l =
  List.rev
    (List.fold_left (fun l' x -> if List.mem x l' then l' else x :: l') [] l)

let gen_cmds deps top_level_files build_toplevel =
  let gen_cmd import =
    String.concat " "
      (List.filter
         (fun s -> s <> "")
         [ "COQPATH=$(pwd)"
         ; "coqc"
         ; String.concat " "
             (remove_duplicates
                (List.map
                   (fun d -> "-R " ^ d ^ " " ^ logpath_of_physpath d)
                   (List.concat
                      ( List.map
                          (fun i ->
                            match i.dirpath with
                            | Some d when remove_oldest_parent d <> "" ->
                                [remove_oldest_parent d]
                            | _ ->
                                [] )
                          import.dependencies
                      @
                      match import.dirpath with
                      | Some d when remove_oldest_parent d <> "" ->
                          [[remove_oldest_parent d]]
                      | _ ->
                          [] ) ) ) )
         ; Filename.concat
             ( match import.dirpath with
             | None ->
                 ""
             | Some d ->
                 remove_oldest_parent d )
             ( import.qualid
             ^ if String.ends_with ~suffix:".v" import.qualid then "" else ".v"
             ) ] )
  in
  List.filter (fun s -> s <> "") (
  List.map
    (fun i -> if i.is_standard_library then "" else gen_cmd i)
    ( deps
    @
    if build_toplevel then
      List.map
        (fun fn ->
          { require= false
          ; mode= NoMode
          ; dirpath= None
          ; qualid= remove_oldest_parent fn
          ; dependencies= []
          ; is_standard_library= false } )
        top_level_files
    else [] ))
