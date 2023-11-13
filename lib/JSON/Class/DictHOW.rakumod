use v6.e.PREVIEW;
unit role JSON::Class::DictHOW:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use experimental :will-complain;

use JSON::Class::HOW::Collection::Class;
use JSON::Class::HOW::Configurable;
use JSON::Class::HOW::Dictionary;
use JSON::Class::HOW::Laziness;
use JSON::Class::HOW::RoleContainer;
use JSON::Class::HOW::SelfConfigure;
use JSON::Class::ItemDescriptor;
use JSON::Class::Jsonish;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;
use JSON::Class::X;

also does JSON::Class::HOW::Collection::Class;
also does JSON::Class::HOW::Configurable;
also does JSON::Class::HOW::RoleContainer;
also does JSON::Class::HOW::Laziness;
also does JSON::Class::HOW::Dictionary;
also does JSON::Class::HOW::SelfConfigure;

has $!json-hash-type;

method compose(Mu --> Mu) is raw {
    my Mu \obj = callsame();
    obj.^json-init-dictionary;
    obj
}

method json-init-dictionary(|c) {
    $!json-hash-type := NOT-SET;
    self.json-setup-dictionary(|c)
}

method json-build-collection-type(Mu \obj, @descriptors) {
    $!json-hash-type := Hash.^parameterize: self.json-build-collection-subset(@descriptors, 'dict'), Str:D;
}

method json-hash-type(Mu \obj) {
    self.json-build-from-mro(obj);
    $!json-hash-type
}

method json-kind { 'dictionary' }