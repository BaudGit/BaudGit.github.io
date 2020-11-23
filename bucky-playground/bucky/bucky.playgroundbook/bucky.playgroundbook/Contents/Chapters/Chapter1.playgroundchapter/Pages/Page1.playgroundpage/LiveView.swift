import UIKit
import CoreBluetooth
import PlaygroundBluetooth
import PlaygroundSupport
import BookAPI

private let serviceUuids = [CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")]
private let characteristicUuids = [CBUUID(string: "20FB")]

public struct LogValue {
  // directions
  var rollDir: Int
  var pitchDir: Int
  var yawDir: Int
  // angles
  var angleX: Int
  var angleY: Int
  var angleZ: Int
  // light
  var light: Int
  // touches
  var hexagonTouch: Int
  var triangleTouch: Int
  var squareTouch: Int
  var rhombusTouch: Int
  var trapezeTouch: Int
}

public enum Bit: UInt8, CustomStringConvertible {
  case zero, one

  public var description: String {
    switch self {
    case .one:
      return "1"
    case .zero:
      return "0"
    }
  }
}

public func bits(fromByte byte: UInt8) -> [Bit] {
  var byte = byte
  var bits = [Bit](repeating: .zero, count: 8)
  for i in 0..<8 {
    let currentBit = byte & 0x01
    if currentBit != 0 {
      bits[7 - i] = .one
    }

    byte >>= 1
  }

  return bits
}

class ViewController: UIViewController, PlaygroundLiveViewMessageHandler {
  var logText = ""

  var textView: UITextView!
  var connectionView: PlaygroundBluetoothConnectionView!
  var peripheral: CBPeripheral!
  var characteristic: CBCharacteristic!

  let centralManager = PlaygroundBluetoothCentralManager(services: nil)

  var value: LogValue!
  var writeValue: [UInt8] = [0x5A, 0x5A, 0x5A, 0x5A, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

  override func loadView() {
    super.viewDidLoad()

    var view = UIView()
    view.backgroundColor = .white
    self.view = view
  }

  override func viewDidLoad() {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height

    textView = UITextView(frame: CGRect(x: 20, y: 120, width: screenWidth / 2 - 40, height: screenHeight))
    textView.text = logText
    textView.textColor = .black
    self.view.addSubview(textView)

    centralManager.delegate = self

    connectionView = PlaygroundBluetoothConnectionView(centralManager: centralManager)
    connectionView.delegate = self
    connectionView.dataSource = self

    self.view.addSubview(connectionView)
    NSLayoutConstraint.activate([
      connectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      connectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
    ])
  }

  public func receive(_ message: PlaygroundValue) {
    switch message {
      case let .array(params):
        switch params[0] {
          case let .string(prop):
            if prop == "motor" {
              switch params[1] {
                case let .integer(index):
                  switch params[2] {
                    case let .integer(speed):
                      writeValue[index - 1] = (UInt8)(speed)
                      let data = Data(writeValue)
                      self.peripheral.writeValue(data, for: self.characteristic, type: .withResponse)
                    default:
                      break
                  }
                default:
                  break
              }
            } else if prop == "color" {
              switch params[1] {
                case let .integer(red):
                  switch params[2] {
                    case let .integer(green):
                      switch params[3] {
                        case let .integer(blue):
                          writeValue[4] = (UInt8)(red)
                          writeValue[5] = (UInt8)(green)
                          writeValue[6] = (UInt8)(blue)
                          let data = Data(writeValue)
                          self.peripheral.writeValue(data, for: self.characteristic, type: .withResponse)
                        default:
                          break
                      }
                    default:
                      break
                  }
                default:
                  break
              }
            }
          default:
            break
        }
      default:
        break
    }
  }

  public func printValue() {
    let value = self.value!

    self.textView?.text = ""

    self.textView?.text += "roll: " + String(describing: value.rollDir) + "\n"
    self.textView?.text += "pitch: " + String(describing: value.pitchDir) + "\n"
    self.textView?.text += "yaw: " + String(describing: value.yawDir) + "\n"

    self.textView?.text += "\n"

    self.textView?.text += "x angle: " + String(describing: value.angleX) + "\n"
    self.textView?.text += "y angle: " + String(describing: value.angleY) + "\n"
    self.textView?.text += "z angle: " + String(describing: value.angleZ) + "\n"

    self.textView?.text += "\n"

    self.textView?.text += "light: " + String(describing: value.light) + "\n"

    self.textView?.text += "\n"

    self.textView?.text += "hexagon touch: " + String(describing: value.hexagonTouch) + "\n"
    self.textView?.text += "triangle touch: " + String(describing: value.triangleTouch) + "\n"
    self.textView?.text += "square touch: " + String(describing: value.squareTouch) + "\n"
    self.textView?.text += "rhombus touch: " + String(describing: value.rhombusTouch) + "\n"
    self.textView?.text += "trapeze touch: " + String(describing: value.trapezeTouch) + "\n"
  }

  public func parseValue() {
    let logBytes = [UInt8](self.characteristic.value!)
    let directionBites = bits(fromByte: logBytes[0])

    let lightBites = bits(fromByte: logBytes[4]) + bits(fromByte: logBytes[5])
    let lightString = lightBites.map(String.init).joined()

    let touchBites = bits(fromByte: logBytes[6])

    self.value = LogValue(
      rollDir: directionBites[0] == Bit.one ? 1 : 0,
      pitchDir: directionBites[1] == Bit.one ? 1 : 0,
      yawDir: directionBites[2] == Bit.one ? 1 : 0,
      angleX: Int(logBytes[1]%180),
      angleY: Int(logBytes[2]%180),
      angleZ: Int(logBytes[3]%180),
      light: Int(lightString, radix: 2)!,
      hexagonTouch: touchBites[5] == Bit.one ? 1 : 0,
      triangleTouch: touchBites[7] == Bit.one ? 1 : 0,
      squareTouch: touchBites[4] == Bit.one ? 1 : 0,
      rhombusTouch: touchBites[6] == Bit.one ? 1 : 0,
      trapezeTouch: touchBites[3] == Bit.one ? 1 : 0
    )

    PlaygroundKeyValueStore.current["rollDir"] = .integer(self.value.rollDir)
    PlaygroundKeyValueStore.current["pitchDir"] = .integer(self.value.pitchDir)
    PlaygroundKeyValueStore.current["yawDir"] = .integer(self.value.yawDir)

    PlaygroundKeyValueStore.current["angleX"] = .integer(self.value.angleX)
    PlaygroundKeyValueStore.current["angleY"] = .integer(self.value.angleY)
    PlaygroundKeyValueStore.current["angleZ"] = .integer(self.value.angleZ)

    PlaygroundKeyValueStore.current["light"] = .integer(self.value.light)

    PlaygroundKeyValueStore.current["hexagon"] = .integer(self.value.hexagonTouch)
    PlaygroundKeyValueStore.current["triangle"] = .integer(self.value.triangleTouch)
    PlaygroundKeyValueStore.current["square"] = .integer(self.value.squareTouch)
    PlaygroundKeyValueStore.current["rhombus"] = .integer(self.value.rhombusTouch)
    PlaygroundKeyValueStore.current["trapeze"] = .integer(self.value.trapezeTouch)

    self.printValue();
  }
}

extension ViewController: PlaygroundBluetoothConnectionViewDelegate {
  func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, shouldDisplayDiscovered peripheral: CBPeripheral, withAdvertisementData advertisementData: [String : Any]?, rssi: Double) -> Bool {
    let visible = (peripheral.name ?? "").contains("Bucky")
    return visible
  }

  func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, shouldConnectTo peripheral: CBPeripheral, withAdvertisementData advertisementData: [String : Any]?, rssi: Double) -> Bool {
    return true
  }

  func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, willDisconnectFrom peripheral: CBPeripheral) {
  }

  func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, titleFor state: PlaygroundBluetoothConnectionView.State) -> String {
    switch state {
      case .noConnection:
          return "Connect"
      case .connecting:
          return "Connecting..."
      case .searchingForPeripherals:
          return "Searching..."
      case .selectingPeripherals:
          return "Select Bucky"
      case .connectedPeripheralFirmwareOutOfDate:
          return "Connect"
    }
  }

  func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, firmwareUpdateInstructionsFor peripheral: CBPeripheral) -> String {
    return #function
  }
}

