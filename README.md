# plasma-taskmanager-rules

Minimal Plasma 6 task manager with rule-based icon / color / background overrides.
Rules live in one shared file: `~/.config/plasma-taskmanager-rules/rules.json`.

## Install (Arch)

```sh
makepkg -fsi
```

Rebuild after Plasma upgrades (the C++ plugin links against Qt).

## Reload

```sh
systemctl --user restart plasma-plasmashell.service   # or: kquitapp6 plasmashell && kstart plasmashell
```

Then add "Task Manager Rules" to a panel in place of the stock task manager.

## Develop

```sh
node --test js/                               # rule engine + editor tests
ctest --test-dir build --output-on-failure    # IO helper, config store, editor page (headless)
cmake -S . -B build -G Ninja && cmake --build build
```
