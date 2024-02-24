# DSBS

DSBS is a Dead-Simple Build System for Coq.

`coq_makefile` is hard to work with in my experience. DSBS does all the work for you.

DSBS scans your Coq files for dependencies and generates a build script that will
automatically compile and apply logical names to said dependencies.

## Usage

```bash
dune exec -- dsbs Main.v CoolFile.v # etc...
# Generates this file containing coqc calls
./dsbs.sh
# Compile your main files
COQPATH=$(pwd) coqc Main.v
```
