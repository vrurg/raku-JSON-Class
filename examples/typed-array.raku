use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Rec {
    has Str:D $.description is required;
}

class Struct is json(:implicit) {
    has Array:D[Real:D] @.matrix is json(:predicate);
    has Rec:D %.rec is json(:name<records>, :predicate);
}

my $struct =
    Struct.new:
        matrix => [
            [1, 2],
            [pi, e],
            [42.12, 13.666, 4321],
        ],
        rec => {
            R1 => Rec.new(:description("test description")),
            R2 => Rec.new(:description("test description 2")),
        };

say "=== Serializing ===";
say $struct.to-json(:pretty, :sorted-keys);

say "=== Deserializing ===";
my $deserialized =
    Struct.from-json:
        q<{"matrix":[[3,4,5],[3.141592653589793e0,2.718281828459045e0],[42.0,32.16,99]],
           "records":{"R1":{"description":"for the first"},"R2":{"description":"for the second"}}}>;

say "Has .matrix: ", $deserialized.json-has-matrix;
say "Has .rec   : ", $deserialized.json-has-records; # JSON key name is used for method name
say "Matrix     : ", $deserialized.matrix;
say "Has .matrix: ", $deserialized.json-has-matrix;
say "Has .rec   : ", $deserialized.json-has-records;
say "Records    : ", $deserialized.rec;
say "Has .matrix: ", $deserialized.json-has-matrix;
say "Has .rec   : ", $deserialized.json-has-records;