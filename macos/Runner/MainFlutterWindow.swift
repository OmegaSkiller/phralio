import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var commandChannel: FlutterMethodChannel?
  private var readingMenu: NSMenuItem?

  private func configureMenus(_ values: [String: Any]) {
    guard let main = NSApp.mainMenu, let labels = values["labels"] as? [String], labels.count == 6 else { return }
    appearance = NSAppearance(named: values["dark"] as? Bool == true ? .darkAqua : .aqua)
    if let previous = readingMenu { main.removeItem(previous) }
    let title = values["title"] as? String ?? "Phralio"
    let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    let menu = NSMenu(title: title)
    menu.autoenablesItems = false
    for (index, command) in ["0", "1", "2", "3", "text", "url"].enumerated() {
      if index == 4 { menu.addItem(.separator()) }
      let shortcut = index < 4 ? String(index + 1) : index == 4 ? "n" : ""
      let action = NSMenuItem(title: labels[index], action: #selector(desktopCommand(_:)), keyEquivalent: shortcut)
      action.target = self
      action.representedObject = command
      menu.addItem(action)
    }
    item.submenu = menu
    main.insertItem(item, at: 1)
    readingMenu = item
    if let preferences = main.items.first?.submenu?.items.first(where: { $0.keyEquivalent == "," }) {
      preferences.title = labels[3] + "…"
      preferences.target = self
      preferences.action = #selector(desktopCommand(_:))
      preferences.representedObject = "3"
      preferences.isEnabled = true
    }
  }

  @objc private func desktopCommand(_ sender: NSMenuItem) {
    commandChannel?.invokeMethod("select", arguments: sender.representedObject)
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    title = "Phralio"
    contentMinSize = NSSize(width: 760, height: 540)
    setContentSize(NSSize(width: 1120, height: 780))
    if !setFrameUsingName("PhralioReaderWindow") { center() }
    setFrameAutosaveName("PhralioReaderWindow")
    titlebarAppearsTransparent = true
    toolbarStyle = .unified

    RegisterGeneratedPlugins(registry: flutterViewController)
    let registrar = flutterViewController.registrar(forPlugin: "PhralioNativeControls")
    registrar.register(NativeControlsFactory(registrar: registrar), withId: "phralio/native-control")

    let commands = FlutterMethodChannel(name: "phralio/desktop", binaryMessenger: flutterViewController.engine.binaryMessenger)
    commandChannel = commands
    commands.setMethodCallHandler { [weak self] call, result in
      if call.method == "configure", let values = call.arguments as? [String: Any] {
        self?.configureMenus(values)
        result(nil)
      } else if call.method == "disable" {
        if let item = self?.readingMenu { NSApp.mainMenu?.removeItem(item) }
        self?.readingMenu = nil
        result(nil)
      } else { result(FlutterMethodNotImplemented) }
    }
    super.awakeFromNib()
  }
}
