use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
role R is json {
    has Bool $.flag;
}

class C1 does R is json {
    has Int $.count;
}

class C2 is json is C1 {
    has Str $.what;
}

my $obj = C2.new(:count(3), :what("whatever you like"), :flag);
say $obj.to-json(:pretty, :sorted-keys);