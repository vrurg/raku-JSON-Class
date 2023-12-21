use v6.e.PREVIEW;
unit role JSON::Class::Representation:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Object;
use JSON::Class::HOW::Jsonish;

also is JSON::Class::Object;

my Mu $JSON-CLASS := ::?CLASS;

submethod JSON-POSTCOMPOSE {
    # A mixin is created starting with a new HOW instance created off the type of the original class. In our case it
    # means the HOW would have a JSON::Class::*HOW role applied. The problem is that the resulting class by all means is
    # a JSONified one, but with all the HOW guts lost because its not a clone of the original one. Therefore we need to
    # find the first non-mixin class to retain access to all meta-data.
    # This code is repeated wherever relevant.
    $JSON-CLASS := self.^mro.first({ .HOW ~~ JSON::Class::HOW::Jsonish });
}

method json-class { $JSON-CLASS }
method json-config-defaults is raw { $JSON-CLASS.^json-config-defaults }