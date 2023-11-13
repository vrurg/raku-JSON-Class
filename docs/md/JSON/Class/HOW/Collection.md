# rakudoc

# NAME

`JSON::Class::Collection` - base role for metas implementing collections

# METHODS

  - **`method json-set-item-default(Mu \item-default)`**
    
    Set collection default value.

  - **`method json-item-default(Mu \obj)`**
    
    Returns collection default value.

  - **`method json-item-descriptors(Mu \obj, Bool :$local, Bool :$class, Bool :$with-matcher)`**
    
    Return a list of collection's value descriptors. Arguments are:
    
      - `Bool` **`:$local`**
        
        Only descriptors immediately declared on the collection type.
    
      - `Bool` **`:$class`**
        
        Only descriptors where type is a non-basic type class.
    
      - `Bool` **`:$with-matcher`**
        
        Only descriptors with matcher helper.

# SEE ALSO

  - [`JSON::Class`](../../Class.md)

  - [`JSON::Class::HOW::Dictionary`](Dictionary.md)

  - [`JSON::Class::HOW::Sequential`](Sequential.md)

  - [`JSON::Class::Details`](../Details.md)

  - [`INDEX`](../../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
