+++
title= "Installation"
date= 2018-09-24T21:32:15+02:00
draft= false
weight = 150
alwaysopen = true
+++

The package is go-gettable: `go get -u gorgonia.org/gorgonia`. Additionally, Gorgonia uses [dep](https://github.com/golang/dep) as its vendoring tool.

The current version is 0.8.x


## Versioning 

We use [semver 2.0.0](http://semver.org/) for our versioning. Before 1.0, Gorgonia's APIs are expected to change quite a bit. API is defined by the exported functions, variables and methods. For the developers' sanity, there are minor differences to semver that we will apply prior to version 1.0. They are enumerated below:

* The MINOR number will be incremented every time there is a deletrious break in API. This means any deletion, or any change in function signature or interface methods will lead to a change in MINOR number. 
* Additive changes will NOT change the MINOR version number prior to version 1.0. This means that if new functionality were added that does not break the way you use Gorgonia, there will not be an increment in the MINOR version. There will be an increment in the PATCH version.  

## Go Version Support ##

Gorgonia aims to support 5 versions below the Master branch of Go. This means Gorgonia will support the current released version of Go, and up to 4 previous versions - providing something doesn't break. Where possible a shim will be provided (for things like new `sort` APIs or `math/bits` which came out in Go 1.9).

The current version of Go is 1.9.2. The earliest version Gorgonia supports is Go 1.6.x. 

## Dependencies ##

There are very few dependencies that Gorgonia uses - and they're all pretty stable, so as of now there isn't a need for vendoring tools. These are the list of external packages that Gorgonia calls, ranked in order of reliance that this package has (subpackages are omitted):

|Package|Used For|Vitality|Notes|Licence|
|-------|--------|--------|-----|-------|
|[gonum/graph](https://godoc.org/gonum.org/v1/gonum/graph)| Sorting `*ExprGraph`| Vital. Removal means Gorgonia will not work | Development of Gorgonia is committed to keeping up with the most updated version|[gonum license](https://github.com/gonum/license) (MIT/BSD-like)|
|[gonum/blas](https://godoc.org/gonum.org/v1/gonum/blas)|Tensor subpackage linear algebra operations|Vital. Removal means Gorgonial will not work|Development of Gorgonia is committed to keeping up with the most updated version|[gonum license](https://github.com/gonum/license) (MIT/BSD-like)|
|[cu](https://gorgonia.org/cu)| CUDA drivers | Needed for CUDA operations | Same maintainer as Gorgonia | MIT/BSD-like|
|[math32](https://github.com/chewxy/math32)|`float32` operations|Can be replaced by `float32(math.XXX(float64(x)))`|Same maintainer as Gorgonia, same API as the built in `math` package|MIT/BSD-like|
|[hm](https://github.com/chewxy/hm)|Type system for Gorgonia|Gorgonia's graphs are pretty tightly coupled with the type system | Same maintainer as Gorgonia | MIT/BSD-like|
|[vecf64](https://gorgonia.org/vecf64)| optimized `[]float64` operations | Can be generated in the `tensor/genlib` package. However, plenty of optimizations have been made/will be made | Same maintainer as Gorgonia | MIT/BSD-like|
|[vecf32](https://gorgonia.org/vecf32)| optimized `[]float32` operations | Can be generated in the `tensor/genlib` package. However, plenty of optimizations have been made/will be made | Same maintainer as Gorgonia | MIT/BSD-like|
|[set](https://github.com/xtgo/set)|Various set operations|Can be easily replaced|Stable API for the past 1 year|[set licence](https://github.com/xtgo/set/blob/master/LICENSE) (MIT/BSD-like)|
|[gographviz](https://github.com/awalterschulze/gographviz)|Used for printing graphs|Graph printing is only vital to debugging. Gorgonia can survive without, but with a major (but arguably nonvital) feature loss|Last update 12th April 2017|[gographviz licence](https://github.com/awalterschulze/gographviz/blob/master/LICENSE) (Apache 2.0)|
|[rng](https://github.com/leesper/go_rng)|Used to implement helper functions to generate initial weights|Can be replaced fairly easily. Gorgonia can do without the convenience functions too||[rng licence](https://github.com/leesper/go_rng/blob/master/LICENSE) (Apache 2.0)|
|[errors](https://github.com/pkg/errors)|Error wrapping|Gorgonia won't die without it. In fact Gorgonia has also used [goerrors/errors](https://github.com/go-errors/errors) in the past.|Stable API for the past 6 months|[errors licence](https://github.com/pkg/errors/blob/master/LICENSE) (MIT/BSD-like)|
|[gonum/mat](https://godoc.org/gonum.org/v1/gonum/mat)|Compatibility between `Tensor` and Gonum's Matrix|Development of Gorgonia is committed to keeping up with the most updated version||[gonum license](https://github.com/gonum/license) (MIT/BSD-like)|
|[testify/assert](https://github.com/stretchr/testify)|Testing|Can do without but will be a massive pain in the ass to test||[testify licence](https://github.com/stretchr/testify/blob/master/LICENSE) (MIT/BSD-like)|

# Keeping Updated #

Gorgonia's project has a [mailing list](https://groups.google.com/forum/#!forum/gorgonia), as well as a [Twitter account](https://twitter.com/gorgoniaML). Official updates and announcements will be posted to those two sites.



