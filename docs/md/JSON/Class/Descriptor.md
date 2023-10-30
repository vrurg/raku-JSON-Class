# rakudoc

# NAME

`JSON::Class::Descriptor` - base role for attribute and sequence item descriptors

# DESCRIPTION

`JSON::Class` doesn't modify attribute objects of a class meta-object. Instead, it manipulates with their *descriptors*, as described in *Descriptors* section of [`JSON::Class::Details`](Details.md).

# METHODS

  - **`method name()`**
    
    Descriptor name. Informational for using in various messages.

  - **`method type()`**
    
    Constraint type.

  - **`method value-type()`**
    
    For [`Positional`](https://docs.raku.org/type/Positional) and [`Associative`](https://docs.raku.org/type/Associative) types this must be constraint type of their values. For example, for the following declaration this would be `Str:D`:
    
    ``` raku
    has Str:D @.keys is json;
    ```

  - **`method nominal-type()`**
    
    Nominalization of the `value-type`. I.e. for `Str:D()` it would be just nominal `Str`.

  - **`method set-serializer(|)`**
    
    Set serializer for this element. Particular implementation of the method depends on role consumer.

  - **`method set-deserializer(|)`**
    
    Set deserializer for this element. Particular implementation of the method depends on role consumer.

  - **`method register-helper(Str:D $stage, Str:D $kind, $helper)`**
    
    Registers a helper in form of a code object or a method name string. Values of `$stage` and `$kind` are not constrained, but normally these would be one of `JSONStages` from [`JSON::Class::Types`](Types.md) and *'attribute'*, or *'item'*, or *'value'*, or *'key'*.
    
    Thread safe.

  - **`method helper(Str:D $stage, Str:D $kind)`**
    
    Returns a helper for a `$stage`+`$kind` pair or `Nil` if no such one.
    
    Thread safe.

  - **`method has-helper(Str:D $stage, Str:D $kind)`**
    
    Tell if we have a helper for the stage and the kind.
    
    Thread safe.

  - **`method serializer(Str:D $kind)`**
    
    A shortcut for *'to-json'* stage.
    
    Thread safe.

  - **`method deserializer(Str:D $kind)`**
    
    A shortcut for *'from-json'* stage.
    
    Thread safe.

  - **`method declarant()`**
    
    Returns the type object for which this descriptor was created. It can be a role or a class. For example:
    
    ``` raku
    role Key is json {
        has Str $.key;
    }
    ```
    
    Descriptor for `$!key` attribute would return `Key` as its declarant.

  - **`proto method kind-type(Str:D $kind)`**
    
    Return the type object for which marshaller of the `$kind` would apply. For example:
    
    ``` raku
    has Str:D %.shortname{Int:D} is json;
    ```
    
    *'value'* type is `Str:D`, *'key'* type is `Int:D`.
    
    Normally one wouldn't care about these as they're used internally for marshalling purposes. But implementing own descriptor may require adding candidates to this `proto`.

  - **`proto method kind-stage(Str:D $stage, Str:D $kind)`**
    
    This method is necessary to map stage+kind pair into [`JSON::Class::Config`](Config.md) helper stage. In other words, if a marshaller wants to find out if there is a custom helper registered for a type then it would do something like:
    
    ``` raku
    $config.helper($value-type, $descriptor.kind-stage('from-json', 'match'))
    ```
    
    We use *'match'* as the kind because it is currently the only case where this method returns something different from `$stage`.

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Details`](Details.md)

  - [`JSON::Class::Attr`](Attr.md)

  - [`JSON::Class::ItemDescriptor`](ItemDescriptor.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENCE

Artistic License 2.0

See the [*docs/md/LICENCE*](../../LICENCE) file in this distribution.
