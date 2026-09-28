import AppKit
import CoreText
import FlutterMacOS

/// AppKit owns material, hit testing, accessibility, and contextual menus.
/// Flutter retains navigation, document state, and preferences.
final class NativeControlsFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let iconFont: String
  private let uiFont: String

  init(registrar: FlutterPluginRegistrar) {
    messenger = registrar.messenger
    func register(_ asset: String, fallback: String) -> String {
      let key = registrar.lookupKey(forAsset: asset)
      guard let frameworks = Bundle.main.privateFrameworksURL else { return fallback }
      let url: URL
      if let path = Bundle.main.path(forResource: key, ofType: nil) {
        url = URL(fileURLWithPath: path)
      } else {
        url = frameworks.appendingPathComponent("App.framework/Resources/flutter_assets").appendingPathComponent(asset)
      }
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
      guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
            let descriptor = descriptors.first else { return fallback }
      return CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String ?? fallback
    }
    iconFont = register("packages/lucide_icons_flutter/assets/lucide.ttf", fallback: "Lucide")
    uiFont = register("assets/fonts/IBMPlexSans.ttf", fallback: "IBMPlexSans")
    super.init()
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    NativeControlsView(id: viewId, values: args as? [String: Any] ?? [:],
      messenger: messenger, iconFont: iconFont, uiFont: uiFont)
  }
}

private final class NativeControlsView: NSView {
  private let channel: FlutterMethodChannel
  private let iconFont: String
  private let uiFont: String
  private var configuration: [String: Any] = [:]
  override var isFlipped: Bool { true }

  init(id: Int64, values: [String: Any], messenger: FlutterBinaryMessenger, iconFont: String, uiFont: String) {
    channel = FlutterMethodChannel(name: "phralio/native-control/\(id)", binaryMessenger: messenger)
    self.iconFont = iconFont
    self.uiFont = uiFont
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    layer?.cornerRadius = 26
    layer?.masksToBounds = true
    update(values)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "update", let values = call.arguments as? [String: Any] {
        self?.update(values)
        result(nil)
      } else if call.method == "activate" {
        self?.openMenu()
        result(nil)
      } else { result(FlutterMethodNotImplemented) }
    }
    NSWorkspace.shared.notificationCenter.addObserver(self,
      selector: #selector(accessibilityChanged),
      name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
  }

  required init?(coder: NSCoder) { fatalError("Use the platform view factory") }
  deinit {
    channel.setMethodCallHandler(nil)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }
  @objc private func accessibilityChanged() { update(configuration, force: true) }

  private func color(_ key: String) -> NSColor {
    let value = (configuration[key] as? NSNumber)?.uint32Value ?? 0xFF182523
    return NSColor(srgbRed: CGFloat((value >> 16) & 255) / 255,
      green: CGFloat((value >> 8) & 255) / 255, blue: CGFloat(value & 255) / 255, alpha: 1)
  }

  private func icon(_ code: Any?, size: CGFloat = 21, leadingPadding: CGFloat = 0) -> NSImage? {
    guard let code = code as? Int, let scalar = UnicodeScalar(code),
          let font = NSFont(name: iconFont, size: size) else { return nil }
    let image = NSImage(size: NSSize(width: size + 4 + leadingPadding, height: size + 4), flipped: false) { rect in
      let text = String(scalar) as NSString
      let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
      let bounds = text.size(withAttributes: attributes)
      text.draw(at: NSPoint(x: leadingPadding + (rect.width - leadingPadding - bounds.width) / 2,
        y: (rect.height - bounds.height) / 2), withAttributes: attributes)
      return true
    }
    image.isTemplate = true
    return image
  }

