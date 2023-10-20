use v6.e.PREVIEW;
unit role JSON::Class::HOW::Explicit:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

has Bool $!json-explicit;

method json-set-explicit(Mu \obj, Bool:D $explicit) {
    $!json-explicit //= $explicit;
}

method json-is-explicit(Mu) { $!json-explicit // False }

method json-has-explicit(Mu) { $!json-explicit.defined }