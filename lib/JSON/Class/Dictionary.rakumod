use v6.e.PREVIEW;
unit role JSON::Class::Dictionary:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use nqp;

use JSON::Class::Types :NOT-SET;
use JSON::Class::Dict;

also is JSON::Class::Dict;

method json-class is raw is pure { ::?CLASS }
method json-config-defaults is raw { ::?CLASS.^json-config-defaults }
method json-dictionary-type is raw { ::?CLASS.^json-hash-type }
method json-key-descriptor is raw { ::?CLASS.^json-key-descriptor }
method keyof is raw { ::?CLASS.^json-keyof }
method of is raw { ::?CLASS.^json-hash-type.of }

method json-new-dict-hash(--> Hash:D) is raw {
    my %dict := ::?CLASS.^json-hash-type.new;

    # Now we need to setup a container descriptor with name because by default a parameterized Hash use no name causing
    # unclear type check error messages. This could be done with Metamodel, but nqp is faster because we delegate the
    # work of locating attributes to the backend.
    my \item-default = $_ =:= NOT-SET ?? %dict.of !! $_ given ::?CLASS.^json-item-default;
    nqp::bindattr(
        %dict, Hash, '$!descriptor',
        my \desc = ContainerDescriptor.new( :name('item value of (' ~ ::?CLASS.^name ~ ')'),
                                 :of(%dict.of),
                                 :default(item-default) ));
    %dict
}

method json-new-key-hash(--> Hash:D) is raw {
    my %keys := Hash.^parameterize(::?CLASS.^json-key-descriptor.type).new;
    nqp::bindattr(
        %keys, Hash, '$!descriptor',
        ContainerDescriptor.new( :name('item key of (' ~ ::?CLASS.^name ~ ')'),
                                 :of(%keys.of),
                                 :default(Nil) ));
    %keys
}

method json-item-descriptors(|c) { ::?CLASS.^json-item-descriptors(|c) }

method json-create(*%profile) { self.new: |%profile }