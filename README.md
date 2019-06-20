Currently this is a messy project that I use for experimenting with SwiftUI and a single store unidirectional architecture. I hope to eventually pull out a library called ElmKit (subject to change) from it.

#  ElmKit

Blah blah, Elm is awesome. If you already knew that, you're awesome. Lots of work needed.

## TODO:
- [ ] See how we could support multiple ViewStores. Child store created from parent, e.g. so that a View in a list of items doesnt need a `context` property and doesnt need to work with the root store. The problem is we need to somehow refer to these child stores via bindings so that we can mutate them in a Transaction, so all the children may actually need to be stored in the Program itself
- [ ] Create Swift package ElmKit with its own repo
- [ ] Add UnitTests
- [ ] extensively test Program with recursive dispatches from Commands and Subscriptions
- [ ] Add a more real world example, possibly build it in a separate repo (whichever is usual for SPM, I dont know)
- [ ] Add default values and/or overloads to Program.init for convenience.
- [ ] Add support for headless Programs (possibly a separate Program-like class, as current Program is heavily SwiftUI dependant)
- [ ] Reconsider `Command.effect` vs `Command.internal` API.
- [ ] Make a whole bunch of stuff private (might require some proxy types)
- [ ] Read all code TODO:'s and convert them to tasks here or remove them 



