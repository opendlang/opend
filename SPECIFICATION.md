# Version v1.0-beta1

### Value

```
value ::=
      \x00            # null
    | \x01            # true
    | \x02            # false
    | \x03 number
    | \x05 string
    | \x09 array
    | \x0A object
    | \b1???????      # deleted

number              ::= number_length json_number_string

number_length       ::= uint8

string              ::= string_length string_data

string_length       ::= uint32
```

### JSON character encoding
Following JSON encoded characters are decoded to an appropriate unicode character.
```
\"
\\
\/
\b
\f
\n
\r
\t
\u-four-hex-digits
```

### Array

```
array         ::= array_length elements

array_length  ::= uint32                # size of elements

elements
      element elements
    | < empty >
```

### Object

```
object        ::= object_length key_value_pairs

object_length ::= uint32               # size of key_value_pairs
 
key_value_pairs
      key value key_value_pairs
    | < empty >

key           ::= key_length string_data

key_length    ::= uint8
```
