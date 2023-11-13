# NAME

`JSON::Class::Dict` - parent of JSON dictionary classes

# DESCRIPTION

This class is injected into the list of parents of any JSON dictionary class. It implements the essential functionality of dictionary marshalling.

## Dictionary Key Objects

Dictionaries allow to use non-string key objects. This is equivalent to `my %h{Foo:D}` kind of hashes:

``` raku
class JDict is json( :dictionary(..., :keyof(Foo:D)) ) {}
```

See more about the `is json` trait and its arguments at [`JSON::Class`](../Class.md) page.

Let's mention a non-apparent aspect of keying over class instances.

When we use objects as hash keys it works best with value objects. For non-values hashes are using objects unique identifiers as key values since these never change during an instance life time. This result in cases where seemingly identical objects of the same class result in different keys on a hash:

``` raku
class Foo { has Str:D $.id is required; }
my $foo1 = Foo.new(:id<the-answer-is-42>);
my $foo2 = Foo.new(:id<the-answer-is-42>);
my %h{Foo:D};
%h{$foo1} = True;
say %h{$foo2}:exists; # False
say %h{$foo1}:exists; # False
```

This is a problem for `JSON::Class` because whenever we deserialize a just've serialized JSON we get a new object, not the original one. But from the user perspective if there is a deserialization of a JSON object in a dictionary `$jdict` of the `JDict` type from above example, where there is a key produced from the `$foo1` instance, then it would be natural if `$jdict{$foo2}` would return that key's value.

With all this in mind, there is a common rule for JSON dictionary keys:

*Key objects of a JSON dictionary are invariants over their JSON serialization.*

As an implication, JSON dictionaries internally index over JSON representations of key objects.

Another implication is that iteration over a JSON dictionary keys may return not the originally used key objects.

# METHODS

This class implements most of the methods standard for the mutable associative types like the [`Hash`](https://docs.raku.org/type/Hash) itself. I.e. `AT-KEY`, `elems`, etc. This set could be incomplete yet, but new methods may be added to it later.

  - **`method json-all-set()`**
    
    Returns *True* if all dictionary values are deserialized.

  - **`multi method json-guess-descriptor(:$json-value, :$key)`**
    
    Returns a matching value descriptor for the given JSON value. `$key` is the dictionary key object which is being deserialized now.

  - **`method json-serialize-item(JSON::Class::ItemDescriptor:D $descriptor, Pair:D $item)`**
    
    Serialize given `$item`, both key and value, using value `$descriptor`. Since there is no need to guess key descriptor as there is always only one available through `self.json-key-descriptor`, it is not passed in as an argument.

  - **`method json-deserialize-item(Mu $key, $json-value)`**
    
    Deserializer for JSON value at `$key`. Note that this method only takes care about a value, not the key, which is already passed in in its deserialized form.

  - **`method json-key2str(Mu \key-type, Mu \key --` Str:D)**\>
    
    This method key serialization falls back to to turn a `key` object into JSON-supported string representation.
    
      - **`multi method json-key2str(Str, Str:D \key)`**
        
        Identity method, `key` just falls through unchanged.
    
      - **`multi method json-key2str(Mu \key-type, Mu \key)`**
        
        Serialize `key` using `json-serialize-value` method. Then turns it into a JSON string with [`JSON::Class::Config`](Config.md) `to-json` method using `:!pretty` and `:sorted-keys` arguments in order to get compact and reproducible representation of the `key`.

  - **`proto method json-str2key(|)`**
    
    The fallback method for key deserialization.
    
      - **`multi method json-str2key(Str:D $json-key, JSON::Class::Jsonish \key-type --` Mu)**\>
        
        Simply calls `from-json` method on `key-type`. This candidate is also used for non-JSON classes by implicitly JSONifying the key type first. Therefore the return value of the `from-json` method could be an instance of the original, non-JSON class.
    
      - **`multi method json-str2key(Str:D $json-key, Mu \key-type)`**
        
        This candidate tries to coerce `$json-key` into the key type.

  - **`multi method json-deserialize(%from, JSON::Class::Config :$config)`**
    
    The method first tries to map its `self.WHAT` into a destination type by using [`JSON::Class::Config`](Config.md) type mapping. Then the result of the previous step is instantiated and returned.

*Note:* The following methods operate on serialized, i.e. JSON, versions of keys directly in the backend storage.

  - **`method json-key-object(Str:D $json-key --` Mu)**\>
    
    Returns a deserialization of the `$json-key` or `Nil` if no such key is found in the backend storage. The deserialization is cached, so that subsequent calls to this method just pull an existing object for its JSON key.

  - **`method json-exists-key(Str:D $json-key)`**
    
    Returns *True* if the keys is known to the backend storage.

  - **`method json-has-key(Str:D $json-key)`**
    
    Returns *True* if the value for `$json-key` has been unmarshalled already.

  - **`method json-assign-key(Str:D $json-key, Mu \value, Mu :$key)`**
    
    Assign a value at `$json-key`. `$key` named argument can provide the original key object for caching.

  - **`method json-delete-key(Str:D $json-key --` Mu)**\>
    
    Delete an item by its JSON key. For undeserialized yet items the default would be returned as if they never existed. This may seem a bit illogical, but to return a deserialization would require it to be produced in first place, but does it worth spending CPU cycles when it is most likely for the result to be immediately sinked? If the value is needed the best course of actions would be either to check out if it's there already with `$jdict{$key}:has`

## The Standard Methods

Currently implemented methods, standard for Raku's mutable associative types:

  - **`ASSIGN-KEY`**

  - **`AT-KEY`**

  - **`CLEAR`**

  - **`DELETE-KEY`**

  - **`EXISTS-KEY`**

  - **`HAS-KEY`**

  - **`append`**

  - **`elems`**

  - **`end`**

  - **`gist`**

  - **`Hash`**

  - **`iterator`**

  - **`keys`**

  - **`kv`**

  - **`list`**

  - **`pairs`**

  - **`push`**

  - **`raku`**

  - **`Str`**

  - **`values`**

# SEE ALSO

  - [`JSON::Class`](../Class.md)

  - [`JSON::Class::Details`](Details.md)

  - [`JSON::Class::Dictionary`](Dictionary.md)

  - [`JSON::Class::DictHOW`](DictHOW.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
