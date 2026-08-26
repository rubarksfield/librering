import CoreBluetooth
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var captureControlChannel: FlutterMethodChannel?
  private var connectedPeripheralChannel: FlutterMethodChannel?
  private var connectedPeripheralResolver: ConnectedPeripheralResolver?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "org.librering/capture-control",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setIdleTimerDisabled",
            let disabled = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.isIdleTimerDisabled = disabled
      result(nil)
    }
    captureControlChannel = channel

    let resolver = ConnectedPeripheralResolver()
    let connectedChannel = FlutterMethodChannel(
      name: "org.librering/connected-peripherals",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    connectedChannel.setMethodCallHandler { call, result in
      guard call.method == "retrieve",
            let arguments = call.arguments as? [String: Any],
            let serviceUUIDs = arguments["serviceUuids"] as? [String] else {
        result(FlutterMethodNotImplemented)
        return
      }
      resolver.retrieve(serviceUUIDs: serviceUUIDs, result: result)
    }
    connectedPeripheralResolver = resolver
    connectedPeripheralChannel = connectedChannel
  }
}

private final class ConnectedPeripheralResolver: NSObject, CBCentralManagerDelegate {
  private lazy var central = CBCentralManager(delegate: self, queue: nil)
  private var pending: [([String], FlutterResult)] = []

  override init() {
    super.init()
    _ = central
  }

  func retrieve(serviceUUIDs: [String], result: @escaping FlutterResult) {
    switch central.state {
    case .poweredOn:
      result(connectedPeripheralMaps(serviceUUIDs: serviceUUIDs))
    case .unknown, .resetting:
      pending.append((serviceUUIDs, result))
    default:
      result([])
    }
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    guard central.state != .unknown, central.state != .resetting else { return }
    let callbacks = pending
    pending.removeAll()
    for (serviceUUIDs, result) in callbacks {
      if central.state == .poweredOn {
        result(connectedPeripheralMaps(serviceUUIDs: serviceUUIDs))
      } else {
        result([])
      }
    }
  }

  private func connectedPeripheralMaps(serviceUUIDs: [String]) -> [[String: Any]] {
    let services = serviceUUIDs.map(CBUUID.init(string:))
    guard !services.isEmpty else { return [] }
    return central.retrieveConnectedPeripherals(withServices: services).map { peripheral in
      [
        "id": peripheral.identifier.uuidString,
        "name": peripheral.name ?? "",
        "serviceUuids": serviceUUIDs,
      ]
    }
  }
}
