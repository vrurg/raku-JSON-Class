use v6.e.PREVIEW;
# For sequential roles where ther functionality is only to define sequence items.
unit role JSON::Class::HOW::Sequential:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::HOW::Collection;
use JSON::Class::HOW::Collection::DefParser;
use JSON::Class::Types :NOT-SET;
use JSON::Class::Utils;

also does JSON::Class::HOW::Collection;

my class DefParser does JSON::Class::HOW::Collection::DefParser['sequence'] {}

method json-setup-sequence(Mu \obj) {
    self.json-set-item-default(obj, NOT-SET, :force);

    my $def-parser = DefParser.new(json-type => obj);
    my $trait-name = $*JSON-CLASS-TRAIT // self.json-trait-name(obj);
    {
        my $*JSON-CLASS-TRAIT := $trait-name;
        for self.json-item-declarations(:clear) {
            $def-parser.parse-trait-def($_);
        }
    }

    self.json-set-item-default(obj, nominalize-type( self.json-item-descriptors(obj).head.type ));
}
