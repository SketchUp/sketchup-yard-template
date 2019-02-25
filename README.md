# SketchUp Ruby API YARD Template

This is the customized YARD template the SketchUp team uses to generate the [SketchUp Ruby API documentation](http://ruby.sketchup.com/).

It is made available for easy re-use. Using this gem a local copy of the documentation can be generated from our [SketchUp Ruby API stubs](https://github.com/SketchUp/ruby-api-stubs).

## Example Usage

Make sure YARD and yard-sketchup are installed:

```
gem install yard
gem install yard-sketchup
```

Example `.yardopts` config:

```
--title "SketchUp Ruby API Documentation"
--no-api
--no-private
--plugin yard-sketchup
SketchUp/**/*.rb
-
pages/*.md
```

The `assets` and `pages` directory can be found in the [SketchUp Ruby API stubs](https://github.com/SketchUp/ruby-api-stubs) repository.
