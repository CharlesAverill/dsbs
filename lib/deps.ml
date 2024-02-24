(* Building dependency graphs from imports *)

open Find
open Import
open Logging

(* https://coq.inria.fr/doc/V8.16.1/refman/proof-engine/vernacular-commands.html#compiled-files *)

let logpath_of_physpath p = Str.global_replace (Str.regexp {|/|}) "." p

let rec dep_graph (top_level_file : string) (dir : dirpath) (depth : int) :
    import list =
  let full_path = Filename.concat dir top_level_file in
  _log Log_Info ("Reading imports of " ^ full_path) ;
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
  let to_visit =
    List.map
      (fun i ->
        ((match !i.dirpath with None -> "" | Some d -> d), !i.qualid ^ ".v") )
      base_imports
  in
  let rec_imports =
    List.concat
      (List.map
         (fun ((d, q), i) ->
           let r = dep_graph q d (depth + 1) in
           List.iter
             (fun dep -> i := {!i with dependencies= dep :: !i.dependencies})
             r ;
           (* i :=
              { !i with
                dependencies=
                  { require= false
                  ; mode= NoMode
                  ; dirpath= Some d
                  ; qualid= q
                  ; dependencies= [] }
                  :: !i.dependencies } ; *)
           r )
         (List.combine to_visit base_imports) )
  in
  rec_imports @ List.map (fun x -> !x) base_imports

let remove_oldest_parent fn =
  let split = Str.split (Str.regexp_string Filename.dir_sep) fn in
  match split with [] -> fn | _ :: t -> String.concat Filename.dir_sep t

let remove_duplicates l =
  List.rev
    (List.fold_left (fun l' x -> if List.mem x l' then l' else x :: l') [] l)

let gen_cmds deps top_level_files =
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
  List.map gen_cmd
    ( deps
    @ List.map
        (fun fn ->
          { require= false
          ; mode= NoMode
          ; dirpath= None
          ; qualid= remove_oldest_parent fn
          ; dependencies= [] } )
        top_level_files )
