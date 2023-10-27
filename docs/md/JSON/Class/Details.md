rakudoc
=======

DETAILS
=======

This document tries to explain some in-depth implementation details for better understanding the internal kitchen of the module. How much information is provided here depends on how much spare time and free energy the author has for this paper.

Marshalling Protocols
---------------------

`JSON::Class` doesn't actually create or read JSON itself. This task is offloaded to a 3rd-party module. For now it is [`JSON::Fast`](https://modules.raku.org/dist/JSON::Fast), but theoretically it could be any other module.

`JSON::Class` task is to either deal with whatever is returned by a JSON parser, or supply JSON generator with a serializable data structure like [`Hash`](https://docs.raku.org/type/Hash), or [`Array`](https://docs.raku.org/type/Array). The structure must represent the entire object we're about to marshall.

There are four key method in the core of the process:

  * **`from-json`**

    Takes either a JSON string, or a deserialized array, or a hash. If all passes good then either an instance of its class (or a subclass) would be returned, or an array of instances. Arrays could even be nested, depending on the original JSON structure.

  * **`to-json`**

    Can only be invoked on an instance of its class. If no errors happen during serialization, a JSON string is returned. Though is given `:raw` named argument the method would return just a [`Hash`](https://docs.raku.org/type/Hash).

  * **`json-serialize`**, **`json-deserialize`**

    These two methods are the immediate marshalling executors. They only deal with de-/serialized data structures.

The difference in functionality between these methods is that `from-json` and `to-json` are "administrators": their primary task is to prepare configuration context (see the next section). Then, depending on arguments, they either parse JSON source, or produce a JSON string. Otherwise they delegate to `json-serizlie` or `json-deserialize` methods.

Object Architechture
--------------------

A JSONified class or sequence are built by `is json` trait injecting corresponding roles into the classes themselves and into their meta-classes.

JSON classes get [`JSON::Class::Representation`](Representation.md) role, and their meta gets [`JSON::Class::ClassHOW`](ClassHOW.md).

JSON sequences get [`JSON::Class::Sequential`](Sequential.md), and their meta gets [`JSON::Class::SequenceHOW`](SequenceHOW.md).

JSON roles doesn't actually implement any functionality by themselves, therefore only their meta objects are modified. If a role declared as sequence the meta received [`JSON::Class::HOW::Sequential`](HOW/Sequential.md); otherwise it is [`JSON::Class::RoleHOW`](RoleHOW.md).

Declarations of [`JSON::Class::Representation`](Representation.md) and [`JSON::Class::Sequential`](Sequential.md) roles include classes [`JSON::Class::Object`](Object.md) and [`JSON::Class::Sequence`](Sequence.md) as their parents. Though such structure could look like an overkill at first, it allows a JSONified type to be subclasses with no extra hassle because access to the most used metaobject interfaces is proxied by the roles where `::?CLASS` symbol points at the JSONified type, no matter what the MRO of an object is. For example:

```raku
class Foo is json {...}
class Bar is Foo {...}
say Bar.json-class; # (Foo) – the method is implemented by JSON::Class::Representation
```

Configuration Context
---------------------

Serialization and deserialization protocols use a configuration object to find out about various paramters, affecting the process. More detailed description of the parameters can be found in [`JSON::Class::Config`](Class/Config.md) documentation. Here we only focus on how configuration object is handled by `JSON::Class`.

When `to-json` or `from-json` methods are invoked for an instance of JSONified class they create a configuration context by setting a `$*JSON-CLASS-CONFIG` dynamic variable to an instance of `JSON::Class::Config`. In most simple cases the instance would be unmodified global, or `$*JSON-CLASS-CONFIG`, or user-supplied config object as in the following example:

```raku
my $config = JSON::Class::Config.new;
$obj.to-json(:$config);
```

The `:config` named argument can be a hash of configuration paramters too:

```raku
$obj.to-json(config => { :pretty, :sorted-keys, :enums-as-value });
```

This this case this is equivalient to:

```raku
my $config = JSON::Class::Config.new: :pretty, :sorted-keys, :enums-as-value;
$obj.to-json(:$config);
```

Yet, the context configuration parameters can be modified with:

  * Method named arguments `:pretty`, `:sorted-keys`, `:enums-as-value`, `:spacing` - these have the highest priority

  * Class default config paramters (see an example above), but these are only have any effect if there is no active configuration context; i.e. `$*JSON-CLASS-CONFIG` doesn't exists

What We Operate With
--------------------

The module internally never deals with JSON sources except when submitting them to a parser ([`JSON::Fast`](https://raku.land/cpan:TIMOTIMO/JSON::Fast)) or returning the result of `to-json` routine of the module. `JSON::Class` manipulates with hashes, arrays, or [`Cool`](https://docs.raku.org/type/Cool) values. This is important to remember when reading the following sections.

Custom Marshallers
------------------

The following example is, perhaps, the best demonstration of how marshalling works

  * From [examples/custom-hash-marshaller.raku](../../../../examples/custom-hash-marshaller.raku)

    ```raku
    class Foo is json {
        has %.idx is json(
            :to-json(
                -> %v { say "Attribute-level serializes: ", %v; json-I-cant },
                key => { say "Key-level serializes  : ", $^key; "Foo." ~ $key },
                value => "raku",
                # value => { say "Value-level serializes: ", $^value.raku; $value.raku }
            ),
            :from-json(
                -> %from { say "Attribute-level deserializes: ", %from; json-I-cant },
                key => { say "Key-level deserializes  : '", $^from-key, "'"; $from-key.substr(1) },
                value => { say "Value-level deserializes: '", $^from-value, "'"; $from-value.EVAL }
            )
        );
    }

    my $foo =
        Foo.new:
            idx => %(
                "k1" => Date.new("2023-10-23"),
                "k2" => pi,
                "k3" => v3.4,
            );

    say "### Serializing ###";
    my $json = $foo.to-json(:sorted-keys);
    say $json;

    say "\n### Deserializing ###";
    say Foo.from-json($json);
    ```

    Sample output:

        ### Serializing ###
        Attribute-level serializes: {k1 => 2023-10-23, k2 => 3.141592653589793, k3 => v3.4}
        Key-level serializes  : k3
        Key-level serializes  : k2
        Key-level serializes  : k1
        {"idx":{"Foo.k1":"Date.new(2023,10,23)","Foo.k2":"3.141592653589793e0","Foo.k3":"v3.4"}}

        ### Deserializing ###
        Attribute-level deserializes: {Foo.k1 => Date.new(2023,10,23), Foo.k2 => 3.141592653589793e0, Foo.k3 => v3.4}
        Key-level deserializes  : 'Foo.k1'
        Value-level deserializes: 'Date.new(2023,10,23)'
        Key-level deserializes  : 'Foo.k2'
        Value-level deserializes: '3.141592653589793e0'
        Key-level deserializes  : 'Foo.k3'
        Value-level deserializes: 'v3.4'
        Foo.new(idx => ${"oo.k1" => Date.new(2023,10,23), "oo.k2" => 3.141592653589793e0, "oo.k3" => v3.4})

We see here default marshallers for the attribute itself and marshallers for keys and values. The default marshallers are using `json-I-cant` to fallback to key/value ones because otherwise these wouldn't be invoked.

### Marshalling By Method Name

In the above example `value` serializer is set to *"raku"* string which is treated as a method name. There are different expectation as to where the method name is looked up for. The right one would be: on the value being serialized. This is because attribute's `is json` trait all about the attribute itself or its value.

Another possibly confusing at first details is about deserializing with a method name. If you pay attention to the value deserializer in the above example, it doesn't use `EVAL` as method name but invokes it directly instead. This is because the deserializer method is lookup upon target value type. In the above case it is [`Mu`](https://docs.raku.org/type/Mu) as the default constraint type of hash values and it doesn't implement `EVAL`. But even if we declare `%.idx` as `has Str %.idx`, `EVAL` as method name won't work for us because deserializing method is expected to receive the source JSON value is its only positional argument.

### Marshalling With JSON Class Methods

Ok, but what if we want to marshall using JSON class owns methods? It can be done using `$*JSON-CLASS-SELF` variable.

  * From [examples/marshall-via-json-class.raku](../../../../examples/marshall-via-json-class.raku)

    ```raku
    class Foo is json(:skip-null) {
        has Real $.n
            is json(
                :serializer({ $*JSON-CLASS-SELF.n2s($_) }),
                :deserializer({ $*JSON-CLASS-SELF.s2n($_) }) );

        multi method new(Real $n) { self.bless: :$n }

        proto method n2s(|) {*}
        multi method n2s(Real:U \t) { t.^name }
        multi method n2s(Real:D \n) { n.^name ~ ":" ~ n }

        method s2n(Str:D $from) {
            if $from.contains(":") {
                my ($type, $val) = $from.split(":");
                return $val."$type"()
            }
            ::($from)
        }
    }

    say "Serializing π  : ", Foo.new(pi).to-json;
    say "Serializing Num: ", Foo.new(Num).to-json;
    say "";
    say "Deserializing a Rat: ", Foo.from-json(q<{"n":"Rat:-12.42"}>).n.WHICH;
    say "Deserializing a type: ", Foo.from-json(q<{"n":"Int"}>).n.WHICH;
    ```

    Sample output:

        Serializing π  : {"n":"Num:3.141592653589793"}
        Serializing Num: {"n":"Num"}

        Deserializing a Rat: Rat|-621/50
        Deserializing a type: Int|U2274472627536

### Marshaller Signature Match

When `JSON::Class` verifies if a marshaller can be used it tries to match its signature against the value it has, where *value* can be attribute value for serialization, and JSON value for deserialization. It does so by using `cando` method of [`Routine`](https://docs.raku.org/type/Routine). Apparently, when there is match the code gets invoked. Otherwise the situation is treated as if the marshaller invoked `json-I-cant` and gave up on processing the value:

  * From [examples/marshaller-signature-match.raku](../../../../examples/marshaller-signature-match.raku)

    ```raku
    class Foo is json {
        has Real:D $.foo is json(:serializer(-> Int:D \v { say "serializing ", v.WHICH; v.Rat })) is required;
    }

    say Foo.new(foo => 12).to-json;
    say Foo.new(foo => 1.2).to-json;
    ```

    Sample output:

        serializing Int|12
        {"foo":12.0}
        {"foo":1.2}

Type Mapping
------------

`JSON::Class` supports deserialization type mapping which allows user code to override 3rd-party standard types with their own classes.

For example, let's say there is an API module for a web-service which de-JSONifies a REST response into an instance of `Web::Service::Response`. The raw response object is barely useful for us and we decide to subclass it with `MyProject::Response` which extends the original class functionality for our needs. Now it all winds down to rather simple code if the `Web::Service` module is using `JSON::Class`:

```raku
JSON::Class::Config().map-type(Web::Service::Response(), MyProject::Response());
my $web-service = Web::Service().new();
await($web-service.request().andthen({
    say(.response().^name())
}))
```

That's all folks! Committing away the first line of the example will result in *Web::Service::Response* output again.

A well-behaving `Web::Service` module would allow to submit a custom [`JSON::Class::Config`](Config.md) object, but the global one will do too...

... unless the `Web::Service` creates and uses its own config, but that's an ethical problem beyond this documentation area of responsibility!

For the sake of declarative syntax, there is `is json-wrap` trait which allows to declare a sub-class as a replacement:

```raku
class MyProject::Response is json-wrap(Web::Service::Response) {
    ...
}
```

The trait doesn't install the mapping automatically though. This might be undesirable. One would still need a call like this to activate it:

```raku
$config.map-type(MyProject::Response())
```

Descriptors
-----------

`JSON::Class` avoids modifying attribute objects of meta-object of a class. Instead, it creates a registry of them where the information about the ways of JSONifying their values is kept. The details of registry implementation are irrelevant, all we need to know is that it holds instances of *descriptors*. There are two kinds of descriptors:

  * *attribute descriptors* for attributes of a JSON class

  * *item descriptors* for items of a JSON sequence

Each JSONified type obejct has its own registry. When a new JSON class or sequence is built registries from parent classes or JSON roles consumed are merged to form the full picture of what's to be marshalled.

SEE ALSO
========

  * [`JSON::Class`](../Class.md)

COPYRIGHT
=========

(c) 2023, Vadim Belman <vrurg@cpan.org>

LICENSE
=======

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.

