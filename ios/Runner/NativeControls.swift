import Flutter
import UIKit
import CoreText

/// Thin platform bridge. UIKit supplies real Liquid Glass and native menus;
/// document state, preference persistence and navigation stay in Dart.
final class NativeControlsFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let fontName: String

  init(registrar: FlutterPluginRegistrar) {
    messenger = registrar.messenger()
    let key = registrar.lookupKey(forAsset: "packages/lucide_icons_flutter/assets/lucide.ttf")
    var name = "Lucide"
    if let path = Bundle.main.path(forResource: key, ofType: nil) {
      let url = URL(fileURLWithPath: path) as CFURL
      CTFontManagerRegisterFontsForURL(url, .process, nil)
      if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url) as? [CTFontDescriptor],
         let descriptor = descriptors.first {
        name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String ?? name
      }
    }
    fontName = name
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    NativeControlsView(frame: frame, id: viewId, args: args, messenger: messenger, fontName: fontName)
  }
}

private final class NativeControlsView: NSObject, FlutterPlatformView {
  private let root: UIView
  private let channel: FlutterMethodChannel
  private let fontName: String
  private var configuration: [String: Any] = [:]

  init(frame: CGRect, id: Int64, args: Any?, messenger: FlutterBinaryMessenger, fontName: String) {
    root = UIView(frame: frame)
    channel = FlutterMethodChannel(name: "phralio/native-control/\(id)", binaryMessenger: messenger)
    self.fontName = fontName
    super.init()
    update(args as? [String: Any] ?? [:])
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "update", let values = call.arguments as? [String: Any] {
        self?.update(values)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(self, selector: #selector(accessibilityChanged), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(accessibilityChanged), name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification, object: nil)
  }

  deinit { NotificationCenter.default.removeObserver(self) }
  func view() -> UIView { root }
  @objc private func accessibilityChanged() { update(configuration, force: true) }

  private func icon(_ code: Any?, size: CGFloat = 23) -> UIImage? {
    guard let code = code as? Int, let scalar = UnicodeScalar(code),
          let font = UIFont(name: fontName, size: size) else { return nil }
    let text = String(scalar) as NSString
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
    let bounds = text.size(withAttributes: attributes)
    return UIGraphicsImageRenderer(size: CGSize(width: size + 2, height: size + 2)).image { _ in
      text.draw(at: CGPoint(x: (size + 2 - bounds.width) / 2, y: (size + 2 - bounds.height) / 2), withAttributes: attributes)
    }.withRenderingMode(.alwaysTemplate)
  }

  private func fill(_ child: UIView, in parent: UIView, inset: CGFloat = 0) {
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
    // Keep menu presentation and VoiceOver focus stable on unrelated Dart rebuilds.
    if !force && NSDictionary(dictionary: values).isEqual(to: configuration) { return }
    configuration = values
    root.subviews.forEach { $0.removeFromSuperview() }
    root.overrideUserInterfaceStyle = values["dark"] as? Bool == true ? .dark : .light
    let solid = values["solid"] as? Bool == true || UIAccessibility.isReduceTransparencyEnabled || UIAccessibility.isDarkerSystemColorsEnabled
    let tint = UIColor(red: 0.16, green: 0.35, blue: 0.82, alpha: 1)
    root.tintColor = root.overrideUserInterfaceStyle == .dark ? UIColor(red: 0.57, green: 0.71, blue: 1, alpha: 1) : tint
    let items = values["items"] as? [[String: Any]] ?? []
    if values["kind"] as? String == "tabs" {
      let material = UIVisualEffectView()
      if !solid {
        if #available(iOS 26.0, *) {
          let glass = UIGlassEffect(style: .regular)
          glass.isInteractive = true
          material.effect = glass
        } else {
          material.effect = UIBlurEffect(style: .systemMaterial)
        }
      } else {
        material.backgroundColor = .secondarySystemGroupedBackground
      }
      material.clipsToBounds = true
      material.layer.cornerRadius = 36
      material.layer.cornerCurve = .continuous
      fill(material, in: root, inset: 2)
      let stack = UIStackView()
      stack.axis = .horizontal
      stack.distribution = .fillEqually
      fill(stack, in: material.contentView, inset: 5)
      for item in items {
        let selected = item["id"] as? String == values["selected"] as? String
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = icon(item["icon"])
        config.title = item["label"] as? String
        config.imagePlacement = .top
        config.imagePadding = 3
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 1, bottom: 5, trailing: 1)
        config.baseForegroundColor = selected ? root.tintColor : .secondaryLabel
        config.background.backgroundColor = selected ? UIColor.label.withAlphaComponent(0.07) : .clear
        config.background.cornerRadius = 29
        let scale = min(values["textScale"] as? Double ?? 1, 1.4)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
          var result = attributes
          result.font = UIFont.systemFont(ofSize: 11 * scale, weight: selected ? .semibold : .medium)
          return result
        }
        button.configuration = config
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.accessibilityLabel = item["label"] as? String
        button.accessibilityTraits = selected ? [.button, .selected] : [.button]
        button.addAction(UIAction { [weak self] _ in self?.channel.invokeMethod("select", arguments: item["id"]) }, for: .touchUpInside)
        stack.addArrangedSubview(button)
      }
    } else {
      let button = UIButton(type: .system)
      var config: UIButton.Configuration
      if #available(iOS 26.0, *), !solid {
        config = .glass()
      } else {
        config = .filled()
        config.baseBackgroundColor = .secondarySystemGroupedBackground
      }
      config.cornerStyle = .capsule
      config.image = icon(values["icon"])
      config.baseForegroundColor = root.tintColor
      button.configuration = config
      button.accessibilityLabel = values["label"] as? String
      button.accessibilityTraits = values["selected"] as? Bool == true ? [.button, .selected] : [.button]
      button.isEnabled = values["enabled"] as? Bool ?? true
      if !items.isEmpty {
        button.menu = UIMenu(children: items.map { item in
          UIAction(title: item["label"] as? String ?? "", image: icon(item["icon"]), state: item["selected"] as? Bool == true ? .on : .off) { [weak self] _ in
            self?.channel.invokeMethod("select", arguments: item["id"])
          }
        })
        button.showsMenuAsPrimaryAction = true
      } else {
        button.addAction(UIAction { [weak self] _ in self?.channel.invokeMethod("select", arguments: "tap") }, for: .touchUpInside)
      }
      fill(button, in: root, inset: 2)
    }
  }
}
