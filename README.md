# cmux Plus Homebrew tap

cmux Plus is [cmux](https://github.com/manaflow-ai/cmux) with the Snippets features that haven't landed upstream yet: a searchable Snippets tab in the right sidebar and a Snippets submenu in the terminal's right-click menu. Builds come from [tommyz4/cmux](https://github.com/tommyz4/cmux) `main`.

```bash
brew install --cask tommyz4/cmux-plus/cmux-plus
brew upgrade --cask cmux-plus
```

It installs as `cmux Plus.app`, next to stable cmux, with its own socket, sign-in link and settings. The CLI is linked as `cmux-plus`.

The app is self-signed and not notarized. The cask clears the quarantine flag after installing, so macOS opens it without a warning. There's no auto-update: upgrades come through `brew upgrade`. The Cloud tunnel system extension won't load in a self-signed build.

## Building a new version

From a cmux checkout of `tommyz4/cmux` `main` (needs Xcode, zig and rustup):

```bash
scripts/build-cmux-plus.sh ~/Developer/cmux 0.65.2-plus.2
gh release create plus-v0.65.2-plus.2 ~/Library/Caches/cmux-plus-build/cmux-plus-macos.dmg \
  --repo tommyz4/cmux --target <commit printed by the script> --latest=false
git commit -am "cmux-plus 0.65.2-plus.2" && git push
```
