use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Item1 is json {
    has Str $.id;
    has Int $.quantity;
}

class Item2 is json {
    has Str $.section;
    has Str $.chapter;
}

class JSeq is json(:sequence(Str:D, Item1:D, Item2:D, :default<removed>)) {
    method json-deserialize-item($idx, \json-value) is raw {
        say "... deserializing [$idx] ...";
        nextsame
    }
}

my $jseq = JSeq.new("something", Item2.new(:section<A>, :chapter("22.1")));

$jseq.push: Item1.new(:id<EBCA-12F>, :quantity(13));
$jseq.push: "final";

say "--- Initial    : ", $jseq.to-json;
$jseq[1]:delete;
say "--- 2nd deleted: ", $jseq.to-json;
my $deserialized := JSeq.from-json: q<["something",{"quantity":12,"id":"9123-BBB"},"different",{"section":"B","chapter":"2.9b"}]>;
for ^$deserialized.elems -> $idx {
    say "--- $idx ---";
    say "Deserialized before accessing? ", $deserialized[$idx]:has;
    say "Item: ", $deserialized[$idx].raku;
    say "Deserialized after accessing? ", $deserialized[$idx]:has;
}