# NobaAddons-REPO

Data repository used by the [NobaAddons] mod.

Note for third party consumers - the JSON files stored here may not strictly conform to the JSON standard.

Using `kotlinx.serialization`, you can instruct it to properly handle these files with the following `Json` builder:

```kotlin
Json {
  allowStructuredMapKeys = true
  allowComments = true
  allowTrailingComma = true
  // Optional, but you probably want this.
  //ignoreUnknownKeys = true
}
```

[NobaAddons]: https://modrinth.com/mod/nobaaddons
