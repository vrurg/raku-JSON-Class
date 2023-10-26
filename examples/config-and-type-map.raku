use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;
use JSON::Class::Config:auth<zef:vrurg>;

#?example start
# To set global defaults .global to be invoked as early as possible or otherwise the global config can be vivified
# somewhere else with standard defaults.
JSON::Class::Config.global: :pretty, :sorted-keys, :!skip-null;

class Record is json {
    has Int $.count;
    has Str $.what;
}

class Status {
    has Str $.code;
    has Bool $.verified;
    has Str $.notes;
}

# Indicate that this class wants to replace Record whenever possible.
class RecWrapper is json-wrap(Record) {
    has Bool $.available is mooish(:lazy);

    method build-available {
        $.count > 0;
    }
}

class StatusTools is Status {
    # Just a mockup of what could be used for accessing some API, for example.
    method update-record {
        "will-update" => $.code
    }
}

JSON::Class::Config.map-types: RecWrapper, (Status) => StatusTools;

class Foo is json {
    has Record:D $.record is required is json(:name<rec>);
    has Status:D $.status is required is json(:name<st>);
}

say "--- Using global config with type maps";
my $foo =
    Foo.from-json:
        q<{"rec":{"count":0,"what":"irrelevant"},"st":{"code":"1A-CD3","verified":false,"notes":"to be done"}}>;

say ".record attribute type: ", $foo.record.^name;
say ".status attribute type: ", $foo.status.^name;

$foo.status.update-record;

say "Serialization of mapped types:\n", $foo.to-json.indent(2);

say "--- Using custom config with no type maps";
my $config = JSON::Class::Config.new;

$foo = Foo.from-json:
            q<{"rec":{"count":0,"what":"irrelevant"},"st":{"code":"1A-CD3","verified":false,"notes":"to be done"}}>,
            :$config;

say ".record attribute type: ", $foo.record.^name;
say ".status attribute type: ", $foo.status.^name;

try { $foo.status.update-record };
say "We expect an exception here: ", $!.^name;
say "Exception message: ", $!.message;

say "Serialization with custom config using standard defaults:\n", $foo.to-json(:$config).indent(2);