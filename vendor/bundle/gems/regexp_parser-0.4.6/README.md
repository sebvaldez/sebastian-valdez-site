# Regexp::Parser

[![Gem Version](https://badge.fury.io/rb/regexp_parser.svg)](http://badge.fury.io/rb/regexp_parser) [![Build Status](https://secure.travis-ci.org/ammar/regexp_parser.svg?branch=master)](http://travis-ci.org/ammar/regexp_parser) [![Code Climate](https://codeclimate.com/github/ammar/regexp_parser.svg)](https://codeclimate.com/github/ammar/regexp_parser/badges)

A ruby gem for tokenizing, parsing, and transforming regular expressions.

* Multilayered
  * A scanner/tokenizer based on [ragel](http://www.colm.net/open-source/ragel/)
  * A lexer that produces a "stream" of token objects.
  * A parser that produces a "tree" of Expression objects (OO API)
* Runs on ruby 1.9, 2.x, and jruby (1.9 mode) runtimes.
* Recognizes ruby 1.8, 1.9, and 2.x regular expressions [See Supported Syntax](#supported-syntax)


_For an example of regexp_parser in use, see the [meta_re project](https://github.com/ammar/meta_re)_


---
## Requirements

* Ruby >= 1.9
* Ragel >= 6.0, but only if you want to build the gem or work on the scanner.


_Note: See the .travis.yml file for covered versions._


---
## Install

Install the gem with:

  `gem install regexp_parser`

Or, add it to your project's `Gemfile`:

```gem 'regexp_parser', '~> X.Y.Z'```

See rubygems for the the [latest version number](https://rubygems.org/gems/regexp_parser)


---
## Usage

The three main modules are **Scanner**, **Lexer**, and **Parser**. Each of them
provides a single method that takes a regular expression (as a RegExp object or
a string) and returns its results. The **Lexer** and the **Parser** accept an
optional second argument that specifies the syntax version, like 'ruby/2.0',
which defaults to the host ruby version (using RUBY_VERSION).

Here are the basic usage examples:

```ruby
require 'regexp_parser'

Regexp::Scanner.scan(regexp)

Regexp::Lexer.lex(regexp)

Regexp::Parser.parse(regexp)
```

All three methods accept a block as the last argument, which, if given, gets
called with the results as follows:

* **Scanner**: the block gets passed the results as they are scanned. See the
  example in the next section for details.

* **Lexer**: after completion, the block gets passed the tokens one by one.
  _The result of the block is returned._

* **Parser**: after completion, the block gets passed the root expression.
  _The result of the block is returned._


---
## Components

### Scanner
A ragel generated scanner that recognizes the cumulative syntax of all
supported syntax versions. It breaks a given expression's text into the
smallest parts, and identifies their type, token, text, and start/end
offsets within the pattern.


#### Example
The following scans the given pattern and prints out the type, token, text and
start/end offsets for each token found.

```ruby
require 'regexp_parser'

Regexp::Scanner.scan /(ab?(cd)*[e-h]+)/  do |type, token, text, ts, te|
  puts "type: #{type}, token: #{token}, text: '#{text}' [#{ts}..#{te}]"
end

# output
# type: group, token: capture, text: '(' [0..1]
# type: literal, token: literal, text: 'ab' [1..3]
# type: quantifier, token: zero_or_one, text: '?' [3..4]
# type: group, token: capture, text: '(' [4..5]
# type: literal, token: literal, text: 'cd' [5..7]
# type: group, token: close, text: ')' [7..8]
# type: quantifier, token: zero_or_more, text: '*' [8..9]
# type: set, token: open, text: '[' [9..10]
# type: set, token: range, text: 'e-h' [10..13]
# type: set, token: close, text: ']' [13..14]
# type: quantifier, token: one_or_more, text: '+' [14..15]
# type: group, token: close, text: ')' [15..16]
```

A one-liner that uses map on the result of the scan to return the textual
parts of the pattern:

```ruby
Regexp::Scanner.scan( /(cat?([bhm]at)){3,5}/ ).map {|token| token[2]}
#=> ["(", "cat", "?", "(", "[", "b", "h", "m", "]", "at", ")", ")", "{3,5}"]
```


#### Notes
  * The scanner performs basic syntax error checking, like detecting missing
    balancing punctuation and premature end of pattern. Flavor validity checks
    are performed in the lexer, which uses a syntax object.

  * If the input is a ruby **Regexp** object, the scanner calls #source on it to
    get its string representation. #source does not include the options of
    the expression (m, i, and x) To include the options in the scan, #to_s
    should be called on the **Regexp** before passing it to the scanner or any
    of the other modules.

  * To keep the scanner simple(r) and fairly reusable for other purposes, it
    does not perform lexical analysis on the tokens, sticking to the task
    of identifying the smallest possible tokens and leaving lexical analysis
    to the lexer.

  * The MRI implementation may accept expressions that either conflict with
    the documentation or are undocumented. The scanner does not support such
    implementation quirks.
    _(See issues [#3](https://github.com/ammar/regexp_parser/issues/3) and
    [#15](https://github.com/ammar/regexp_parser/issues/15) for examples)_


---
### Syntax
Defines the supported tokens for a specific engine implementation (aka a
flavor). Syntax classes act as lookup tables, and are layered to create
flavor variations. Syntax only comes into play in the lexer.

#### Example
The following instantiates syntax objects for Ruby 2.0, 1.9, 1.8, and
checks a few of their implementation features.

```ruby
require 'regexp_parser'

ruby_20 = Regexp::Syntax.new 'ruby/2.0'
ruby_20.implements? :quantifier,  :zero_or_one             # => true
ruby_20.implements? :quantifier,  :zero_or_one_reluctant   # => true
ruby_20.implements? :quantifier,  :zero_or_one_possessive  # => true
ruby_20.implements? :conditional, :condition               # => true

ruby_19 = Regexp::Syntax.new 'ruby/1.9'
ruby_19.implements? :quantifier,  :zero_or_one             # => true
ruby_19.implements? :quantifier,  :zero_or_one_reluctant   # => true
ruby_19.implements? :quantifier,  :zero_or_one_possessive  # => true
ruby_19.implements? :conditional, :condition               # => false

ruby_18 = Regexp::Syntax.new 'ruby/1.8'
ruby_18.implements? :quantifier,  :zero_or_one             # => true
ruby_18.implements? :quantifier,  :zero_or_one_reluctant   # => true
ruby_18.implements? :quantifier,  :zero_or_one_possessive  # => false
ruby_18.implements? :conditional, :condition               # => false
```


#### Notes
  * Variations on a token, for example a named group with angle brackets (< and >)
    vs one with a pair of single quotes, are specified with an underscore followed
    by two characters appended to the base token. In the previous named group example,
    the tokens would be :named_ab (angle brackets) and :named_sq (single quotes).
    These variations are normalized by the syntax to :named.


---
### Lexer
Sits on top of the scanner and performs lexical analysis on the tokens that
it emits. Among its tasks are; breaking quantified literal runs, collecting the
emitted token attributes into Token objects, calculating their nesting depth,
normalizing tokens for the parser, and checkng if the tokens are implemented by
the given syntax version.

See the [Token Objects](https://github.com/ammar/regexp_parser/wiki/Token-Objects)
wiki page for more information on Token objects.


#### Example
The following example lexes the given pattern, checks it against the ruby 1.9
syntax, and prints the token objects' text indented to their level.

```ruby
require 'regexp_parser'

Regexp::Lexer.lex /a?(b(c))*[d]+/, 'ruby/1.9' do |token|
  puts "#{'  ' * token.level}#{token.text}"
end

# output
# a
# ?
# (
#   b
#   (
#     c
#   )
# )
# *
# [
# d
# ]
# +
```

A one-liner that returns an array of the textual parts of the given pattern.
Compare the output with that of the one-liner example of the **Scanner**; notably
how the sequence 'cat' is treated. The 't' is seperated because it's followed
by a quantifier that only applies to it.

```ruby
Regexp::Lexer.scan( /(cat?([b]at)){3,5}/ ).map {|token| token.text}
#=> ["(", "ca", "t", "?", "(", "[", "b", "]", "at", ")", ")", "{3,5}"]
```

#### Notes
  * The syntax argument is optional. It defaults to the version of the ruby
    interpreter in use, as returned by RUBY_VERSION.

  * The lexer normalizes some tokens, as noted in the Syntax section above.


---
### Parser
Sits on top of the lexer and transforms the "stream" of Token objects emitted
by it into a tree of Expression objects represented by an instance of the
Expression::Root class.

See the [Expression Objects](https://github.com/ammar/regexp_parser/wiki/Expression-Objects)
wiki page for attributes and methods.


#### Example

```ruby
require 'regexp_parser'

regex = /a?(b+(c)d)*(?<name>[0-9]+)/

tree = Regexp::Parser.parse( regex, 'ruby/2.1' )

tree.traverse do |event, exp|
  puts "#{event}: #{exp.type} `#{exp.to_s}`"
end

# Output
# visit: literal `a?`
# enter: group `(b+(c)d)*`
# visit: literal `b+`
# enter: group `(c)`
# visit: literal `c`
# exit: group `(c)`
# visit: literal `d`
# exit: group `(b+(c)d)*`
# enter: group `(?<name>[0-9]+)`
# visit: set `[0-9]+`
# exit: group `(?<name>[0-9]+)`
```

Another example, using each_expression and strfregexp to print the object tree.
_See the traverse.rb and strfregexp.rb files under `lib/regexp_parser/expression/methods`
for more information on these methods._

```ruby
include_root  = true
indent_offset = include_root ? 1 : 0

tree.each_expression(include_root) do |exp, level_index|
  puts exp.strfregexp("%>> %c", indent_offset)
end

# Output
# > Regexp::Expression::Root
#   > Regexp::Expression::Literal
#   > Regexp::Expression::Group::Capture
#     > Regexp::Expression::Literal
#     > Regexp::Expression::Group::Capture
#       > Regexp::Expression::Literal
#     > Regexp::Expression::Literal
#   > Regexp::Expression::Group::Named
#     > Regexp::Expression::CharacterSet
```

_Note: quantifiers do not appear in the output because they are members of the
Expression class. See the next section for details._


---


## Supported Syntax
The three modules support all the regular expression syntax features of Ruby 1.8
, 1.9, and 2.x:

_Note that not all of these are available in all versions of Ruby_


| Syntax Feature                        | Examples                                                | &#x22ef; |
| ------------------------------------- | ------------------------------------------------------- |:--------:|
| **Alternation**                       | `a\|b\|c`                                               | &#x2713; |
| **Anchors**                           | `^`, `$`, `\b`                                          | &#x2713; |
| **Character Classes**                 | `[abc]`, `[^\\]`, `[a-d&&g-h]`, `[a=e=b]`               | &#x2713; |
| **Character Types**                   | `\d`, `\H`, `\s`                                        | &#x2713; |
| **Cluster Types**                     | `\R`, `\X`                                              | &#x2713; |
| **Conditional Exps.**                 | `(?(cond)yes-subexp)`, `(?(cond)yes-subexp\|no-subexp)` | &#x2713; |
| **Escape Sequences**                  | `\t`, `\\+`, `\?`                                       | &#x2713; |
| **Free Space**                        | whitespace and `# Comments` _(x modifier)_              | &#x2713; |
| **Grouped Exps.**                     |                                                         | &#x22f1; |
| &emsp;&nbsp;_**Assertions**_          |                                                         | &#x22f1; |
| &emsp;&emsp;_Lookahead_               | `(?=abc)`                                               | &#x2713; |
| &emsp;&emsp;_Negative Lookahead_      | `(?!abc)`                                               | &#x2713; |
| &emsp;&emsp;_Lookbehind_              | `(?<=abc)`                                              | &#x2713; |
| &emsp;&emsp;_Negative Lookbehind_     | `(?<!abc)`                                              | &#x2713; |
| &emsp;&nbsp;_**Atomic**_              | `(?>abc)`                                               | &#x2713; |
| &emsp;&nbsp;_**Absence**_             | `(?~abc)`                                               | &#x2713; |
| &emsp;&nbsp;_**Back-references**_     |                                                         | &#x22f1; |
| &emsp;&emsp;_Named_                   | `\k<name>`                                              | &#x2713; |
| &emsp;&emsp;_Nest Level_              | `\k<n-1>`                                               | &#x2713; |
| &emsp;&emsp;_Numbered_                | `\k<1>`                                                 | &#x2713; |
| &emsp;&emsp;_Relative_                | `\k<-2>`                                                | &#x2713; |
| &emsp;&emsp;_Traditional_             | `\1` thru `\9`                                          | &#x2713; |
| &emsp;&nbsp;_**Capturing**_           | `(abc)`                                                 | &#x2713; |
| &emsp;&nbsp;_**Comments**_            | `(?# comment text)`                                     | &#x2713; |
| &emsp;&nbsp;_**Named**_               | `(?<name>abc)`, `(?'name'abc)`                          | &#x2713; |
| &emsp;&nbsp;_**Options**_             | `(?mi-x:abc)`, `(?a:\s\w+)`                             | &#x2713; |
| &emsp;&nbsp;_**Passive**_             | `(?:abc)`                                               | &#x2713; |
| &emsp;&nbsp;_**Subexp. Calls**_       | `\g<name>`, `\g<1>`                                     | &#x2713; |
| **Keep**                              | `\K`, `(ab\Kc\|d\Ke)f`                                  | &#x2713; |
| **Literals** _(utf-8)_                | `Ruby`, `ルビー`, `روبي`                                | &#x2713; |
| **POSIX Classes**                     | `[:alpha:]`, `[:^digit:]`                               | &#x2713; |
| **Quantifiers**                       |                                                         | &#x22f1; |
| &emsp;&nbsp;_**Greedy**_              | `?`, `*`, `+`, `{m,M}`                                  | &#x2713; |
| &emsp;&nbsp;_**Reluctant** (Lazy)_    | `??`, `*?`, `+?`, `{m,M}?`                              | &#x2713; |
| &emsp;&nbsp;_**Possessive**_          | `?+`, `*+`, `++`, `{m,M}+`                              | &#x2713; |
| **String Escapes**                    |                                                         | &#x22f1; |
| &emsp;&nbsp;_**Control**_             | `\C-C`, `\cD`                                           | &#x2713; |
| &emsp;&nbsp;_**Hex**_                 | `\x20`, `\x{701230}`                                    | &#x2713; |
| &emsp;&nbsp;_**Meta**_                | `\M-c`, `\M-\C-C`, `\M-\cC`, `\C-\M-C`, `\c\M-C`        | &#x2713; |
| &emsp;&nbsp;_**Octal**_               | `\0`, `\01`, `\012`                                     | &#x2713; |
| &emsp;&nbsp;_**Unicode**_             | `\uHHHH`, `\u{H+ H+}`                                   | &#x2713; |
| **Unicode Properties**                | _<sub>([Unicode 7.0.0](http://www.unicode.org/versions/Unicode7.0.0/))</sub>_ | &#x22f1; |
| &emsp;&nbsp;_**Age**_                 | `\p{Age=5.2}`, `\P{age=7.0}`                            | &#x2713; |
| &emsp;&nbsp;_**Blocks**_              | `\p{InArmenian}`, `\P{InKhmer}`                         | &#x2713; |
| &emsp;&nbsp;_**Classes**_             | `\p{Alpha}`, `\P{Space}`                                | &#x2713; |
| &emsp;&nbsp;_**Derived**_             | `\p{Math}`, `\P{Lowercase}`                             | &#x2713; |
| &emsp;&nbsp;_**General Categories**_  | `\p{Lu}`, `\P{Cs}`                                      | &#x2713; |
| &emsp;&nbsp;_**Scripts**_             | `\p{Arabic}`, `\P{Hiragana}`                            | &#x2713; |
| &emsp;&nbsp;_**Simple**_              | `\p{Dash}`, `\p{Extender}`                              | &#x2713; |

##### Inapplicable Features

Some modifiers, like `o` and `s`, apply to the **Regexp** object itself and do not
appear in its source. Others such modifiers include the encoding modifiers `e` and `n`
[See](http://www.ruby-doc.org/core-2.1.3/Regexp.html#class-Regexp-label-Encoding).
These are not seen by the scanner.

The following features are not currently enabled for Ruby by its regular
expressions library (Onigmo). They are not supported by the scanner.

  - **Quotes**: `\Q...\E` _<a href="https://github.com/k-takata/Onigmo/blob/master/doc/RE#L452/" title="Links to master branch, may change">[See]</a>_
  - **Capture History**: `(?@...)`, `(?@<name>...)` _<a href="https://github.com/k-takata/Onigmo/blob/master/doc/RE#L499" title="Links to master branch, may change">[See]</a>_


See something missing? Please submit an [issue](https://github.com/ammar/regexp_parser/issues)

_**Note**: Attempting to process expressions with unsupported syntax features can raise an error,
or incorrectly return tokens/objects as literals._


## Testing
To run the tests simply run rake from the root directory, as 'test' is the default task.

In addition to the main test task, which runs all tests, there are also component specific test
tasks, which only run the tests for one component at a time. These are:

* test:scanner
* test:lexer
* test:parser
* test:expression
* test:syntax

_A special task 'test:full' generates the scanner's code from the ragel source files and
runs all the tests. This task requires ragel to be installed._


The tests use ruby's test/unit. They can also be run with:

```
bin/test
```

The test runner accepts all arguments accepted by test/unit.  You can run a specific test like so:

```
bin/test test/scanner/test_properties.rb
```

It is sometimes helpful during development to focus on a specific test case, for example:

```
bin/test test/expression/test_base.rb -n test_expression_to_re
```


## Building
Building the scanner and the gem requires [ragel](http://www.colm.net/open-source/ragel/) to be
installed. The build tasks will automatically invoke the 'ragel:rb' task to generate the
ruby scanner code.


The project uses the standard rubygems package tasks, so:


To build the gem, run:
```
rake build
```

To install the gem from the cloned project, run:
```
rake install
```


## References
Documentation and books used while working on this project.


#### Ruby Flavors
* Oniguruma Regular Expressions (Ruby 1.9.x) [link](https://github.com/kkos/oniguruma/blob/master/doc/RE)
* Onigmo Regular Expressions (Ruby >= 2.0) [link](https://github.com/k-takata/Onigmo/blob/master/doc/RE)


#### Regular Expressions
* Mastering Regular Expressions, By Jeffrey E.F. Friedl (2nd Edition) [book](http://oreilly.com/catalog/9781565922570/)
* Regular Expression Flavor Comparison [link](http://www.regular-expressions.info/refflavors.html)
* Enumerating the strings of regular languages [link](http://www.cs.dartmouth.edu/~doug/nfa.ps.gz)
* Stack Overflow Regular Expressions FAQ [link](http://stackoverflow.com/questions/22937618/reference-what-does-this-regex-mean/22944075#22944075)


#### Unicode
* Unicode Explained, By Jukka K. Korpela. [book](http://oreilly.com/catalog/9780596101213)
* Unicode Derived Properties [link](http://www.unicode.org/Public/UNIDATA/DerivedCoreProperties.txt)
* Unicode Property Aliases [link](http://www.unicode.org/Public/UNIDATA/PropertyAliases.txt)
* Unicode Regular Expressions [link](http://www.unicode.org/reports/tr18/)
* Unicode Standard Annex #44 [link](http://www.unicode.org/reports/tr44/)


---
##### Copyright
_Copyright (c) 2010-2016 Ammar Ali. See LICENSE file for details._
