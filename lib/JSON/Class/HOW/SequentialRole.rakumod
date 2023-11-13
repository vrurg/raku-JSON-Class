use v6.e.PREVIEW;
unit role JSON::Class::HOW::SequentialRole:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::HOW::Collection::Role;
use JSON::Class::HOW::Sequential;
use JSON::Class::SequenceHOW;
use JSON::Class::Sequential;
use JSON::Class::X;

also does JSON::Class::HOW::Collection::Role[JSON::Class::SequenceHOW, JSON::Class::Sequential];
also does JSON::Class::HOW::Sequential;

method compose(|) is raw {
    my \obj = callsame();
    self.json-setup-sequence(obj);
    obj
}

method json-kind { 'sequential role' }