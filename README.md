opm-meta
========

This repository holds a meta buildsystem for OPM. The buildsystem will clone and build all components of OPM
in an automated fashion.

You can specify revision, repository url, patches and build build flags on a per-component basis if you so desire
through

cmake -D<component>_[REPO|VERSION|PATCHES|CXXFLAGS]

You can build a specific release version of OPM through

cmake -DRELEASE_VERSION=<version>

and use a specific DUNE version through

cmake -DDUNE_VERSION=<version>

If no parameters are given, it will build the head of git master for all modules.

While everything relies on use of the 'make install' mechanism, everything is contained in the build tree;
nothing is installed on your system.

The filesystem layout in the build tree is dictated by cmake and is structured like

installed/* - this holds the installed files.
<module>/src/<module> - the source tree for <module>
<module>/src/<module>-build - the build tree for <module>
