# SketchUp Ruby API Documentation

## TL;DR - Usage

Generate API Documentation:
`yardoc`

Exclude a version:

`yardoc --query '@version.text != "SketchUp 2018"'`

Generate API Stubs:
`yardoc -t stubs -f text`

Generate coverage.manifest:
`yardoc -t coverage -f text`

## YARD

Currently the stable version of YARD is 0.8.7.6, but there are bugs in that
release which cause problems for us, so we must use the development version from
the `master` branch instead. Current commit at [5025564].

[Clone YARD](https://github.com/lsegal/yard/) to your computer and from its
folder run `rake install` from a console window.

`cd` into the `ruby/documentation` folder and then run `yardoc` and wait for a
few seconds. (Assumes you have Ruby installed
on your computer. [Windows Installer](http://rubyinstaller.org/))

A `doc` directory is created which contains the output.

Also make sure you have updated the gems for your installed Ruby installation.
Run `gem update` - otherwise docs might not generate correctly if for instance
you have an out of date rdoc gem installed.

The `.yardopts` file contain the configuration for YARD to process our docs.

## Excluding API versions

If you are generating from trunk but want to omit unreleased methods added since
last public release you can use this syntax:

`yardoc --query '@version.text != "SketchUp 2017"'`

## Listing Undocumented Items

`yard stats --list-undoc > undocumented.txt`

## Generating Stubs

The "su-template" include a template alternative which generate stubs for the
API. Use the following command:

`yardoc -t stubs -f text`

## Generating Coverage Manifest

The "su-template" include a template alternative which generate coverage
manifest for the API. TestUp use this file to determine what we are missing test
coerage for. Use the following command:

`yardoc -t coverage -f text`

## Debugging YARD

`yardoc --debug > debug.txt`

## Gotchas

`rb_define_module/class*` functions must be assigned to a return value.
Otherwise YARD seem to ignore it.

`rb_define_module/class_under` must use the same variable name for parent
namespace as the VALUE the parent was assigned to.

    // The name of the variable assigned to the return value is important:
    VALUE foo = rb_define_module("Foo");

    // If you don't use the same name, then YARD cannot resolve the namespace.
    VALUE bar = rb_define_module_under(foo, "Bar");

Likewise with the base class for `rb_define_class`, if it doesn't match any
known variable names (or built-in classes such as rb_cArray) it will fail to
resolve the base class.

## References

YARD tags: http://www.rubydoc.info/gems/yard/file/docs/Tags.md
YARD types parser: http://yardoc.org/types.html

RDoc syntax: http://docs.seattlerb.org/rdoc/RDoc/Markup.html

