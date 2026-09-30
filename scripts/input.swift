// Синтетические события мыши и клавиатуры для проверки ввода в CI.
//   swiftc scripts/input.swift -o build/input
//   build/input move 512 5        — курсор в точку (от верхнего левого угла экрана)
//   build/input click 512 5       — клик
//   build/input key 2 option      — клавиша по виртуальному коду (2 — D) с модификатором
//   build/input screen            — ширина и высота главного экрана
// Нужно разрешение «Управление компьютером» для процесса, который запускает.
import CoreGraphics
import Foundation

func fail() -> Never {
    FileHandle.standardError.write(Data("input move|click x y | key code [option|command]\n".utf8))
    exit(2)
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else { fail() }

func mouse(_ type: CGEventType, _ point: CGPoint) {
    CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)?
        .post(tap: .cghidEventTap)
}

switch command {
case "screen":
    let bounds = CGDisplayBounds(CGMainDisplayID())
    print(Int(bounds.width), Int(bounds.height))
case "move", "click":
    guard args.count == 3, let x = Double(args[1]), let y = Double(args[2]) else { fail() }
    let point = CGPoint(x: x, y: y)
    mouse(.mouseMoved, point)
    if command == "click" {
        usleep(60_000)
        mouse(.leftMouseDown, point)
        usleep(60_000)
        mouse(.leftMouseUp, point)
    }
case "key":
    guard args.count >= 2, let code = UInt16(args[1]) else { fail() }
    var flags: CGEventFlags = []
    if args.dropFirst(2).contains("option") { flags.insert(.maskAlternate) }
    if args.dropFirst(2).contains("command") { flags.insert(.maskCommand) }
    for down in [true, false] {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)
        event?.flags = flags
        event?.post(tap: .cghidEventTap)
        usleep(40_000)
    }
default:
    fail()
}
