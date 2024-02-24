(lang dune 3.9)

(name dsbs)

(generate_opam_files true)

(source
 (github CharlesAverill/dsbs))

(authors "Charles Averill")

(maintainers "Charles Averill")

(license LICENSE)

(documentation https://github.com/CharlesAverill/dsbs)

(package
 (name dsbs)
 (synopsis "Dead Simple Build System for Coq")
 (description "Dead Simple Build System for Coq")
 (depends ocaml dune))

