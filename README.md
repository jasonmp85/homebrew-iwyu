Homebrew IWYU
=============

[![Build Status](https://img.shields.io/travis/jasonmp85/homebrew-iwyu/master.svg)][status]
[![Release](https://img.shields.io/github/release/jasonmp85/homebrew-iwyu.svg)][release]
[![License](https://img.shields.io/:license-mit-blue.svg)][license]

This formula makes it easy to install `include-what-you-use` on any modern OS X system.

Just `brew tap jasonmp85/iwyu` and then `brew install iwyu`.

Using `iwyu`
------------

The [project's page][iwyu-page] goes into more detail, but there are three basic ways to use `iwyu`…

### Directly

Invoke it on a single file, as you would a compiler: `iwyu hello_world.c`. Messages about what includes to add or remove will be printed to standard output.

### From `make`

Tell make to use it as the C compiler: `make -k CC=iwyu`. It's necessary to use the `-k` flag to continue after errors (`iwyu` always errors to signal that no compilation has actually taken place).

### Using `fix_include`

`include-what-you-use` bundles a Python script capable of parsing its output in order to automatically fix any include problems, in-place if you desire. It's not perfect, but something like `fix_include hello_world.c < iwyu hello_world.c` should work to update a file named _hello_world.c_ with the suggestions made by `iwyu`.

Copyright
---------

Copyright (c) 2014 Jason Petersen

Code released under the [MIT License](LICENSE).

[status]: https://travis-ci.org/jasonmp85/homebrew-iwyu
[release]: https://github.com/jasonmp85/homebrew-iwyu/releases/latest
[license]: LICENSE
[iwyu-page]: http://include-what-you-use.org
