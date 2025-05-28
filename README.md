# Remove trailing whitespace

Adds event that will remove trailing whitespaces on vis

## Use

```
require"vis.remove-trailing-whitespace".Subscribe()
```

## Install

use erf vis-plugins or

```
vispath=$HOME/.config/vis
mkdir -p $vispath/lua/vis
git clone https://github.com/Nomarian/vis-remove-trailing-whitespace $vispath/lua/vis/remove-trailing-whitespace
```

remember to add "vispath/lua/?.lua" to your package.path
