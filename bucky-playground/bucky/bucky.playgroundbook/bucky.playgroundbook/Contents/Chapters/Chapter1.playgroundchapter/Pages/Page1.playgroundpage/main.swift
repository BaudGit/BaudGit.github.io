/*:
 **Instructions:**
 1. Power on your Bucky.
 2. Press the **Connect** button in the Live View and choose your Bucky from the list.
 3. Press the **Run My Code** button.
 */
//#-hidden-code
import UIKit
import PlaygroundSupport

guard let remoteView = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
  fatalError("Error: no LiveView here")
}

public func setMotor(_ number: Int, _ speed: Int) {
  remoteView.send(.array([.string("motor"), .integer(number), .integer(speed + 90)]))
  Thread.sleep(forTimeInterval: 0.5)
}
public func setColor(_ red: Int, _ green: Int, _ blue: Int) {
  remoteView.send(.array([.string("color"), .integer(red), .integer(green), .integer(blue)]))
  Thread.sleep(forTimeInterval: 0.5)
}

public func stop() {
  remoteView.send(.array([.string("motor"), .integer(1), .integer(90)]))
  remoteView.send(.array([.string("motor"), .integer(2), .integer(90)]))
  remoteView.send(.array([.string("motor"), .integer(3), .integer(90)]))
  remoteView.send(.array([.string("motor"), .integer(4), .integer(90)]))
}
public func moveForward() {
  remoteView.send(.array([.string("motor"), .integer(1), .integer(180)]))
  remoteView.send(.array([.string("motor"), .integer(2), .integer(0)]))
  remoteView.send(.array([.string("motor"), .integer(3), .integer(180)]))
  remoteView.send(.array([.string("motor"), .integer(4), .integer(0)]))
}
public func moveBackward() {
  remoteView.send(.array([.string("motor"), .integer(1), .integer(0)]))
  remoteView.send(.array([.string("motor"), .integer(2), .integer(180)]))
  remoteView.send(.array([.string("motor"), .integer(3), .integer(0)]))
  remoteView.send(.array([.string("motor"), .integer(4), .integer(180)]))
}
public func turnRight() {
  remoteView.send(.array([.string("motor"), .integer(1), .integer(180)]))
  remoteView.send(.array([.string("motor"), .integer(2), .integer(180)]))
  remoteView.send(.array([.string("motor"), .integer(3), .integer(180)]))
  remoteView.send(.array([.string("motor"), .integer(4), .integer(180)]))
}
public func turnLeft() {
  remoteView.send(.array([.string("motor"), .integer(1), .integer(0)]))
  remoteView.send(.array([.string("motor"), .integer(2), .integer(0)]))
  remoteView.send(.array([.string("motor"), .integer(3), .integer(0)]))
  remoteView.send(.array([.string("motor"), .integer(4), .integer(0)]))
}

public func getValue(_ name: String) -> Int {
  var value: Int = 0

  if let keyValue = PlaygroundKeyValueStore.current[name],
    case .integer(let resValue) = keyValue {
      value = resValue
    }

  return value
}
public func getLight() -> Int {
  return getValue("light")
}
public func getDirection(_ axis: String) -> Int {
  return getValue(axis + "Dir")
}
public func getTouch(_ sensor: String) -> Int {
  return getValue(sensor)
}
public func getAngle(_ axis: String) -> Int {
  return getValue("angle" + axis.uppercased())
}
//#-end-hidden-code
//#-editable-code
setColor(0, 255, 255) // Change color to cyan in RGB. Colors go from 0 to 255 to control their brightness
sleep(UInt32(0.2))    // Wait 0.2 seconds
moveForward()         // Make the robot move forward
sleep(1)              // This wait will define how far the robot will move forward
stop()                // This functions makes the robot stop
setColor(255, 255, 0) // Change color to yellow
turnRight()           // This function maker the robot turn right
sleep(2)              // This wait will define how long the robot will be turning right
stop()
setColor(0, 255, 0)   // Change color to green
sleep(1)
setMotor(1, 90)       // You can also control single motors. The first parameter is the motor number. The second is speed, 90 is full speed in one direction
sleep(1)
setMotor(1, -90)      // And -90 is full speed in the other direction
sleep(1)
setMotor(1, 0)        // With zero you can stop it
//#-end-editable-code
