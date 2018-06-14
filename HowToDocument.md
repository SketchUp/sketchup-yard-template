# SketchUp Ruby API Documentation

## Requirements

* System Ruby interpreter
  * Mac: Ships with OS. (Can use RVM: https://rvm.io/)
  * Windows: https://rubyinstaller.org/

Use [bundler](http://bundler.io/) to install required dependencies for the
tools.

```bash
bundle install
```

## TL;DR - Usage

Generate API Documentation:
`thor doc`

Exclude Versions:
`thor doc -e=SU2017 SU2018`

List Available Versions:
`thor doc:versions`

List Undocumented:
`thor doc:undocumented`

Generate API Stubs:
`thor stubs`

Generate API Stubs from Cache:
`thor stubs -c`

Generate coverage.manifest:
`thor coverage`

List All Commands: (There are more than listed here)
`thor list`

## Thor

http://whatisthor.com/

We use YARD to generate our Ruby API documentation, but also utilize it's API
for other automation tasks related to the API docs.

These tools are implemented as YARD templates and invoked from the command line.

YARD is highly flexible and therefore come with lots of options and switches.

In order to simplify the interaction with our tools we wrap them in Thor
commands.

### How to use Thor

`cd` into the `ruby/documentation` folder and then run `thor list`

This will list the available commands. To get more details on each command;
    `thor help [COMMAND]`

Whenever you run a Thor command it will print the YARD command it runs, so you
can tell exactly what it is doing.

Often Thor commands will use the YARD database to generate output. If you have
already parsed the source code and you can save time by telling it to use
the cache from last run. You do this by appending `--use-cache` or `-c`.

### Example

Lets say we add something new to the Ruby API;

1. Generate the documentation:
    `thor doc`

2. Update the test coverage list:
    `thor coverage:make -c`
    `thor coverage:install`

Notice that in step 2 we can rely on the cache from the previous command that
parsed the source code. Hence the `-c` flag.

## YARD

http://yardoc.org/

`cd` into the `ruby/documentation` folder and then run `yardoc` and wait for a
few seconds. (Assumes you have Ruby installed
on your computer. [Windows Installer](http://rubyinstaller.org/))

A `doc` directory is created which contains the output.

Also make sure you have updated the gems for your installed Ruby installation.
Run `gem update` - otherwise docs might not generate correctly if for instance
you have an out of date rdoc gem installed.

NOTE: You might run into this error when installing/updating Ruby gems;
    SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed

If you do, visit this guide on how to repair your Ruby installation:
http://guides.rubygems.org/ssl-certificate-update/

The `.yardopts` file contain the configuration for YARD to process our docs.

## TL;DR - YARD Usage

**Note:** The Thor commands mentioned above are wrappers on top of these YARD
commands.

Generate API Documentation:
`yardoc`

Exclude a version:

`yardoc --query '@version.text != "SketchUp 2018"'`

Generate API Stubs:
`yardoc -t stubs -f text`

Generate coverage.manifest:
`yardoc -t coverage -f text`

### Excluding API versions

If you are generating from trunk but want to omit unreleased methods added since
last public release you can use this syntax:

`yardoc --query '@version.text != "SketchUp 2017"'`

### Listing Undocumented Items

`yard stats --list-undoc > undocumented.txt`

### Generating Stubs

The "su-template" include a template alternative which generate stubs for the
API. Use the following command:

`yardoc -t stubs -f text`

### Generating Coverage Manifest

The "su-template" include a template alternative which generate coverage
manifest for the API. TestUp use this file to determine what we are missing test
coerage for. Use the following command:

`yardoc -t coverage -f text`

### Debugging YARD

`yardoc --debug > debug.txt`

### Gotchas

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

### References

YARD tags: http://www.rubydoc.info/gems/yard/file/docs/Tags.md
YARD types parser: http://yardoc.org/types.html

RDoc syntax: http://docs.seattlerb.org/rdoc/RDoc/Markup.html

