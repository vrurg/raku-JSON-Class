use v6.e.PREVIEW;
unit role JSON::Class::Jsonish:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

method from-json {...}
method to-json {...}
method json-serialize {...}
method json-deserialize {...}
method json-create {...}
method clone-from {...}

my $warnings-reported;