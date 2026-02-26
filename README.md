# MiyooCFW cores

List of generated cores (read by Makefile) can be found in `cores_list` file in topdir.

## Cross-Compile build (MiyooCFW):

- fetch & compile & build & generate index's list
```
make release
```
NOTES:
- to not rebuild the same cores add `SKIP_UNCHANGED=1` flag to make, which generated revisions files (if needed) for build checks
- don't use jobs parallel mode in make (it will be auto invoked in build process of cores)
- build logs can be found at `$TOPDIR/logs/`

## Native TEST build (linux):

- fetch & compile & build
```
make SKIP_UNCHANGED=1 CORES=<list cores> PLATFORM="" dist
```
NOTES:
- the `PLATFORM=` var. is unset on purpose for test results (which are gitignored from `$TOPDIR/cores/latest` content.

- release dir pkg (zip, move, index)
```
make release
```
