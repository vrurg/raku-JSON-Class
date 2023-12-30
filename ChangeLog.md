# CHANGELOG

  - **v0.0.5**
    
      - Support for marshalling of undefined `DateTime` and `Version` values with `:using-defaults`
    
      - Support for attribute clearers
    
      - Allow the use of custom predicate name
    
      - No predicate helper method installed unless `:predicate` attribute trait argument is used
    
      - Implement support for mixins
    
      - Support for `:config` argument of `is json` trait to define any default configuration value for typeobject
    
      - When type-mapping a nominalizable don't construct a new type if there are no mappings for its nominals
    
      - Clarify deserialization of coercive types
    
      - Make attributes with initializers non-lazy by default
    
      - Fix config derivation from upstream configuration
    
      - Fix marshalling of non-string hash key types
    
      - Fix method `clone` of [`JSON::Class::Object`](docs/md/JSON/Class/Object.md) not actually returning the clone
    
      - Fix deserialization of nominalizable positionals and associatives

  - **v0.0.4**
    
      - Implement support for generic instantiations
        
        For example, the following is now supported:
        
        ``` raku
        role R[::ValT, ::KeyT] is json {
            my class JDict is json(:dict(default => ValT, ValT, :keyof(KeyT))) {}
            has %.items is JDict;
        }
        class Rec does R[Int:D, Str:D()] {}
        ```
        
        This change requires Rakudo compiler builds starting with [the commit 28ebb7ac0f5057c1a836f6bdda15fdcf76eedfd9](https://github.com/rakudo/rakudo/commit/28ebb7ac0f5057c1a836f6bdda15fdcf76eedfd9), or starting v2023.12 releasem, when it's available.
    
      - Implemented lazy attribute build with `:build` adverb of `is json` trait for attributes; see [*examples/lazy-build.raku*](examples/lazy-build.raku)
    
      - Don't mark type-declarator as *explicit* if attribute's `is json` declaration only uses `:skip` and `:build` adverbs. *Note* that using the trait without any adverb is still de-implicifying.
    
      - Added support for coercions as dictionary or sequences value types
    
      - Type mapping now works with nominalizables
    
      - Fix incorrect `.elems` on a fully deserialized dictionary
    
      - Fix `JSON::Class::X::ReMooify` exception when used with uncomposed yet types
    
      - Fix some issues with serializing enumerations
    
      - Fix some issues with deserializing parameterized positionals and associatives
    
      - Work around a bug where use of an iterable type object as a hash key triggers a bug deep in Rakudo CORE
    
      - Fix deserialization of typed (parameterized) positionals and associatives
    
      - Fixed [`Rat`](https://docs.raku.org/type/Rat) not considered as a basic type
    
      - Fixed mixins into a JSONified class
    
      - Some more under the hood fixes

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
