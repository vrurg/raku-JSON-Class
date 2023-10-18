use v6.e.PREVIEW;
unit role JSON::Class::Sequential:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);
use nqp;

use JSON::Class::Types :NOT-SET;
use JSON::Class::Sequence;

also is JSON::Class::Sequence;

method json-class is raw { ::?CLASS }
method json-config-defaults is raw { ::?CLASS.^json-config-defaults }
method json-array-type is raw { ::?CLASS.^json-array-type }

method json-new-seq-array(--> Array:D) {
    my @a := ::?CLASS.^json-array-type.new;
    # Now we need to setup a container descriptor with name because by default a typed Array use no name causing
    # unclear type check error messages. This could be done with Metamodel, but nqp is faster because we delegate
    # the work of locating attributes to the backend.
    my \item-default = $_ =:= NOT-SET ?? @a.of !! $_ given ::?CLASS.^json-item-default;
    nqp::bindattr( @a, Array, '$!descriptor',
                   ContainerDescriptor.new( :name('item of (' ~ ::?CLASS.^name ~ ')'),
                                            :of(@a.of),
                                            :default(item-default) ));
    @a
}

method json-item-descriptors(|c) { ::?CLASS.^json-item-descriptors(|c) }

method json-create(*%profile) { self.new: |%profile }