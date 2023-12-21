use v6.e.PREVIEW;
unit role JSON::Class::HOW::Configurable:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

has $!json-config-defaults;

method json-has-config-defaults { ? $!json-config-defaults }

method json-config-defaults(Mu \obj) is raw { $!json-config-defaults // %() }

method json-configure-defaults(Mu \obj, *%options) {
    my @defaults = %options.grep(*.value.defined);
    if @defaults {
        $!json-config-defaults //= Hash.new;
        $!json-config-defaults{.key} = .value for @defaults;
    }
}