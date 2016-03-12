[![Build Status](https://travis-ci.org/alehander42/hivemind.svg?branch=master)](https://travis-ci.org/alehander42/hivemind)
[![MIT License](http://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

# hivemind

A prototype of a multi-syntax programming language.

Hivemind has a core language defined by its AST and configurable syntaxes acting like plugins.

The concept of "syntax" for hivemind is similar to

* a theme for a text editor
* a skin for a gui app
* a json/html/xml template for a MVC web app

Syntaxes are defined using code-like examples for core ast nodes and they act in a bidirectional way:
  * they are used to parse source code using that syntax
  * and to render code in that syntax

They look like that:

A pythonic syntax:

```python
#if_statement
if <test>:
    <true_branch>
else:
    <else_branch>

#assign
<left> = <right>

#call
<function>(<<args:', '>>)

#attribute
<object>.<label>

#attribute_assign
<object>.<label> = <right>

#binary
<left> <operation> <right>

#list
[<<elements:', '>>]

#method_statement
method <method_name>(<<args:', '>>):
    <<body>>

#class_statement
class <class_name>:
    <<methods:''>>

#module_statement
module <module_name>:
    <<elements>>

```

A lisp-like syntax

```
#if_statement
(if <test>
    <true_branch>
    <else_branch>)

#assign
(define <left> <right>)

#method_statement
(method <method_name> (<<args:' '>>)
    <<body>>)

#attribute
<object>.<label>

#attribute_assign
(update <object>.<label> <right>)

#binary
(<operation> <left> <right>)

#call
(! <function> <<args:' '>>)

#list
_(<<elements:' '>>)

#class_statement
(class <class_name>
    <<methods>>)

#module_statement
(module <module_name>
    <<elements>>)
```

# Examples

[pythonic example](examples/shape_pythonic.hm)
[schemelike example](examples/shape_paren.hm)

# Installation

```
gem install hivemind
```

# Usage

Run a file

```bash
hivemind <filename>
```

Translate a file into another syntax representation

```bash
hivemind render a.hm pythonic a2.hm
```

# Goals

* Experiment with diffent syntaxes in different contexts
* Use different sub-language seamlessly across the same codebase
* A possible solution for the expression problem (just convert between different representations)

# Language

The core language is just a simple python/ruby-like language for now.

# History

Created for the HackFMI 5

# Future development

* fluid folder/file structure representations
* editor plugins
* more syntaxes

## License

Copyright 2016 [Alexander Ivanov](https://twitter.com/alehander42)

Distributed under the MIT License.

