# NAME

`JSON::Class` - general purpose JSON de-/serialization for Raku

# SYNOPSIS

``` raku
use JSON::Class:auth<zef:vrurg>;

role Base is json(:!skip-null) {
    has Num:D $.size is required is json(:name<volume>);
}

class Record is json does Base {
    has Int $.count;
    has Str $.description;
}

say Record.new(:count(42), :description("The Answer"), :size(1.2e0)).to-json;
```

# DESCRIPTION

This module is an alternative to the family of [`JSON::Marshal`](https://raku.land/zef:jonathanstowe/JSON::Marshal), [`JSON::Unmarshal`](https://raku.land/zef:raku-community-modules/JSON::Unmarshal), [`JSON::Class`](https://raku.land/zef:jonathanstowe/JSON::Class) modules. It tries to get rid of their weak points and shifts the locus of control from class' outers to its inners. In other words, the class itself is responsible for its de-/serialization in first place. Though it's perhaps, the primary difference, it's far from being the only one.

  - **IMPORTANT\!**
    
    In order to use this module it is mandatory to use `:auth<zef:vrurg>` in your `use` statement:
    
    ``` raku
    use JSON::Class:auth<zef:vrurg>
    ```
    
    Otherwise you are likely to accidentally pull in [`JSON::Class:auth<zef:jonathanstowe>`](https://raku.land/zef:jonathanstowe/JSON::Class).

Also, this module tries to follow the standards of [`LibXML::Class`](https://raku.land/zef:vrurg/LibXML::Class) module by adapting them for differing domain of JSON. First of all, they share the same view on the locus of responsibility. Second, they try to implement declarative semantics in first place.

From here on whenever `JSON::Class` name is used it refers to this module unless otherwise stated or implied by the context.

# BASICS

In this section some basic concepts of `JSON::Class` are explained. If you feel like skipping it then skip over to the *QUICK INTRO BY EXAMPLE* section below.

## Basic Or "Complex" Types

Some protocols of `JSON::Class` depend on the kind of type involved. Basic types are considered to be *simple* or *trivially marshalled*. Currently these are [`Mu`](https://docs.raku.org/type/Mu), [`Any`](https://docs.raku.org/type/Any), [`Bool`](https://docs.raku.org/type/Bool), or those consuming [`Numeric`](https://docs.raku.org/type/Numeric), [`Stringy`](https://docs.raku.org/type/Stringy), [`Enumeration`](https://docs.raku.org/type/Enumeration) roles.

A "complex" type is expected to have marshallable attributes.

## Marshalling And JSONification

JSON marshalling requires declaring corresponding entities as JSON-ones, or *JSONification*. Normally this is done by using trait `is json` with classes, roles, or attributes. This is declarative, or explicit, JSONification.

It is also possible that implicit jsonification can be used when necessary or desirable. Normally `JSON::Class` attempts to implement it in a user-transparent way. For example:

``` raku
class Record {...}
class Archive is json {
    has Record:D @.records;
}

my $arch = Archive.new;
... add records to the archive ...
$arch.to-json;
```

The class `Record` above would be implicitly JSONified to produce serialization of a single record. But the JSONified version would never pop on the surface. So, when the archive is deserialized `@.records` will contain instances of the original `Record`.

## Trait

Trait `is json` is used for nearly every declaration of JSON elements. The only other trait we have is `json-wrap`, but it is too early to discuss it.

How something is marshalled is mostly defined by the trait's arguments.

## Declarant

In a context of attribute-related discussion it is the object where the attribute was declared in.

## Config

Marshalling of deep structures often requires sharing of common options, modifying the process. This is implemented by using a *configuration* object. A configuration belongs to a dynamic context of marshalling.

There is also a global configuration singleton used when no other configuration provided.

## JSON Class

A *JSON class* is one which has `is json` trait applied. Sometimes, depending on the context and especially when referring to an instance of the class, another term *JSON object* can be used.

## Laziness

Deserialization of big deeply nested structures could be a long process, no matter if we need an element of the structure right away, or it is going to be requested later, or not used at all. `JSON::Class` attempts to bring some relieve by postponing deserialization for later time.

## Lazy Collections

`JSON::Class` implements two [*collection*](https://en.wikipedia.org/wiki/Collection_\(abstract_data_type\)) types: sequences and dictionaries, namely *JSON sequences* and *JSON dictionaries*. The first is a [`Postional`](https://docs.raku.org/type/Postional) and [`Iterable`](https://docs.raku.org/type/Iterable), the second is an [`Associative`](https://docs.raku.org/type/Associative).

Both types are primarily defined by these two properties:

  - their elements are lazily deserialized on demand

  - they do their best to serve as a container for multiple types, including user classes

### JSON Sequence

*JSON sequence* is a class with `is json( :sequence(...) )` trait applied.

Term "sequence" is used here for something that is rather an array and, most definitely, not a sequence ([`Seq`](https://docs.raku.org/type/Seq)) from Raku's point of view. The term was borrowed from [`LibXML::Class`](https://raku.land/zef:vrurg/LibXML::Class), which implements the same concept, and where it was adopted from XML schema definitions.

### JSON Dictionary

*JSON dictionary* is, in a way, similar to JSON sequence in terms of been a lazily deserialized collection. Dictionary is an [`Associative`](https://docs.raku.org/type/Associative) implementation produced with `is json( :dictionary(...) )`.

## Explicit Or Implicit Typeobjects

It could be tedious to marshal a class with many attributes. Most use cases assume that entire object would end up mapped into a JSON structure. Therefore `JSON::Class` defaults to *implicit* declaration where all public or `is built` attributes are JSONified wihout needing explicit `is json` trait. This is the case demoed in the SYNOPSIS.

In explicit mode one has to manually apply the trait to marshallable attributes.

## Declaration

As it was stated earlier, `is json` is the primary and, basically, the only declarator used by the module. The trait accepts various arguments to modify the declaration according to one's needs. For example, an explicit class is to be declared as:

``` raku
class ComplexOne is json(:!implicit) {...}
```

Within the class an attribute for marshalling is to be also marked with `is json`:

``` raku
has SomeType $.st is required is json(:skip-null, :!lazy);
```

## Naming Convention

With only few exceptions, names of all attributes and methods introduced by `JSON::Class` distribution are starting with `json-` prefix. This rule may not be followed by some internal data structures, but is almost 100% true about entities injected into JSONified typeobject as part of their public or private API.

There is a consequence to this rule: implicit JSONification of attributes skips these with `json-`-prefixed names:

  - From [examples/json-pfx-attr.raku](examples/json-pfx-attr.raku)
    
    ``` raku
    class Foo is json(:implicit) {
        has Int $.foo;
        has Str $.json-invisible;
    }
    
    my $foo = Foo.new(:foo(42), :json-invisible("The Answer"));
    say "JSON      : ", $foo.to-json;
    say "Attribute : ", $foo.json-invisible;
    ```
    
    Sample output:
    
    ``` 
    JSON      : {"foo":42}
    Attribute : The Answer
    ```

## Trait Arguments

### Common For Classes And Roles

  - `Bool` **`:implicit`**
    
    Set typeobject explicit/implicit mode. Omitting this argument assumes that the typeoject is implicit unless at least one attribute has an explicit [`is json` declaration](#Attribute).
    
    See [*examples/decl-implicit.raku*](examples/decl-implicit.raku).

  - `Bool` **`:lazy`**
    
    Set typeobject lazyness. When the argument is omitted attributes are set to *non-lazy* if they have a *basic type*, and set to *lazy* otherwise.
    
    When the argument is used all attributes of the typeobject use it as their default, unless their own mode is set manually. See [*examples/decl-lazy.raku*](examples/decl-lazy.raku).

  - `Bool` **`:skip-null`**
    
    If *True* then attributes of this typeobject are not serialized if their value is undefined. When omitted then value of this parameter is obtained from the configuration object. See [*t/020-json-basics.rakutest*](t/020-json-basics.rakutest), subtest "Undefineds".

  - **`:sequence(...)`**
    
    This type object is a sequence. See the [Sequences](#Sequences) section.

  - **`:dictionary(...)`** or **`:dict(...)`**
    
    This type object is a dictionary. See the [Dictionaries](#Dictionaries) section.

  - **`:is(...)`**, **`:does(...)`**
    
    These arguments allow to incorporate additional non-JSON parent classes and/or roles. See [Incorporation](#Incorporation) section.

### Class-only

  - `Bool` **`:pretty`**, `Bool` **`:sorted-keys`**
    
    This two arguments set default values for corresponding config parameters but only if the type object is the initiator of serialization. Normally it means that method `to-json` is called on an instance of this typeobject, and that the call is not made inside a dynamic context of another `to-json`-initiated serialization. More practically, it means that dynamic variable `$*JSON-CLASS-CONFIG` is not set.

### Attribute

Parameters set via `is json` trait for attributes are normally overriding these set by its declarant. Moreover, unless the declarant is using `:implicit` or `:!implicit` argument with its `is json` trait then declaring an attribute as JSON-marshallable turns its typeobject into an explicit one.

There is an exception though: adverbs `:skip`, `:build`, and `:aliases`, used in any combination, but with no other arguments, doesn't affect the status of attribute's declarant.

  - `Bool` **`:skip`**
    
    Don't ever marshalize this attribute. Mostly useful for `:implicit` typeobjects when one or more attributes are to be ignored. Negation of this argument makes no sense.

  - `Bool` **`:skip-null`**
    
    Set `skip-null` parameter individually for this attribute, no matter what is set for the declarant.

  - `Str` **`:name`**
    
    Normally key name of a JSON object to which an attribute serializes is given after attribute's name, omitting its sigil and twigil. With `:name` this value can be altered to something different.

  - `Array[Str:D]` **`:alias`** or `B<:aliases>`
    
    This adverb has the same meaning as its counterpart in [`AttrX::Mooish`](https://raku.land/?q=AttrX::Mooish): it allows an attribute to have more than one name. **Note** though that this adverb doesn't affect marshalling where only one JSON key name is allowed.

  - `Bool` **`:lazy`**
    
    Force laziness mode of this attribute.

  - `Bool` **`:serializer(...)`**, `Bool` **`:deserializer(...)`**
    
    Allowed aliases are `:to-json` and `:from-json`, correspondingly.
    
    Specify custom marshallers for the attribute. Normally that'd be either a method name on attribute's type, or an explicit code object. For associative and positional attributes additional marshallers for keys and values are available via `:key` and `:value` named arguments. Apparently, only the latter works with positionals:
    
    ``` raku
    has %.assoc is json(
        :serializer(
            key => { "pfx-" ~ $^key },
            value => { $^value.raku } ),
        :deserializer(
            key => { $^from.substr(4) },
            value => { $^from.EVAL } ));
    ```
    
    See 'Custom Marshallers' in [`JSON::Class::Details`](docs/md/JSON/Class/Details.md).

  - `Bool:D | Str:D | Code:D` **`:build(...)`**
    
    Lazily build attribute value upon read unless it's been initialized already from other sources like a constructor argument, or a value from JSON structure. Unless you're familiar with [`AttrX::Mooish`](https://raku.land/?q=AttrX::Mooish), then think of this adverb as a kind of [`is default`](https://docs.raku.org/type/Attribute#Trait_is_default) trait but with some specifics.
    
    Depending on adverb format different ways of building attribute's value are used:
    
      - **`:build`**
        
        Attribute base name is taken (i.e. with no sigil or twigil), prepended with *'build-'* prefix and the result is taken as the method name. For example, for `$.foo` the method name would be *"build-foo"*.
        
        `:!build` is a [NOP](https://en.wikipedia.org/wiki/NOP_\(code\)).
    
      - **`:build("method-name")`**
        
        An explicit method name to use.
    
      - **`:build(&code)`**
        
        Particular code object (routine, block, etc.).
    
    Value returned by either of the above variant is used to initialize the attribute.
    
    See [*examples/lazy-build.raku*](examples/lazy-build.raku) and subtest "Lazy Build" in [*t/020-json-basics.rakutest*](t/020-json-basics.rakutest).

### Collections

A class is declared as a JSON collection with `:sequence` or `:dictionary` (also aliased as `:dict`) adverbs of the `is json` trait. The adverbs are expected to be a list of declarations where each item of the list either specify a type constraint or a default value. For dictionaries it is possible to type constrain their keys.

A type constraint declaration can be either:

  - a plain typeobject
    
    Int:D:D

  - a typeobject with modifiers as a list
    
    ``` 
    (Foo, :&serializer, :&deserializer)
    ```

  - a [`Pair`](https://docs.raku.org/type/Pair) of a type object and a list of modifiers:
    
    ``` 
    (Bar) => (:to-json(&bar2json), :from-json(&json2bar))
    ```

Typeobject modifiers are:

  - **`:$serializer`** AKA **`:$to-json`**

  - **`:$deserializer`** AKA **`:$from-json`**

  - **`:$matcher`**

The last one's meaning is explained below in this section.

The **`:default`** declaration is similar in semantics to the `is default` trait: it sets the value to be used when `Nil` is assigned into a sequence position, or when a non-existing element requested:

``` raku
class JDict is json(:dict(..., :default(42))) {}

say JDict.new.<not-here-yet>; # 42
```

Default is not obliged to be a concrete value.

Whenever a collection is declared with multiple types it is equivalent to declaring an array or a hash with a subset matching all the same types:

``` raku
class JSeq is json(:sequece(Int:D, Str:D, Foo)) {}
```

be like:

``` raku
my subset JSeqOf of Mu where Int:D | Str:D | Foo;
my JSeqOF @jseq;
```

  - *Note*
    
    There is a potential problem with this declaration: assigning a `Nil` will result in a type mismatch because the default value would me [`Mu`](https://docs.raku.org/type/Mu), but it doesn't match the subset. Therefore a safe way to do it would be something like:
    
    ``` raku
    class JSeq is json(:sequece(Int:D, Str:D, Foo, :default(Foo))) {}
    ```

#### Dictionary Only Declaration

**`:keyof(...)`** declaration can only be used with the `:dictionary` adverb. It's value has the same format as a single type constraint declaration:

``` raku
class JDict is json( :dictionary( ..., :keyof(Foo:D()) ) )
```

``` raku
class JDict is json( :dictionary( ..., :keyof(Foo:D(), :serializer(&foo2json), :deserializer(&json2foo)) ) )
```

#### The Multitype Matching Problem

When a collection is declared with two or more value classes that are not basic types a problem of matching JSON object to a class arises. Apparently, JSON itself lacks any means of distinguishing one JSON object from another *(kids, let's say "Hello\!" to JavaScript's OO\!)*. In other words, having something like:

``` JSON
[
    {"key1": 1, "key2":"a string"},
    {"keyA": 3.1415926, "keyB": "const"}
]
```

One wouldn't be able to tell what classes each JSON object represents. The only way for us to distinguish is to guess. Say, we have:

``` raku
class Foo {
    has Int $.key1;
    has Str $.key2;
}
class Bar {
    has Num $.keyA;
    has Str $.keyB;
}
```

In this case it is obvious that the first JSON object matches `Foo`, whereas the other one matches `Bar`.

This is what `JSON::Class` sequence basically does by default: it compares sets of keys per each class-candidate to the keys of JSON object. So far – so good, until a very rare case pops up where two classes has the same key names. Say:

``` raku
class Book {
    has Str:D $.id is required;
    has Str:D $.name is requried;
}
class Article {
    has Str:D $.id is required;
    has Str:D $.name is required;
}
```

The default matching algorithm would throw here with `JSON::Class::X::Deserialize::SeqItem` or `JSON::Class::X::Deserialize::DictItem` exception, depending on the collection type, due to the unresolvable ambiguity. What can we do to avoid that?

One can work around the problem by introducing extra layers of data, for example:

``` raku
class BookOrArticle is json {
    has Book $.book;
    has Article $.article;
}
```

This approach unreasonably complicates things and not even always possible.

But what if we know that IDs of books and articles are sufficiently different to tell exactly which is is which? For example, book ID could start with *ISBN:*, whereas article ID starts with a date-based *YYYY-MM-DD:* prefix? In this case custom matchers can distinguish one JSON object from another:

  - From [examples/book-article-seq.raku](examples/book-article-seq.raku)
    
    ``` raku
    class Book {
        has Str:D $.id is required;
        has Str:D $.name is required;
    }
    class Article {
        has Str:D $.id is required;
        has Str:D $.name is required;
    
        method is-an-article(%from) {
            ? (%from<id> ~~ /^ \d ** 4 '-' \d ** 2 '-' \d ** 2 ':'/)
        }
    }
    
    sub is-a-book(%from) { %from<id>.starts-with("ISBN:") }
    
    class BoxOfPapers is json(:sequence( (Book, :matcher(&is-a-book)), (Article, :matcher<is-an-article>) )) {}
    
    my $json = q:to/JSON/;
    [
        {"id": "ISBN:1234", "name": "The Guide"},
        {"id": "2006-04-01:the-pop-one", "name":"What's the programmer's most popular book out there?"}
    ]
    JSON
    
    my $box = BoxOfPapers.from-json($json);
    say $box.map(*.gist).join("\n");
    ```
    
    Sample output:
    
    ``` 
    Book.new(id => "ISBN:1234", name => "The Guide")
    Article.new(id => "2006-04-01:the-pop-one", name => "What's the programmer's most popular book out there?")
    ```

This approach, in essence, is applicable to dictionaries too.

There are other ways of solving this task that involve custom marshalling where we can manipulate with serializable data or keys to inject clues as to what's the source type of JSON object was.

#### Alternative Solutions To Matching

A universal matcher for type can also be set using [`JSON::Class::Config`](docs/md/JSON/Class/Config.md) `set-helpers` method.

Another way is to try overriding `json-guess-descriptor` method of a container class. In this case it would even be possible to base your guess on value's position is a sequence, or its key in a dictionary. But to do so one is better be familiar with the internals of `JSON::Class`.

# DYNAMIC VARIABLES

  - `JSON::Class::Config` **`$*JSON-CLASS-CONFIG`**
    
    Configuration object. When not available it means we're out of the context of `to-json` or `from-json` methods.

  - **`$*JSON-CLASS-SELF`**
    
    The invocant of `json-serialize` or `json-deserialize` methods.

  - [`JSON::Class::Descriptor`](docs/md/JSON/Class/Descriptor.md) **`$*JSON-CLASS-DESCRIPTOR`**
    
    Descriptor of the currently being marshalled attribute or sequence item.

# QUICK INTRO BY EXAMPLE

This section contains a series of working code examples demonstrating different features of this module. The samples are slightly stripped down to keep focus on their functionality and don't bother you with boilerplate. Their full code can be found under *examples/* subdirectory of the distribution.

## Explicit/Implicit

  - From [examples/decl-implicit.raku](examples/decl-implicit.raku)
    
    ``` raku
    class Foo is json {
        has $.foo;
    }
    
    say "Foo is explicit: ", Foo.^json-is-explicit, "\n",
        " has 'foo' key : ", Foo.^json-has-key('foo');
    
    class Bar is json {
        has $.bar1;
        has $.bar2 is json;
    }
    
    say "Bar is explicit: ", Bar.^json-is-explicit, "\n",
        " has 'bar1' key: ", Bar.^json-has-key('bar1'), "\n",
        " has 'bar2' key: ", Bar.^json-has-key('bar2');
    ```
    
    Sample output:
    
    ``` 
    Foo is explicit: False
     has 'foo' key : True
    Bar is explicit: True
     has 'bar1' key: False
     has 'bar2' key: True
    ```

## Inheritance And Role Consumption

  - From [examples/simple-inherit.raku](examples/simple-inherit.raku)
    
    ``` raku
    role R is json {
        has Bool $.flag;
    }
    
    class C1 does R is json {
        has Int $.count;
    }
    
    class C2 is json is C1 {
        has Str $.what;
    }
    
    my $obj = C2.new(:count(3), :what("whatever you like"), :flag);
    say $obj.to-json(:pretty, :sorted-keys);
    ```
    
    Sample output:
    
    ``` 
    {
      "count": 3,
      "flag": true,
      "what": "whatever you like"
    }
    ```

## Incorporation

Notice that except for `C3`, all other classes and roles are not JSONified. Only attributes of `C1` and `R1` are serialized.

  - From [examples/incorporation.raku](examples/incorporation.raku)
    
    ``` raku
    role R1 {
        has Bool $.flag;
    }
    
    role R2 {
        has Num $.cost;
    }
    
    class C1 {
        has Int $.count;
    }
    
    class C2 {
        has Num $.total;
    }
    
    class C3 is json(:is(C1), :does(R1)) does R2 is C2 {
        has Str $.what;
    }
    
    my $obj = C3.new(:count(3), :what("whatever you like"), :flag, :cost(1.2e0), :total(1e3));
    say $obj.to-json(:pretty, :sorted-keys);
    ```
    
    Sample output:
    
    ``` 
    {
      "count": 3,
      "flag": true,
      "what": "whatever you like"
    }
    ```

## Lazy Deserialization

  - From [examples/decl-lazy.raku](examples/decl-lazy.raku)
    
    ``` raku
    class Item {
        has $.something;
    }
    
    class Foo is json {
        has Str $.foo;   # Basic types are eager by default
        has Item $.item; # Non-basic types is lazy by default
    }
    
    say "--- Foo";
    say "    .foo lazy      : ", Foo.^json-get-key("foo").lazy;
    say "    .item lazy     : ", Foo.^json-get-key("item").lazy;
    
    class Bar is json(:lazy, :implicit) {
        has Str $.bar;
        has Item $.item;
        has Item $.item2 is json(:!lazy);
    }
    
    say "--- Bar";
    say "    .bar is lazy   : ", Bar.^json-get-key('bar').lazy;
    say "    .item is lazy  : ", Bar.^json-get-key('item').lazy;
    say "    .item2 is lazy : ", Bar.^json-get-key('item2').lazy;
    
    class Baz is json(:!lazy, :implicit) {
        has Str $.baz;
        has Item $.item;
        has Item $.item2 is json(:lazy);
    }
    
    say "--- Baz";
    say "    .baz lazy      : ", Baz.^json-get-key("baz").lazy;
    say "    .item lazy     : ", Baz.^json-get-key("item").lazy;
    say "    .item2 lazy    : ", Baz.^json-get-key("item2").lazy;
    ```
    
    Sample output:
    
    ``` 
    --- Foo
        .foo lazy      : False
        .item lazy     : True
    --- Bar
        .bar is lazy   : True
        .item is lazy  : True
        .item2 is lazy : False
    --- Baz
        .baz lazy      : False
        .item lazy     : False
        .item2 lazy    : True
    ```

## Lazy Attribute Build

  - From [examples/lazy-build.raku](examples/lazy-build.raku)
    
    ``` raku
    class LazyRec is json(:lazy) {
        has $.attr1 is json(:build);
        has $.attr2 is json(:build<build-attr1>);
        has @.attr3 is json(:build(-> $ { "π", pi, "the answer", 42 }));
        has %.attr4 is json(:build<new-map>);
    
        method build-attr1(JSON::Class::Attr:D $descr) {
            say "Builder for attr1 for ", $descr.json-name;
            "for " ~ $descr.name
        }
        method new-map($) { :key<value>, :!flag }
    }
    
    my $lr = LazyRec.new;
    say "- attr1: ", $lr.attr1;
    say "- attr2: ", $lr.attr2;
    say "- attr3: ", $lr.attr3;
    say "- attr4: ", $lr.attr4;
    ```
    
    Sample output:
    
    ``` 
    Builder for attr1 for attr1
    - attr1: for $!attr1
    Builder for attr1 for attr2
    - attr2: for $!attr2
    - attr3: [π 3.141592653589793 the answer 42]
    - attr4: {flag => False, key => value}
    ```

## Config Defaults

`C1` specify config defaults but they affect the output only when the immediate instance of the class is serialized. Otherwise if a subclass instance is serialized then its defaults are used. This is to preserve the uniformity of serialization.

  - From [examples/config-defaults.raku](examples/config-defaults.raku)
    
    ``` raku
    class C1 is json(:pretty, :sorted-keys) {
        has Int $.count;
        has Str $.what;
    }
    
    class C2 is C1 is json(:!skip-null) { }
    
    my $c1 = C1.new(:count(42), :what("The Answer"));
    say "--- C1 serialization:\n", $c1.to-json;
    my $c2 = C2.new(:count(42), :what("The Answer"));
    say "--- C2 serialization:\n", $c2.to-json;
    ```
    
    Sample output:
    
    ``` 
    --- C1 serialization:
    {
      "count": 42,
      "what": "The Answer"
    }
    --- C2 serialization:
    {"count":42,"what":"The Answer"}
    ```

## Sequence

This example is a bit verbose from both code and output perspective. It's point is to demonstrate the difference between an array and a JSON Sequence type. The following aspects a worth paying attention to:

  - Multi-type support. See *The Multitype Matching Problem* section above.

  - Lazy deserialization of individual elements of the sequence. This may come handy when dealing with big arrays of objects where only few of them are actually needed.

Apparently, this example doesn't cover all of `JSON::Class` sequence features.

  - From [examples/simple-sequence.raku](examples/simple-sequence.raku)
    
    ``` raku
    class Item1 is json {
        has Str $.id;
        has Int $.quantity;
    }
    
    class Item2 is json {
        has Str $.section;
        has Str $.chapter;
    }
    
    class JSeq is json(:sequence(Str:D, Item1:D, Item2:D, :default<removed>)) {
        method json-deserialize-item($idx, \json-value) is raw {
            say "... deserializing [$idx] ...";
            nextsame
        }
    }
    
    my $jseq = JSeq.new("something", Item2.new(:section<S>, :chapter("22.1")));
    
    $jseq.push: Item1.new(:id<EBCA-12F>, :quantity(13));
    $jseq.push: "final";
    
    say "--- Initial    : ", $jseq.to-json;
    say "--- Delete 2nd : ", $jseq[1]:delete;
    say "--- 2nd deleted: ", $jseq.to-json;
    my $deserialized := JSeq.from-json: q<["something",{"quantity":12,"id":"9123-BBB"},"different",{"section":"B","chapter":"2.9b"}]>;
    for ^$deserialized.elems -> $idx {
        say "\n--- $idx ---";
        say "Deserialized before accessing? ", $deserialized[$idx]:has;
        say "Item: ", $deserialized[$idx].raku;
        say "Deserialized after accessing? ", $deserialized[$idx]:has;
    }
    ```
    
    Sample output:
    
    ``` 
    --- Initial    : ["something",{"section":"S","chapter":"22.1"},{"id":"EBCA-12F","quantity":13},"final"]
    --- Delete 2nd : Item2.new(section => "S", chapter => "22.1")
    --- 2nd deleted: ["something","removed",{"id":"EBCA-12F","quantity":13},"final"]
    
    --- 0 ---
    Deserialized before accessing? False
    ... deserializing [0] ...
    Item: "something"
    Deserialized after accessing? True
    
    --- 1 ---
    Deserialized before accessing? False
    ... deserializing [1] ...
    Item: Item1.new(id => "9123-BBB", quantity => 12)
    Deserialized after accessing? True
    
    --- 2 ---
    Deserialized before accessing? False
    ... deserializing [2] ...
    Item: "different"
    Deserialized after accessing? True
    
    --- 3 ---
    Deserialized before accessing? False
    ... deserializing [3] ...
    Item: Item2.new(section => "B", chapter => "2.9b")
    Deserialized after accessing? True
    ```

## Dictionary

  - From [examples/simple-dictionary.raku](examples/simple-dictionary.raku)
    
    ``` raku
    class Item1 is json {
        has Str $.id;
        has Int $.quantity;
    }
    
    class Item2 is json {
        has Str $.section;
        has Str $.chapter;
    }
    
    class JDict
        is json(
            :dictionary( Str:D, Item1:D, Item2:D, :default("<not there>") ) )
    {
        method json-deserialize-item(Mu \key, |) {
            say "... deserializing key '", key, "'";
            nextsame
        }
    }
    
    #my $jdict = JDict.new;
    my %jdict is JDict =
        "plain" => "string",
        "i1" => Item1.new(:id<AB12-EFZK>, :quantity(2));
    
    %jdict.push: "i2" => Item2.new(:section<D>, :chapter("66.6"));
    
    say "--- Initial        : ", %jdict.to-json;
    say "--- Delete i1      : ", %jdict<i1>:delete;
    say "--- Default is     : ", %jdict<this-never-been-here>;
    say "--- JSON without i1: ", %jdict.to-json;
    
    my $deserialized =
        JDict.from-json(
            q<{"sval":"some string","entry1":{"id":"FROM-JSON","quantity":0},"in":{"section":"DS","chapter":"43.2.1"}}>);
    
    for $deserialized.keys -> $key {
        say "\n--- Key '$key' ---";
        say "Deserialized before accessing? ", $deserialized{$key}:has;
        say "Value: ", $deserialized{$key};
        say "Deserialized after accessing? ", $deserialized{$key}:has;
    }
    ```
    
    Sample output:
    
    ``` 
    --- Initial        : {"plain":"string","i2":{"chapter":"66.6","section":"D"},"i1":{"id":"AB12-EFZK","quantity":2}}
    --- Delete i1      : Item1.new(id => "AB12-EFZK", quantity => 2)
    --- Default is     : <not there>
    --- JSON without i1: {"plain":"string","i2":{"section":"D","chapter":"66.6"}}
    
    --- Key 'in' ---
    Deserialized before accessing? False
    ... deserializing key 'in'
    Value: Item2.new(section => "DS", chapter => "43.2.1")
    Deserialized after accessing? True
    
    --- Key 'entry1' ---
    Deserialized before accessing? False
    ... deserializing key 'entry1'
    Value: Item1.new(id => "FROM-JSON", quantity => 0)
    Deserialized after accessing? True
    
    --- Key 'sval' ---
    Deserialized before accessing? False
    ... deserializing key 'sval'
    Value: some string
    Deserialized after accessing? True
    ```

## Array Attributes

  - From [examples/typed-array.raku](examples/typed-array.raku)
    
    ``` raku
    class Rec {
        has Str:D $.description is required;
    }
    
    class Struct is json(:implicit) {
        has Array:D[Real:D] @.matrix;
        has Rec:D %.rec is json(:name<records>);
    }
    
    my $struct =
        Struct.new:
            matrix => [
                [1, 2],
                [pi, e],
                [42.12, 13.666, 4321],
            ],
            rec => {
                R1 => Rec.new(:description("test description")),
                R2 => Rec.new(:description("test description 2")),
            };
    
    say "=== Serializing ===";
    say $struct.to-json(:pretty, :sorted-keys);
    
    say "=== Deserializing ===";
    my $deserialized =
        Struct.from-json:
            q<{"matrix":[[3,4,5],[3.141592653589793e0,2.718281828459045e0],[42.0,32.16,99]],
               "records":{"R1":{"description":"for the first"},"R2":{"description":"for the second"}}}>;
    
    say "Has .matrix: ", $deserialized.json-has-matrix;
    say "Has .rec   : ", $deserialized.json-has-records; # JSON key name is used for method name
    say "Matrix     : ", $deserialized.matrix;
    say "Has .matrix: ", $deserialized.json-has-matrix;
    say "Has .rec   : ", $deserialized.json-has-records;
    say "Records    : ", $deserialized.rec;
    say "Has .matrix: ", $deserialized.json-has-matrix;
    say "Has .rec   : ", $deserialized.json-has-records;
    ```
    
    Sample output:
    
    ``` 
    === Serializing ===
    {
      "matrix": [
        [
          1,
          2
        ],
        [
          3.141592653589793e0,
          2.718281828459045e0
        ],
        [
          42.12,
          13.666,
          4321
        ]
      ],
      "records": {
        "R1": {
          "description": "test description"
        },
        "R2": {
          "description": "test description 2"
        }
      }
    }
    === Deserializing ===
    Has .matrix: False
    Has .rec   : False
    Matrix     : [[3 4 5] [3.141592653589793 2.718281828459045] [42 32.16 99]]
    Has .matrix: True
    Has .rec   : False
    Records    : {R1 => Rec.new(description => "for the first"), R2 => Rec.new(description => "for the second")}
    Has .matrix: True
    Has .rec   : True
    ```

## Using Configuration And Type Mapping

These two subjects are tightly bound to each other, hence single example for both subjects.

  - From [examples/config-and-type-map.raku](examples/config-and-type-map.raku)
    
    ``` raku
    # To set global defaults .global to be invoked as early as possible or otherwise the global config can be vivified
    # somewhere else with standard defaults.
    JSON::Class::Config.global: :pretty, :sorted-keys, :!skip-null;
    
    class Record is json {
        has Int $.count;
        has Str $.what;
    }
    
    class Status {
        has Str $.code;
        has Bool $.verified;
        has Str $.notes;
    }
    
    # Indicate that this class wants to replace Record whenever possible.
    class RecWrapper is json-wrap(Record) {
        has Bool $.available is mooish(:lazy);
    
        method build-available {
            $.count > 0;
        }
    }
    
    class StatusTools is Status {
        # Just a mockup of what could be used for accessing some API, for example.
        method update-record {
            "will-update" => $.code
        }
    }
    
    JSON::Class::Config.map-types: RecWrapper, (Status) => StatusTools;
    
    class Foo is json {
        has Record:D $.record is required is json(:name<rec>);
        has Status:D $.status is required is json(:name<st>);
    }
    
    say "--- Using global config with type maps";
    my $foo =
        Foo.from-json:
            q<{"rec":{"count":0,"what":"irrelevant"},"st":{"code":"1A-CD3","verified":false,"notes":"to be done"}}>;
    
    say ".record attribute type: ", $foo.record.^name;
    say ".status attribute type: ", $foo.status.^name;
    
    $foo.status.update-record;
    
    say "Serialization of mapped types:\n", $foo.to-json.indent(2);
    
    say "--- Using custom config with no type maps";
    my $config = JSON::Class::Config.new;
    
    $foo = Foo.from-json:
                q<{"rec":{"count":0,"what":"irrelevant"},"st":{"code":"1A-CD3","verified":false,"notes":"to be done"}}>,
                :$config;
    
    say ".record attribute type: ", $foo.record.^name;
    say ".status attribute type: ", $foo.status.^name;
    
    try { $foo.status.update-record };
    say "We expect an exception here: ", $!.^name;
    say "Exception message: ", $!.message;
    
    say "Serialization with custom config using standard defaults:\n", $foo.to-json(:$config).indent(2);
    ```
    
    Sample output. Notice how different configuration defaults affect serialization output without passing any arguments to the `to-json` method:
    
    ``` 
    --- Using global config with type maps
    .record attribute type: RecWrapper
    .status attribute type: StatusTools
    Serialization of mapped types:
      {
        "rec": {
          "count": 0,
          "what": "irrelevant"
        },
        "st": {
          "code": "1A-CD3",
          "notes": "to be done",
          "verified": false
        }
      }
    --- Using custom config with no type maps
    .record attribute type: Record
    .status attribute type: Status
    We expect an exception here: X::Method::NotFound
    Exception message: No such method 'update-record' for invocant of type 'Status'
    Serialization with custom config using standard defaults:
      {"rec":{"count":0,"what":"irrelevant"},"st":{"verified":false,"code":"1A-CD3","notes":"to be done"}}
    ```

## Custom Serialziers And Deserializers

There are more than we can fit into this example. We can have individual custom marshalling for hash and array values, and hash keys too. We can specify marshallers for sequence elements too.

  - From [examples/custom-marshallers.raku](examples/custom-marshallers.raku)
    
    ``` raku
    class Record is json {
        has Str $.description is json( :serializer({ "pfx:" ~ $_ }),    # :to-json alias can be used instead
                                       :deserializer({ .substr(4) }) ); # :from-json can be used instead
    }
    
    class Article is json {
        has Str $.title;
    
        method serialize {
            %{ "-ttl-" => $!title }
        }
        method deserialize(%p) {
            die "bad profile" unless %p<-ttl->;
            self.new: title => %p<-ttl->;
        }
    }
    
    class Foo is json {
        has Record:D $.rec is required;
        has Article:D $.article is required;
    }
    
    my $config = JSON::Class::Config.new(:pretty, :sorted-keys);
    $config.set-helpers: Article, serializer => 'serialize', deserializer => 'deserialize';
    
    my $foo = Foo.new:
                rec => Record.new(:description("means nothing")),
                article => Article.new(:title("The Deep Thought: Complexity Of The Answer"));
    
    say "Custom serializers affect JSON:\n", $foo.to-json(:$config).indent(2);
    # "article" key is affected, but "rec" is using attribute's marshallizers.
    say "Serializing with default config:\n", $foo.to-json(:pretty, :sorted-keys).indent(2);
    
    $foo = Foo.from-json:
            q<{"rec":{"description":"pfx:stuff"},"article":{"-ttl-":"The Deep Thought: Gimme A Bit More Time"}}>,
            :$config;
    
    say "Custom deserializers handle 'weird' JSON:\n", $foo.raku.indent(2);
    ```
    
    Sample output:
    
    ``` 
    Custom serializers affect JSON:
      {
        "article": {
          "-ttl-": "The Deep Thought: Complexity Of The Answer"
        },
        "rec": {
          "description": "pfx:means nothing"
        }
      }
    Serializing with default config:
      {
        "article": {
          "title": "The Deep Thought: Complexity Of The Answer"
        },
        "rec": {
          "description": "pfx:means nothing"
        }
      }
    Custom deserializers handle 'weird' JSON:
      Foo.new(rec => Record.new(description => "stuff"), article => Article.new(title => "The Deep Thought: Gimme A Bit More Time"))
    ```

## Skipping Custom Marshalling

Here we use custom marshallers too, this time for array values. But there is a trick: serializer and deserializer do not modify every third value. To do so they call `json-I-cant` routine giving up the task to `JSON::Class`

  - From [examples/skipping-marshalling.raku](examples/skipping-marshalling.raku)
    
    ``` raku
    my $skiped-serializations = 0;
    my $skipped-deserializations = 0;
    
    class Foo is json {
        has Int:D @.counts is json(
            :serializer(
                value => -> $v {
                    if $v % 3 == 0 {
                        ++$skiped-serializations;
                        json-I-cant
                    }
                    $v * 1000
                } ),
            :deserializer(
                value => -> $v {
                    if $v < 1000 {
                        ++$skipped-deserializations;
                        json-I-cant
                    }
                    $v div 1000
                } ));
    }
    
    my $foo = Foo.new(counts => ^22);
    
    my $json = $foo.to-json;
    
    say $json;
    say Foo.from-json($json);
    say "I skipped ", $skiped-serializations, " serializations and ", $skipped-deserializations, " deserializations";
    ```
    
    Sample output:
    
    ``` 
    {"counts":[0,1000,2000,3,4000,5000,6,7000,8000,9,10000,11000,12,13000,14000,15,16000,17000,18,19000,20000,21]}
    Foo.new(counts => Array[Int:D].new(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21))
    I skipped 8 serializations and 8 deserializations
    ```

# METHODS

## JSONified Class

  - **`method to-json(:$config, Bool :$raw, Bool :$pretty, Bool :$sorted-keys, Bool :$enums-as-value, UInt :$spacing)`**
    
    Serialize an instance of JSON class. Arguments:
    
      - [`JSON::Class::Config:D`](docs/md/JSON/Class/Config.md) **`:$config`**, **`:%config`**
        
        Either a configuration object or a profile hash which will be used to create one.
    
      - `Bool` **`:$raw`**
        
        If *True* then the method will return raw serialization of the object, i.e. a [`Hash`](https://docs.raku.org/type/Hash).
    
      - `Bool` **`:$pretty`**, `Bool` **`:$sorted-keys`**, `Bool` **`:$enums-as-value`**, `UInt` **`:$spacing`**
        
        Same as [`JSON::Fast`](https://raku.land/cpan:TIMOTIMO/JSON::Fast) `to-json` arguments.

  - **`proto method from-json(|)`**
    
      - **`method from-json(Str:D $json, :$config, Bool :$allow-jsonc, Bool :$enums-as-value)`**
    
      - **`method from-json(%json, :$config, Bool :$allow-jsonc, Bool :$enums-as-value)`**
    
      - **`method from-json(@json, :$config, Bool :$allow-jsonc, Bool :$enums-as-value)`**
    
    Deserialize JSON class from either a JSON string, or raw hash or array.
    
      - `Str:d` **`$json`**
        
        JSON source
    
      - **`%json`**, **`@json`**
        
        Deserialize from pre-parsed JSON data. A hash is only making sense for a JSON class. An array can be fed to both JSON class and JSON sequence; each will treat it differently.
    
      - `JSON::Class::Config:D` **`:$config`**, **`:%config`**
        
        Either a configuration object or a profile hash which will be used to create one.
    
      - `Bool` **`:$allow-jsonc`**, `Bool` **`:$enums-as-value`**
        
        Same as [`JSON::Fast`](https://raku.land/cpan:TIMOTIMO/JSON::Fast) `from-json` arguments.

  - **`method json-serialize(JSON::Class::Config :$config)`**
    
    Implements the actual serialization task.

  - **`method json-deserialize($from, JSON::Class::Config:D :$config)`**
    
    Implements the actual deserialization task. `$from` can be a hash or an array. JSON sequences only accept arrays.

  - **`proto method json-serialize-value(|)`**
    
    Produce a value that can be immediately serialized by the underlying JSON module (think [`JSON::Fast`](https://raku.land/?q=JSON::Fast)). Say, for complex objects it would produce a hash; for an [`Enumeration`](https://docs.raku.org/type/Enumeration) it would return either its symbol name, or value, depending on [`JSON::Class::Config`](docs/md/JSON/Class/Config.md) `enums-as-value` parameter.
    
    This is a low-level method also used as a fallback when other means of serialization are not possible for whatever reason.
    
      - **`multi method json-serialize-value(Mu \value, *%nameds)`**
        
        Tries to serialize any kind of `value`. Any of `%nameds` are passed down the call chain to other candidates.
    
      - **`multi method json-serialize-value(Mu \target-type, Mu \value, JSON::Class::Config :$config, *%nameds)`**
        
        There are a few candidates with two-argument signature, responsible for serializing different kinds of `target-type`. These are somewhat specialized to serve `JSON::Class` internals. Yet, it is possible to introduce own candidates in a subclass if necessary.
        
        Some candidates are using the `$config` named argument. Any unknown arguments are passed down the call chain to other candidates.

  - **`proto method json-deserialize-value(Mu \dest-type, Mu \json-value, JSON::Class::Config :$config)`**
    
    This is a low-level method to produce a `dest-type` object from a `json-value` which is one of [a JSON data type](https://en.wikipedia.org/wiki/JSON#Data_types), returned by `from-json` routine.

  - **`method json-create(|)`**
    
    This method acts almost like `new`, but the difference is in what class it eventually creates. If it belongs to a run-time JSONified class, i.e. to one created by [`JSON::Class::Config`](docs/md/JSON/Class/Config.md) `jsonify` method, then `json-create` would return an instance of the original class, not its JSONification.
    
    Normally one doesn't need to use this method. But if it comes down to manually instantiating JSON classes then it would be preferred over the standard constructor.

  - **`method clone-from(Mu $obj, *%twiddles)`**
    
    This method allows to create an instance of its class using attribute values of `$obj`. The point is that it makes it possible to have a copy of type different from that of `$obj`. `JSON::Class` uses it to JSONify instances of non-JSON classes, for example.
    
    *Note* that this is one of few methods whose names don't start with `json-` prefix.

  - **`method json-all-set()`**
    
    Returns *True* if all postponed JSON data have been lazily deserialized.

  - **`method json-config-class()`**
    
    Returns the default configuration class type object. Overridable.

  - **`method json-config()`**
    
    Get the currently active configuration object if invoked within an active configuration context. Otherwise creates a new configuration context using class' defaults and returns its config.

  - **`method json-config-context(&code, :$config, *%twiddles)`**
    
    Creates a new configuration context by pulling in defaults for the config from various sources. Invokes user `&code` with `$*JSON-CLASS-CONFIG` context variable set with a configuration object. [`JSON::Class::Details`](docs/md/JSON/Class/Details.md) has some more information on how configuration context gets built.

# SEE ALSO

  - [`JSON::Class::Details`](docs/md/JSON/Class/Details.md)

  - [`JSON::Class::Config`](docs/md/JSON/Class/Config.md)

  - [`JSON::Class::Descriptor`](docs/md/JSON/Class/Descriptor.md)

  - [`JSON::Class::Object`](docs/md/JSON/Class/Object.md)

  - [`JSON::Class::Dict`](docs/md/JSON/Class/Dict.md)

  - [`JSON::Class::Sequence`](docs/md/JSON/Class/Sequence.md)

  - [`JSON::Class::Types`](docs/md/JSON/Class/Types.md)

  - [`Changes`](ChangeLog.md)

  - [`INDEX`](INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](LICENSE) file in this distributio
