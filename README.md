# cocoapods-dependencies

[![Gem Version](https://badge.fury.io/rb/cocoapods-dependencies.svg)](http://badge.fury.io/rb/cocoapods-dependencies)
[![Code Climate](https://codeclimate.com/github/segiddins/cocoapods-dependencies.png)](https://codeclimate.com/github/segiddins/cocoapods-dependencies)

Shows a project's CocoaPod dependency graph.

## Installation

```bash
$ [sudo] gem install cocoapods-dependencies
```

## Usage

```bash
$ pod dependencies [PODSPEC] [--graphviz] [--image]
```

Use the `--graphviz` option to generate `<podspec name>.gv` or `Podfile.gv` containing the dependency graph in graphviz format.

Use the `--image` option to generate `<podspec name>.png` or `Podfile.png` containing a rendering of the dependency graph.

[!] Note that for either graphviz or image output, GraphViz must be installed and `dot` must be accessible via `$PATH`.
