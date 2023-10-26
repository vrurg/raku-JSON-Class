use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
role R1 {
    has Bool $.flag;
}

role R2 {
    has Num $.cost;
}

class C1 {
    has Int $.count;
}

class C2 {
    has Num $.total;
}

class C3 is json(:is(C1), :does(R1)) does R2 is C2 {
    has Str $.what;
}

my $obj = C3.new(:count(3), :what("whatever you like"), :flag, :cost(1.2e0), :total(1e3));
say $obj.to-json(:pretty, :sorted-keys);