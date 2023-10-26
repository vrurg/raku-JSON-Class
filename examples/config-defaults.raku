use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class C1 is json(:pretty, :sorted-keys) {
    has Int $.count;
    has Str $.what;
}

class C2 is C1 is json(:!skip-null) { }

my $c1 = C1.new(:count(42), :what("The Answer"));
say "--- C1 serialization:\n", $c1.to-json;
my $c2 = C2.new(:count(42), :what("The Answer"));
say "--- C2 serialization:\n", $c2.to-json;