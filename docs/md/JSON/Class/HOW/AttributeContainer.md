# NAME

`JSON::Class::HOW::AttributeContainer` – role for meta-objects that serve as JSON attribute containers

# METHODS

  - **`method json-attrs(Mu, Bool:D :$local, Bool :$p, Bool :$k, Bool :$kv, Bool :$v)`**
    
    Returns a registry of JSON attribute descriptors.
    
      - `Bool:D` **`:$local`**`= True`
        
        Only attributes of the class itself and directly consumed roles. With `:!local` attributes of parent or incorporated JSON classes are included too.
    
      - `Bool` **`:$p, :$k, :$v, :$kv`**
        
        Similarly to many standard Raku routines, these adverbs request for list of pairs, keys, values, and keys and values to be returned. By *values* we mean attribute descriptor objects.

  - **`method json-attrs-by-key(Bool :$local = True, Bool :$p, Bool :$k, Bool :$v, Bool :$kv)`**
    
    Similar to `json-attrs`, but the registry returned is keyed with JSON keys, not Raku attribute names.

  - **`method json-get-attr(Mu, $attr, Bool:D :$local = True)`**
    
    Get attribute descriptor for an attribute. The attribute can be specified either by its name, or by [`Attribute`](https://docs.raku.org/type/Attribute) object.

  - **`method json-has-attr(Mu, $attr, Bool :$local = True)`**
    
    Tell if attribute has a descriptor. Can be given a name or an [`Attribute`](https://docs.raku.org/type/Attribute) object.

  - **`method json-get-key(Mu, Str:D $json-key, Bool :$local = True)`**
    
    Get attribute descriptor for a JSON key name.

  - **`method json-has-key(Mu, Str:D $json-key, Bool :$local = True)`**
    
    Tell if we have a descriptor for the give JSON key.

  - **`method jsonify-attribute(Mu $type, Attribute:D $attribute, *%adverbs)`**
    
    This method adds `$attribute` to the pool of marshallable attributes of the `$type`. This is done by creating an appropriate descriptor and, if necessary, by turning the `$attribute` into a lazy one using [`AttrX::Mooish`](https://raku.land/?q=AttrX::Mooish) module.
    
    The set and types of allowed `%adverbs` is the same as for `is json` trait for attributes.

# SEE ALSO

  - [`JSON::Class`](../../Class.md)

  - [`JSON::Class::Details`](../Details.md)

  - [`JSON::Class::ClassHOW`](../ClassHOW.md)

  - [`JSON::Class::RoleHOW`](../RoleHOW.md)

  - [`JSON::Class::HOW::Laziness`](Laziness.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
