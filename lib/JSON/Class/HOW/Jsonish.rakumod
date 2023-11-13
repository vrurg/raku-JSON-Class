use v6.e.PREVIEW;
unit role JSON::Class::HOW::Jsonish:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

has $!json-warnings;

method json-kind {...}

method json-add-warning(Mu \obj, \warning) {
    ($!json-warnings // ($!json-warnings := Array.new)).push: warning;
}

method json-warnings(Mu \obj, Bool :$clear) is raw {
    $!json-warnings // ()
}

method json-report-warnings(Mu, $config --> Nil) is hidden-from-backtrace {
    return without $!json-warnings;
    $config.notify(|$_) for $!json-warnings;
    $!json-warnings := Nil;
}