# About

Thie repository contains the sources and the website of gorgonia.org.

The website is hosted in the root dir and the sources in the `./src` subdirectory

## How to contribute:

```
git clone https://github.com/gorgonia/gorgonia.github.io.git
git submodule init
git submodule update
```

then test your developments from the `src` subdirectory with:

```
hugo -D serve
```

and generate the site with from the `src` subdirectory:

```
hugo
```

## vanity import (for the Gorgonia team)

Vanity import paths are handled by hugo.

#### Add a new repository

To add a new go-gettable repository, add a file in the `content/vanity-import-paths` subdir.

#### Add a subpackage

To add a new subpackage to an existing repository, add an entry in the `aliases` array within the md of the repository.