  private func fill(_ child: NSView, in parent: NSView, inset: CGFloat = 0) {
    child.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(child)
    NSLayoutConstraint.activate([
      child.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: inset),
      child.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -inset),
      child.topAnchor.constraint(equalTo: parent.topAnchor, constant: inset),
      child.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -inset)
    ])
  }

  private func update(_ values: [String: Any], force: Bool = false) {
    if !force && NSDictionary(dictionary: values).isEqual(to: configuration) { return }
    configuration = values
    layer?.backgroundColor = (values["kind"] as? String == "tabs" ? color("background") : NSColor.clear).cgColor
    subviews.forEach { $0.removeFromSuperview() }
    appearance = NSAppearance(named: values["dark"] as? Bool == true ? .darkAqua : .aqua)
    let solid = values["solid"] as? Bool == true ||
      NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency ||
      NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    let content = NSView()
    // Glass casts a rectangular backdrop at the Flutter platform-view edge;
    // the native sidebar material clips cleanly to its rounded bounds.
    if #available(macOS 26.0, *), !solid, values["kind"] as? String != "tabs" {
      let glass = NSGlassEffectView()
      glass.style = .regular
      glass.cornerRadius = 24
      glass.contentView = content
      fill(glass, in: self, inset: 2)
    } else if !solid {
      let material = NSVisualEffectView()
      material.material = .sidebar
      material.blendingMode = .withinWindow
      material.state = .active
      material.wantsLayer = true
      material.layer?.cornerRadius = 24
      material.layer?.masksToBounds = true
      fill(material, in: self, inset: 2)
      fill(content, in: material)
    } else {
      content.wantsLayer = true
      content.layer?.backgroundColor = color("surface").cgColor
      content.layer?.cornerRadius = 24
      fill(content, in: self, inset: 2)
    }
    let items = values["items"] as? [[String: Any]] ?? []
    let navigation = values["kind"] as? String == "tabs"
    if navigation {
      let vertical = values["vertical"] as? Bool == true
      let compact = values["compact"] as? Bool == true
      let stack = NSStackView()
      stack.orientation = vertical ? .vertical : .horizontal
      stack.distribution = .fillEqually
      stack.spacing = 4
      fill(stack, in: content, inset: 6)
      for item in items {
        let selected = item["id"] as? String == values["selected"] as? String
        let button = makeButton(item, title: !compact, selected: selected)
        button.imagePosition = compact ? .imageOnly : vertical ? .imageLeading : .imageAbove
        button.alignment = vertical && !compact ? .left : .center
        stack.addArrangedSubview(button)
        if vertical { button.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        else { button.heightAnchor.constraint(equalTo: stack.heightAnchor).isActive = true }
      }
    } else {
      let button = makeButton(values, title: false, selected: values["selected"] as? Bool == true)
      button.identifier = NSUserInterfaceItemIdentifier("tap")
      button.isEnabled = values["enabled"] as? Bool ?? true
      fill(button, in: content)
    }
  }

  private func makeButton(_ item: [String: Any], title: Bool, selected: Bool) -> NSButton {
    let label = item["label"] as? String ?? ""
    let button = NSButton(title: title ? label : "", target: self, action: #selector(activate(_:)))
    button.identifier = NSUserInterfaceItemIdentifier(item["id"] as? String ?? "tap")
    let leadingPadding: CGFloat = configuration["kind"] as? String == "tabs" &&
      configuration["vertical"] as? Bool == true &&
      configuration["compact"] as? Bool != true ? 14 : 0
    button.image = icon(item["icon"], leadingPadding: leadingPadding)
    button.imagePosition = .imageOnly
    button.isBordered = false
    button.bezelStyle = .rounded
    button.contentTintColor = selected || !title ? color("accent") : color("secondary")
    button.toolTip = label
    button.setAccessibilityLabel(label)
    if configuration["kind"] as? String == "tabs" {
      button.setAccessibilityRole(.radioButton)
      button.setAccessibilityValue(selected ? 1 : 0)
    }
    let scale = min(configuration["textScale"] as? Double ?? 1, 1.6)
    let base = NSFont(name: uiFont, size: 15 * scale) ?? NSFont.systemFont(ofSize: 15 * scale)
    let descriptor = base.fontDescriptor.addingAttributes([
      NSFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [NSNumber(value: 0x77676874): NSNumber(value: 500)]
    ])
    button.font = NSFont(descriptor: descriptor, size: 15 * scale)
    button.wantsLayer = true
    button.layer?.cornerRadius = 16
    button.layer?.backgroundColor = selected ? color("accent").withAlphaComponent(0.1).cgColor : NSColor.clear.cgColor
    return button
  }

  @objc private func activate(_ sender: NSButton) {
    let items = configuration["items"] as? [[String: Any]] ?? []
    if configuration["kind"] as? String == "menu", !items.isEmpty {
      openMenu()
    } else {
      channel.invokeMethod("select", arguments: sender.identifier?.rawValue ?? "tap")
    }
  }

  private func openMenu() {
      guard configuration["enabled"] as? Bool != false else { return }
      let items = configuration["items"] as? [[String: Any]] ?? []
      let menu = NSMenu()
      menu.autoenablesItems = false
      for item in items {
        let action = NSMenuItem(title: item["label"] as? String ?? "", action: #selector(menuSelected(_:)), keyEquivalent: "")
        action.target = self
        action.representedObject = item["id"]
        action.image = icon(item["icon"], size: 17)
        action.state = item["selected"] as? Bool == true ? .on : .off
        menu.addItem(action)
      }
      menu.popUp(positioning: nil, at: NSPoint(x: 0, y: bounds.height), in: self)
  }

  @objc private func menuSelected(_ sender: NSMenuItem) {
    channel.invokeMethod("select", arguments: sender.representedObject)
  }
}
