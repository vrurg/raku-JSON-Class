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

class JDict
    is json(
        :dictionary( Str:D, Item1:D, Item2:D, :default("<not there>") ) )
{
    method json-deserialize-item(Mu \key, |) {
        say "... deserializing key '", key, "'";
        nextsame
    }
}

#my $jdict = JDict.new;
my %jdict is JDict =
    "plain" => "string",
    "i1" => Item1.new(:id<AB12-EFZK>, :quantity(2));

%jdict.push: "i2" => Item2.new(:section<D>, :chapter("66.6"));

say "--- Initial        : ", %jdict.to-json;
say "--- Delete i1      : ", %jdict<i1>:delete;
say "--- Default is     : ", %jdict<this-never-been-here>;
say "--- JSON without i1: ", %jdict.to-json;

my $deserialized =
    JDict.from-json(
        q<{"sval":"some string","entry1":{"id":"FROM-JSON","quantity":0},"in":{"section":"DS","chapter":"43.2.1"}}>);

for $deserialized.keys -> $key {
    say "\n--- Key '$key' ---";
    say "Deserialized before accessing? ", $deserialized{$key}:has;
    say "Value: ", $deserialized{$key};
    say "Deserialized after accessing? ", $deserialized{$key}:has;
}