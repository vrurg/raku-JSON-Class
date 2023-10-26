use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;
use JSON::Class::Config:auth<zef:vrurg>;

#?example start
class Record is json {
    has Str $.description is json( :serializer({ "pfx:" ~ $_ }),    # :to-json alias can be used instead
                                   :deserializer({ .substr(4) }) ); # :from-json can be used instead
}

class Article is json {
    has Str $.title;

    method serialize {
        %{ "-ttl-" => $!title }
    }
    method deserialize(%p) {
        die "bad profile" unless %p<-ttl->;
        self.new: title => %p<-ttl->;
    }
}

class Foo is json {
    has Record:D $.rec is required;
    has Article:D $.article is required;
}

my $config = JSON::Class::Config.new(:pretty, :sorted-keys);
$config.set-helpers: Article, serializer => 'serialize', deserializer => 'deserialize';

my $foo = Foo.new:
            rec => Record.new(:description("means nothing")),
            article => Article.new(:title("The Deep Thought: Complexity Of The Answer"));

say "Custom serializers affect JSON:\n", $foo.to-json(:$config).indent(2);
# "article" key is affected, but "rec" is using attribute's marshallizers.
say "Serializing with default config:\n", $foo.to-json(:pretty, :sorted-keys).indent(2);

$foo = Foo.from-json:
        q<{"rec":{"description":"pfx:stuff"},"article":{"-ttl-":"The Deep Thought: Gimme A Bit More Time"}}>,
        :$config;

say "Custom deserializers handle 'weird' JSON:\n", $foo.raku.indent(2);