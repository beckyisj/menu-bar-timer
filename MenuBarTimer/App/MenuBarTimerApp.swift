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
        popover.contentSize = NSSize(width: 320, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        timerManager.onTick = { [weak self] progress, text in
            DispatchQueue.main.async {
                self?.updateIcon(progress: progress, text: text)
            }
        }

        timerManager.onFocusNudge = { [weak self] in
            DispatchQueue.main.async {
                self?.showNudge()
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

    private func showNudge() {
        guard let button = statusItem.button, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
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

            // Outer ring
            ctx.setStrokeColor(NSColor.labelColor.cgColor)
            ctx.setLineWidth(1.5)
            ctx.addArc(center: center, radius: 7.5, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.strokePath()

            // Inner ring
            ctx.setLineWidth(1.2)
            ctx.addArc(center: center, radius: 4, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.strokePath()

            // Center dot
            ctx.setFillColor(NSColor.labelColor.cgColor)
            ctx.addArc(center: center, radius: 1.5, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.fillPath()

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
            let radius: CGFloat = 7.5

            // Background circle (subtle track)
            ctx.setFillColor(NSColor.tertiaryLabelColor.withAlphaComponent(0.2).cgColor)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.fillPath()

            if progress > 0.001 {
                // Filled pie/wedge — teal color for visibility
                let teal = NSColor(red: 0.2, green: 0.75, blue: 0.7, alpha: 1.0)
                ctx.setFillColor(teal.cgColor)
                let startAngle = CGFloat.pi / 2
                let sweep = CGFloat(min(max(progress, 0), 1)) * 2 * .pi
                let endAngle = startAngle - sweep
                ctx.move(to: center)
                ctx.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                ctx.closePath()
                ctx.fillPath()
            }

            return true
        }
        image.isTemplate = false
        return image
    }
}
