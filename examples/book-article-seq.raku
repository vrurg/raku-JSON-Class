use v6.e.PREVIEW;
use JSON::Class:auth<zef:vrurg>;

#?example start
class Book {
    has Str:D $.id is required;
    has Str:D $.name is required;
}
class Article {
    has Str:D $.id is required;
    has Str:D $.name is required;

    method is-an-article(%from) {
        ? (%from<id> ~~ /^ \d ** 4 '-' \d ** 2 '-' \d ** 2 ':'/)
    }
}

sub is-a-book(%from) { %from<id>.starts-with("ISBN:") }

class BoxOfPapers is json(:sequence( (Book, :matcher(&is-a-book)), (Article, :matcher<is-an-article>) )) {}

my $json = q:to/JSON/;
[
    {"id": "ISBN:1234", "name": "The Guide"},
    {"id": "2006-04-01:the-pop-one", "name":"What's the programmer's most popular book out there?"}
]
JSON

my $box = BoxOfPapers.from-json($json);
say $box.map(*.gist).join("\n");