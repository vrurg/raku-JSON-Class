use v6.e.PREVIEW;
unit role JSON::Class::Sequential:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use nqp;

use JSON::Class::HOW::Jsonish;
use JSON::Class::Internals;
use JSON::Class::Sequence;
use JSON::Class::Types :NOT-SET;

my Mu $JSON-CLASS := ::?CLASS;

submethod JSON-POSTCOMPOSE {
    # See JSON::Class::Representation
    $JSON-CLASS := self.^mro.first({ .HOW ~~ JSON::Class::HOW::Jsonish });
}

method json-class is raw { $JSON-CLASS }
method json-config-defaults is raw { $JSON-CLASS.^json-config-defaults }
method json-array-type is raw { $JSON-CLASS.^json-array-type }

method json-new-seq-array(--> Array:D) {
    my @a := $JSON-CLASS.^json-array-type.new;
    # Now we need to setup a container descriptor with name because by default a typed Array use no name causing unclear
    # type check error messages. This could be done with Metamodel, but nqp is faster because we delegate the work of
    # locating attributes to the backend.
    my \item-default = $_ =:= NOT-SET ?? @a.of !! $_ given $JSON-CLASS.^json-item-default;
    nqp::bindattr( @a, Array, '$!descriptor',
                   ContainerDescriptor.new( :name('item of (' ~ ::?CLASS.^name ~ ')'),
                                            :of(@a.of),
                                            :default(item-default) ));
    @a
}

method json-item-descriptors(|c) { $JSON-CLASS.^json-item-descriptors(|c) }

method json-create(*%profile) { self.new: |%profile }

method is-generic {
    $JSON-CLASS.^json-is-generic
}

proto method INSTANTIATE-GENERIC(|) {*}
multi method INSTANTIATE-GENERIC( ::?CLASS:U:
                                  TypeEnv:D $typeenv is raw,
                                  Mu :$instantiation is raw = NOT-SET
                                  --> ::?ROLE:U )
    is raw
{
    my \ins-type = $instantiation === NOT-SET
                        ?? ::?CLASS.^json-instantiation-new-type(:$typeenv)
                        !! $instantiation;
    ins-type.^json-instantiate-collection($typeenv);
    ins-type.^set_name:
        ins-type.^name ~ "[" ~ ins-type.^json-local-item-descriptors.map(*.type.^name).join(",") ~ "]";
    ins-type.^compose;
    ins-type.^json-build-from-mro(:force);
    ins-type.^json-clear-typeenv;
    ins-type
}

multi method INSTANTIATE-GENERIC( ::?CLASS:D:
                                  TypeEnv:D $typeenv is raw,
                                  Mu :$instantiation is raw = NOT-SET
                                  --> ::?ROLE:D )
    is raw
{
    ($instantiation // ::?CLASS.INSTANTIATE-GENERIC($typeenv)).STORE(self)
}