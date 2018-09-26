## Hugo Source for http://gorgonia.org

Hugo source for [gorgonia](http://gorgonia.org).

### Building

    git clone git@github.com:gorgonia/gorgonia.github.io.git
    cd gorgonia.github.io
    git submoudle init && git submodule update
    make

### Adding New Content

Launch the built-in hugo server for local development and live reloading:

    make serve

Content files exist in the `content/...` path, you can read about [content management](https://gohugo.io/content-management/) with hugo for more details.
