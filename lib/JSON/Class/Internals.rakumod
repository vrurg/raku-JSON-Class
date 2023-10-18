use v6.e.PREVIEW;
unit module JSON::Class::Internals:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Attr;

sub verify-named-args(%adv?, :@unique, :%extra, Str:D :$what, Str:D :$source, Int:D :$offset = 0 --> Nil) is export {
    my @nogo = %adv{@unique}.grep({ .defined && .value }).map(":" ~ *.key);
    my @unexpected = %extra.keys.map(":" ~ *);

    if @nogo > 1 || @unexpected {
        X::Adverb.new( :@nogo, :@unexpected, :$what, :$source ).throw(Backtrace($offset + 2))
    }
}