use v6.e.PREVIEW;
unit role JSON::Class::DictHOW:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use experimental :will-complain;

use JSON::Class::Dictionary;
use JSON::Class::Dict;
use JSON::Class::HOW::Collection::Class;
use JSON::Class::HOW::Configurable;
use JSON::Class::HOW::Dictionary;
use JSON::Class::HOW::Instantiation;
use JSON::Class::HOW::Laziness;
use JSON::Class::HOW::RoleContainer;
use JSON::Class::HOW::SelfConfigure;
use JSON::Class::ItemDescriptor;
use JSON::Class::Jsonish;
use JSON::Class::Types :NOT-SET, :DEFAULT;
use JSON::Class::Utils;
use JSON::Class::X;

also does JSON::Class::HOW::Collection::Class;
also does JSON::Class::HOW::Configurable;
also does JSON::Class::HOW::Dictionary;
also does JSON::Class::HOW::Instantiation;
also does JSON::Class::HOW::Laziness;
also does JSON::Class::HOW::RoleContainer;
also does JSON::Class::HOW::SelfConfigure;

has $!json-hash-type is json-meta(:mixin-skip);

method compose(Mu \obj, |c --> Mu) is raw {
    unless self.is_composed(obj) {
        self.json-instantiation-prepare(obj);
        self.add_parent(obj, JSON::Class::Dict);
        self.add_role(obj, JSON::Class::Dictionary);
    }
    my \composed = callsame();
    self.json-post-compose(obj);
    composed
}

method publish_type_cache(Mu \obj) is raw {
    self.json-init-dictionary(obj);
    nextsame
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