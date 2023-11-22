# CHANGELOG

  - **v0.0.4**
    
      - Implemented lazy attribute build with `:build` adverb of `is json` trait for attributes; see [*examples/lazy-build.raku*](examples/lazy-build.raku)
    
      - Don't mark type-declarator as *explicit* if attribute's `is json` declaration only uses `:skip` and `:build` adverbs. *Note* that using the trait without any adverb is still de-implicifying.
    
      - Fix incorrect `.elems` on a fully deserialized dictionary
    
      - Fix `JSON::Class::X::ReMooify` exception when used with uncomposed yet types
    
      - Fix some issues with serializing enumerations
    
      - Fix some issues with deserializing parameterized positionals and associatives

  - **v0.0.3**
    
      - Implemented [`JSON::Class::Dict`](docs/md/JSON/Class/Dict.md)
    
      - Fixed some cases where [`JSON::Class::Sequence`](docs/md/JSON/Class/Sequence.md) would not transition into "all set" state

  - **v0.0.2**
    
      - Added default marshalling for [`Version`](https://docs.raku.org/type/Version), and [`QuantHash`](https://docs.raku.org/type/QuantHash)es
    
      - Implicit JSONification now reports a problem for some problematic types

  - **v0.0.1**
    
      - First release

# SEE ALSO

  - [`README`](README.md)

  - [`INDEX`](INDEX.md)
