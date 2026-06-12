import Cocoa
import InputMethodKit

// Entry point for the Input Method application
// Input methods are background-only apps that launch automatically
// when selected in System Settings > Keyboard > Input Sources

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
