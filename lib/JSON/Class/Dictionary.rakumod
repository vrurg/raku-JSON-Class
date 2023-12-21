use v6.e.PREVIEW;
unit role JSON::Class::Dictionary:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use nqp;

use JSON::Class::HOW::Jsonish;
use JSON::Class::Types :NOT-SET;

my Mu $JSON-CLASS = ::?CLASS;

submethod JSON-POSTCOMPOSE {
    # See JSON::Class::Representation
    $JSON-CLASS := self.^mro.first({ .HOW ~~ JSON::Class::HOW::Jsonish });
}

method json-class is raw is pure { $JSON-CLASS }
method json-config-defaults is raw { $JSON-CLASS.^json-config-defaults }
method json-dictionary-type is raw { $JSON-CLASS.^json-hash-type }
method json-key-descriptor is raw { $JSON-CLASS.^json-key-descriptor }
method keyof is raw { $JSON-CLASS.^json-keyof }
method of is raw { $JSON-CLASS.^json-hash-type.of }

method json-new-dict-hash(--> Hash:D) is raw {
    my %dict := $JSON-CLASS.^json-hash-type.new;

    # Now we need to setup a container descriptor with name because by default a parameterized Hash use no name causing
    # unclear type check error messages. This could be done with Metamodel, but nqp is faster because we delegate the
    # work of locating attributes to the backend.
    my \item-default = $_ =:= NOT-SET ?? %dict.of !! $_ given $JSON-CLASS.^json-item-default;
    nqp::bindattr(
        %dict, Hash, '$!descriptor',
        my \desc = ContainerDescriptor.new( :name('item value of (' ~ ::?CLASS.^name ~ ')'),
                                 :of(%dict.of),
                                 :default(item-default) ));
    %dict
}

method json-new-key-hash(--> Hash:D) is raw {
    my %keys := Hash.^parameterize($JSON-CLASS.^json-key-descriptor.type).new;
    nqp::bindattr(
        %keys, Hash, '$!descriptor',
        ContainerDescriptor.new( :name('item key of (' ~ ::?CLASS.^name ~ ')'),
                                 :of(%keys.of),
                                 :default(Nil) ));
    %keys
}

method json-item-descriptors(|c) { $JSON-CLASS.^json-item-descriptors(|c) }

method json-create(*%profile) { self.new: |%profile }

method is-generic {
    # TODO Must report key descriptor too!
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
                        ?? $JSON-CLASS.^json-instantiation-new-type(:$typeenv)
                        !! $instantiation;
    ins-type.^json-instantiate-dictionary($typeenv);
    ins-type.^set_name:
        ins-type.^name ~ "["
            ~ ins-type.^json-local-item-descriptors.map(*.type.^name).join(",")
            ~ ";" ~ ins-type.^json-key-descriptor.type.^name ~ "]";
    ins-type.^compose;
    ins-type.^json-build-from-mro(:force);
    # We don't need the type environment anymore.
    ins-type.^json-clear-typeenv;
    ins-type
}

multi method INSTANTIATE-GENERIC( ::?CLASS:D:
                                  TypeEnv:D $typeenv is raw,
                                  Mu :$instantiation is raw = NOT-SET
                                  --> ::?ROLE:D )
    is raw
{
    ($instantiation // $JSON-CLASS.INSTANTIATE-GENERIC($typeenv)).STORE(self)
}