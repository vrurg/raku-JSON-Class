use v6.e.PREVIEW;
unit module JSON::Class::X:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

use JSON::Class::Utils;

role Base is Exception {}

role Typed {
    has Mu $!type is required is built;
    method type is raw {
        $!type.HOW.^can('json-FROM') ?? $!type.^json-FROM !! $!type.WHAT
    }
}

class AdHoc does Base {
    has Str:D $.message is required;
    multi method new(Str:D $message) { self.new(:$message) }
}

class UnsupportedType does Base does Typed {
    has Str $.why;
    method message {
        "Unsupported type object '" ~ $.type.^name ~ "'" ~ ($.why andthen ": " ~ $_ orelse "")
    }
}

class Redeclaration does Base {
    has Str:D $.kind is required;
    has Str:D $.name is required;
    has Str:D $.what = "json";

    method message {
        $.kind.tclc ~ " " ~ $.name ~ " is already declared as " ~ $.what
    }
}

class NoMethod does Base does Typed {
    has Str:D $.method-name is required;
    has Str $.hint;
    method message {
        "Method '" ~ $.method-name ~ "' must be implemented by '" ~ $.type.^name ~ "'"
            ~ ($.hint andthen " " ~ $_ orelse "")
    }
}

role Trait does Base {
    has Str:D $.trait-name = $*JSON-CLASS-TRAIT;

    method !message-trait { "Trait '$.trait-name'" }
}

class Trait::NonJSONType does Trait does Typed {
    # To what the trait is applied
    has Str:D $.target is required;

    method message {
        self!message-trait ~ " cannot be used with a non-JSON type object '" ~ $.type.^name
            ~ "'; consider adding 'is json' to the type declaration"
    }
}

my class Trait::Argument does Trait {
    has Str $.why;
    has Str:D @.details;
    has Bool:D $.singular = False;
    method message {
        self!message-trait
            ~ " cannot be used with "
            ~ ($!singular ?? "this argument" !! "these arguments") ~ ":" ~ ($.why ?? " " ~ $.why !! "")
            ~ |("\n" ~ @!details.map("  - " ~ *).join("\n") if @!details)
    }
}

class NonClass does Base does Typed {
    has Str:D $.what is required;
    method message {
        "Non-class type object " ~ $.type.^name ~ " cannot be used to " ~ $.what
    }
}

role Config does Base {}

my class Config::ImmutableGlobal does Config {
    method message {
        "The global configuration object already exists and cannot be changed"
    }
}

my class Config::NonWrapperType does Config does Typed {
    method message {
        "Type object '" ~ $.type.^name ~ "' is not a wrapper, consider using 'json-wrap' trait"
    }
}

class ReMooify does Base does Typed {
    has Attribute:D $.attr is required;
    method message {
        "Don't use lazy mode with attribute "
            ~ $!attr.name ~ " of " ~ $.type.^name
            ~ " to which 'is mooish' trait is already applied"
    }
}

role Serialize does Base does Typed {}

my class Serialize::Impossible does Serialize {
    has Mu $.what is required;
    has Str:D $.why is required;
    method message {
        "Cannot serialize " ~ type-or-instance($!what) ~ " for " ~ $.type.^name ~ ": " ~ $.why
    }
}

role Deserialize does Base does Typed {}

my class Deserialize::Impossible does Deserialize {
    has Str:D $.why is required;
    method message {
        "Cannot deserialize into " ~ $.type.^name ~ ": " ~ $.why
    }
}

my class Deserialize::SeqItem does Deserialize {
    has Mu $.what is required;
    has Int:D $.idx is required;
    has Str:D $.why is required;
    method message {
        "Cannot deserialize " ~ type-or-instance($.what)
        ~ " at position " ~ $.idx
        ~ " of sequence type " ~ $.type.^name ~ ": " ~ $.why
    }
}

my class Deserialize::DictItem does Deserialize {
    has Mu $.what is required;
    has Mu $.key is required;
    has Str:D $.why is required;
    method message {
        "Cannot deserialize " ~ type-or-instance($.what)
        ~ " at key '" ~ $.key.gist ~ "'"
        ~ " of dictionary type " ~ $.type.^name ~ ": " ~ $.why
    }
}

my class Deserialize::NoAttribute does Deserialize {
    has Str:D $.json-key is required;
    method message {
        "No attribute found in '" ~ $.type.^name ~ "' for JSON key '" ~ $.json-key ~ "'"
    }
}

# my class Sequence::TypeDuplicate does Sequence {
#     has Mu $.type is required;
#     has Mu $.sequence is required;
#     method message {
#         "Duplicate definition for type ("
#             ~ $!type.^name
#             ~ ") in declaration of JSON sequence ("
#             ~ $!sequence.^name
#             ~ ")"
#     }
# }