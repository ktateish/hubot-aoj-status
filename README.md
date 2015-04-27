# hubot-aoj-status

A hubot script that watch judge results on AOJ

See [`src/aoj-status.coffee`](src/aoj-status.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-aoj-status --save`

Then add **hubot-aoj-status** to your `external-scripts.json`:

```json
["hubot-aoj-status"]
```

## Sample Interaction

```
user1>> hubot aoj watch foo
hubot>> I'll watch foo's judge results on AOJ
```
