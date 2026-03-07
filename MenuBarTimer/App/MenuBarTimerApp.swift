import SwiftUI
import AppKit

@main
struct MenuBarTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    let timerManager = TimerManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = makeIdleIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        let contentView = ContentView()
            .environmentObject(timerManager)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        timerManager.onTick = { [weak self] progress, text in
            DispatchQueue.main.async {
                self?.updateIcon(progress: progress, text: text)
            }
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Menu Bar Icon

    private func updateIcon(progress: Double, text: String?) {
        if progress <= 0 && text == nil {
            statusItem.button?.image = makeIdleIcon()
            statusItem.button?.title = ""
            return
        }

        statusItem.button?.image = makeProgressIcon(progress: progress)
        statusItem.button?.title = text.map { " \($0)" } ?? ""
    }

    private func makeIdleIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 7

            // Simple circle
            ctx.setStrokeColor(NSColor.labelColor.cgColor)
            ctx.setLineWidth(1.5)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.strokePath()

            // Clock hands: hour hand + minute hand
            ctx.setLineCap(.round)

            // Minute hand (pointing to 12 / up)
            ctx.setLineWidth(1.5)
            ctx.move(to: center)
            ctx.addLine(to: CGPoint(x: center.x, y: center.y + 5))
            ctx.strokePath()

            // Hour hand (pointing to 3 / right)
            ctx.setLineWidth(1.5)
            ctx.move(to: center)
            ctx.addLine(to: CGPoint(x: center.x + 3.5, y: center.y))
            ctx.strokePath()

            return true
        }
        image.isTemplate = true
        return image
    }

    private func makeProgressIcon(progress: Double) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 7

            ctx.setStrokeColor(NSColor.tertiaryLabelColor.cgColor)
            ctx.setLineWidth(2.5)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.strokePath()

            if progress > 0.001 {
                ctx.setStrokeColor(NSColor.controlAccentColor.cgColor)
                ctx.setLineWidth(2.5)
                ctx.setLineCap(.round)
                let startAngle = CGFloat.pi / 2
                let sweep = CGFloat(min(max(progress, 0), 1)) * 2 * .pi
                let endAngle = startAngle - sweep
                ctx.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                ctx.strokePath()
            }

            return true
        }
        image.isTemplate = false
        return image
    }
}
