rakudoc
=======

NAME
====

`JSON::Class` - general purpose JSON de-/serialization for Raku

SYNOPSIS
========

    clas Record is json {
        has Int $.count;
        has Str $.description;
    }

    say Record.new(:count(42), :description("The Answer")).to-json;

