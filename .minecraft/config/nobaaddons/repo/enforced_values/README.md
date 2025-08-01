# Enforced Options

This directory is used by the mod to load `.json` files that override values used for certain config options
at runtime, allowing for disabling broken functionality until a release can be made to fix it.

Overridden values cannot be modified by the user, while the value they originally set is preserved in
the (de)serialized config file.

>[!warning]
> Files in this directory **must not be deleted**, as the mod does not currently have the capability
> to delete files that have since been deleted; instead, use a `{"type": "false"}` condition.

## Example

```json
{
  "override": {
    // Fragment of a full config file, overriding certain values. In this case, this sets `autoShareCorpses` in
    // the Glacite Mineshaft group to false.
    "mining": {
      "glaciteMineshaft": {
        "autoShareCorpses": false
      }
    }
  },
  // When this should be applied; in this case, this simply checks if(true), meaning this is always active.
  // See below for other available conditions.
  // This must always be present.
  "if": {"type": "true"},
  // A message to send in chat on the first join in a session, or after updating the repo.
  // This may be null to not send a message in chat, but must still be present in some capacity.
  "message": "Auto Share Corpses has been disabled due to ..."
}
```

## Available Conditions

<details>
<summary><code>true</code></summary>

Always returns `true`.

```json
{
  "type": "true"
}
```

</details>
<details>
<summary><code>false</code></summary>

Always returns `false`. **Use this to deactivate an enforced option.**

```json
{
  "type": "false"
}
```

</details>
<details>
<summary><code>not</code></summary>

Inverts the value of another check.

```json
{
  "type": "not",
  "check": {"type": "false"}
}
```

</details>
<details>
<summary><code>mod</code></summary>

Returns `true` if a mod with the provided `id` is present, and optionally within a specified `min`/`max` version range.

```json
{
  "type": "mod",
  "id": "other_mod",
  // optional; only returns true if the version of other_mod is >=1.0.0
  "min": "1.0.0",
  // optional; only returns true if the version of other_mod is <=1.2.0
  "max": "1.2.0"
}
```

</details>
<details>
<summary><code>self</code></summary>

Same as `mod`, but implicitly targets the `nobaaddons` mod `id`.

```json
{
  "type": "self",
  // optional; only returns true if the mod version is >=1.0.0
  "min": "1.0.0",
  // optional; only returns true if the mod version is <=1.2.0
  "max": "1.2.0"
}
```

</details>
<details>
<summary><code>minecraft</code></summary>

Same as `mod`, but implicitly targets the `minecraft` mod `id`.

```json
{
  "type": "minecraft",
  // optional; only returns true if the current minecraft version is >=1.21.4
  "min": "1.21.4",
  // optional; only returns true if the current minecraft version is <=1.21.6
  "max": "1.21.6"
}
```

</details>
<details>
<summary><code>production</code></summary>

Returns `true` if the player is not in a development environment.

```json
{
  "type": "production"
}
```

</details>
<details>
<summary><code>all</code></summary>

Returns `true` if all provided `checks` also return `true`.

```json
{
  "type": "all",
  "checks": [
    // evaluates to true when both not in a development environment and running <=1.21.6
    {"type": "production"},
    {"type": "minecraft", "max": "1.21.6"}
  ]
}
```

</details>
<details>
<summary><code>any</code></summary>

Returns `true` if any of the provided `checks` return `true`.

```json
{
  "type": "any",
  "checks": [
    // evalutes to true when not in a development environment
    {"type": "false"},
    {"type": "production"}
  ]
}
```

</details>
<details>
<summary><code>none</code></summary>

Returns `true` if none of the provided `checks` return `true`.

```json
{
  "type": "none",
  "checks": [
    // this evaluates as false due to the presence of a check that returns true
    {"type": "true"},
    {"type": "false"}
  ]
}
```

</details>
