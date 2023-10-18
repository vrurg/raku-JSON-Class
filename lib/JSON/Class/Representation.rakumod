use v6.e.PREVIEW;
unit role JSON::Class::Representation:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Object;

also is JSON::Class::Object;

method json-class { ::?CLASS }
method json-config-defaults is raw { ::?CLASS.^json-config-defaults }