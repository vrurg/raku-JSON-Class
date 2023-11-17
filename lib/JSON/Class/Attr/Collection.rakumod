use v6.e.PREVIEW;
unit role JSON::Class::Attr::Collection:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use AttrX::Mooish;

use JSON::Class::Jsonish;
use JSON::Class::Utils;

has Bool:D $.jsonish is mooish(:lazy);

method type {...}

method build-jsonish { ? (self.type ~~ JSON::Class::Jsonish) }