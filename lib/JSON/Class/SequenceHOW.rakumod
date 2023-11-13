use v6.e.PREVIEW;
unit role JSON::Class::SequenceHOW:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::HOW::Collection::Class;
use JSON::Class::HOW::Configurable;
use JSON::Class::HOW::Laziness;
use JSON::Class::HOW::RoleContainer;
use JSON::Class::HOW::SelfConfigure;
use JSON::Class::HOW::Sequential;
use JSON::Class::ItemDescriptor;
use JSON::Class::Jsonish;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;
use JSON::Class::X;

also does JSON::Class::HOW::Collection::Class;
also does JSON::Class::HOW::Configurable;
also does JSON::Class::HOW::Laziness;
also does JSON::Class::HOW::Sequential;
also does JSON::Class::HOW::SelfConfigure;
also does JSON::Class::HOW::RoleContainer;

has $!json-array-type;

method compose(Mu --> Mu) is raw {
    my Mu \obj = callsame();
    obj.^json-init-sequence;
    obj
}

method json-init-sequence(|c) {
    $!json-array-type := NOT-SET;
    self.json-setup-sequence(|c)
}

method json-build-collection-type(Mu, @descriptors) {
    $!json-array-type := Array.^parameterize(self.json-build-collection-subset(@descriptors, 'sequence'));
}

method json-array-type(Mu \obj) {
    self.json-build-from-mro(obj);
    $!json-array-type
}

method json-kind { 'sequence' }