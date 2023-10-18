use v6.e.PREVIEW;
unit role JSON::Class::HOW::Configurable:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

has $!config-defaults;

method json-has-config-defaults { ? $!config-defaults }

method json-config-defaults(Mu \obj) is raw { $!config-defaults // %() }

method json-configure-defaults(Mu \obj, *%options) {
    my @defaults = %options.grep(*.value.defined);
    if @defaults {
        $!config-defaults //= Hash.new;
        $!config-defaults{.key} = .value for @defaults;
    }
}