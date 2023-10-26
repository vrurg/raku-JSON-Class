use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
my $skiped-serializations = 0;
my $skipped-deserializations = 0;

class Foo is json {
    has Int:D @.counts is json(
        :serializer(
            value => -> $v {
                if $v % 3 == 0 {
                    ++$skiped-serializations;
                    json-I-cant
                }
                $v * 1000
            } ),
        :deserializer(
            value => -> $v {
                if $v < 1000 {
                    ++$skipped-deserializations;
                    json-I-cant
                }
                $v div 1000
            } ));
}

my $foo = Foo.new(counts => ^22);

my $json = $foo.to-json;

say $json;
say Foo.from-json($json);
say "I skipped ", $skiped-serializations, " serializations and ", $skipped-deserializations, " deserializations";