extension ViewController: PlaygroundBluetoothConnectionViewDataSource {
  func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, itemForPeripheral peripheral: CBPeripheral, withAdvertisementData advertisementData: [String : Any]?) -> PlaygroundBluetoothConnectionView.Item {
    let icon = UIImage()
    let name = peripheral.name ?? peripheral.identifier.uuidString
    let item = PlaygroundBluetoothConnectionView.Item(name: name, icon: icon, issueIcon: icon, firmwareStatus: nil, batteryLevel: nil)

    return item
  }
}

extension ViewController: PlaygroundBluetoothCentralManagerDelegate {
  func centralManagerStateDidChange(_ centralManager: PlaygroundBluetoothCentralManager) {
  }

  func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didDiscover peripheral: CBPeripheral, withAdvertisementData advertisementData: [String : Any]?, rssi: Double) {
  }

  func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, willConnectTo peripheral: CBPeripheral) {
  }

  func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didConnectTo peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(serviceUuids)
  }

  func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didFailToConnectTo peripheral: CBPeripheral, error: Error?) {
  }

  func centralManager(_ centralManager: PlaygroundBluetoothCentralManager, didDisconnectFrom peripheral: CBPeripheral, error: Error?) {
  }
}

extension ViewController: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    peripheral.services?.forEach { service in
      peripheral.discoverCharacteristics(characteristicUuids, for: service)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    service.characteristics?.forEach { characteristic in
      if characteristic.uuid.uuidString == characteristicUuids[0].uuidString {
        self.peripheral = peripheral
        self.characteristic = characteristic

        if self.characteristic.properties.contains(.read) {
          self.peripheral.readValue(for: self.characteristic)
        }
      }
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    self.parseValue()
    self.peripheral.readValue(for: self.characteristic)
  }
}

PlaygroundPage.current.liveView = ViewController()
PlaygroundPage.current.needsIndefiniteExecution = true
