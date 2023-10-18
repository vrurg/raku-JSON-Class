use v6.e.PREVIEW;
unit role JSON::Class::HOW::Laziness:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

# Will we use lazy instantiation?
has Bool $!json-lazy;

method json-set-lazy(Mu \obj, Bool:D $lazy) {
    $!json-lazy //= $lazy;
}

method json-is-lazy(Mu \obj) { $!json-lazy }