use v6.e.PREVIEW;
unit role JSON::Class::SequenceHOW:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::HOW::Configurable;
use JSON::Class::HOW::Laziness;
use JSON::Class::HOW::Sequential;
use JSON::Class::HOW::SelfConfigure;
use JSON::Class::ItemDescriptor;
use JSON::Class::Jsonish;
use JSON::Class::Utils;
use JSON::Class::Types :NOT-SET;
use JSON::Class::X;

also does JSON::Class::HOW::Configurable;
also does JSON::Class::HOW::Laziness;
also does JSON::Class::HOW::Sequential;
also does JSON::Class::HOW::SelfConfigure;

has $!json-array-type;

method json-init-sequence(Mu) {
    $!json-array-type := NOT-SET;
}

method json-build-collection-type(Mu, @descriptors) {
    $!json-array-type := Array.^parameterize(self.json-build-collection-subset(@descriptors, 'sequence'));
}

method json-array-type(Mu \obj) {
    self.json-build-from-mro(obj);
    $!json-array-type
}