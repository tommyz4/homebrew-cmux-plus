cask "cmux-plus" do
  version "0.65.2-plus.2"
  sha256 "a11643891b132539751e67a2a6c5d0359494274577a0a101c95e22d3cf7e7e3f"

  url "https://github.com/tommyz4/cmux/releases/download/plus-v#{version}/cmux-plus-macos.dmg"
  name "cmux Plus"
  desc "cmux with unreleased features (Snippets sidebar and context menu); self-signed"
  homepage "https://github.com/tommyz4/cmux"

  depends_on macos: ">= :sonoma"

  app "cmux Plus.app"
  binary "#{appdir}/cmux Plus.app/Contents/Resources/bin/cmux", target: "cmux-plus"

  # The app is ad-hoc signed and not notarized, so Gatekeeper would block it.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/cmux Plus.app"]
  end

  zap trash: [
    "~/Library/Preferences/com.cmuxterm.app.debug.plus.plist",
    "~/.local/state/cmux/dev-plus-last-socket-path",
  ]
end
