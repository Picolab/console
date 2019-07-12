# console
a ruleset to evaluate KRL expressions

## usage

Install this ruleset in a pico.

Open the pico's Testing tab, and click on the checkbox beside the ruleset id.

Type a KRL expression into the box with placeholder "expr" and click the "console/expr" button.

The result of evalating the KRL expression will be shown (or a compiler error if the expression is invalid).

## principals of operation

The rule which selects on "console/expr" does the following:

1. creates a new child pico
2. queries the child pico for the source code of a test ruleset and registers it with the engine
3. installs that ruleset in the child pico
4. queries the child pico for the result of evaluating the expression using the test ruleset
5. provides the result with a special `send_directive` as plain text
6. uninstalls the test ruleset from the child pico
7. unregisters the test ruleset from the engine
8. deletes the child pico

### risk

If the expression entered, when incorporated into the test ruleset, causes a compile-time error,
the bad ruleset will still be registered with the pico engine, in an inactive state.

When this happens, you will have to delete it manually in the Engine Rulesets page.

## sample expressions

`meta:host` to learn where the pico engine is hosted

`32.range(127).collect(function(x){x.chr()}).map(function(a){a.head()})` for a quick ASCII table

`355/113` for an approximation of _pi_

