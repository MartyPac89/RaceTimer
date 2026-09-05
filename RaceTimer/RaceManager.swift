//
//  RaceManager.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import Foundation
import PDFKit
import UIKit

class RaceManager: ObservableObject {
    @Published var races: [Race] = []
    @Published var currentRace: Race?
    @Published var raceStartTime: Date?
    @Published var isRaceStarted = false
    
    private let userDefaults = UserDefaults.standard
    private let racesKey = "savedRaces"
    
    init() {
        loadRaces()
    }
    
    func startRace() {
        guard !isRaceStarted else { return }
        raceStartTime = Date()
        isRaceStarted = true
    }
    
    func createNewRace(name: String, distance: Double, numberOfRunners: Int) {
        // Always start clean so an abandoned race can't leak its clock into the next one.
        raceStartTime = nil
        isRaceStarted = false
        let race = Race(name: name, distance: distance, numberOfRunners: numberOfRunners)
        currentRace = race
    }
    
    /// Clears in-progress race state without saving. Safe to call repeatedly.
    func abandonCurrentRace() {
        currentRace = nil
        raceStartTime = nil
        isRaceStarted = false
    }
    
    func recordTime(for runnerIndex: Int) {
        guard var race = currentRace, runnerIndex < race.runners.count, let startTime = raceStartTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        race.runners[runnerIndex].finishTime = startTime.addingTimeInterval(elapsedTime)
        currentRace = race
    }
    
    func updateRunnerNumber(for runnerIndex: Int, number: String) {
        guard var race = currentRace, runnerIndex < race.runners.count else { return }
        race.runners[runnerIndex].runnerNumber = number
        currentRace = race
    }
    
    func updateRunnerName(for runnerIndex: Int, name: String) {
        guard var race = currentRace, runnerIndex < race.runners.count else { return }
        race.runners[runnerIndex].runnerName = name
        currentRace = race
    }
    
    func finishRace() {
        guard var race = currentRace else { return }
        
        race.isCompleted = true
        race.raceStartTime = raceStartTime
        
        let sortedRunners = race.sortedRunners
        for (index, runner) in sortedRunners.enumerated() {
            if let runnerIndex = race.runners.firstIndex(where: { $0.id == runner.id }) {
                race.runners[runnerIndex].finishPlace = index + 1
            }
        }
        
        races.append(race)
        currentRace = nil
        raceStartTime = nil
        isRaceStarted = false
        saveRaces()
    }
    
    func deleteRace(_ race: Race) {
        races.removeAll { $0.id == race.id }
        saveRaces()
    }
    
    func updateCompletedRaceName(for raceId: UUID, name: String) {
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }) else {
            return
        }
        
        var updatedRace = races[raceIndex]
        updatedRace.name = name
        races[raceIndex] = updatedRace
        saveRaces()
    }
    
    func updateCompletedRaceDistance(for raceId: UUID, distance: Double) {
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }), distance > 0 else {
            return
        }
        
        var updatedRace = races[raceIndex]
        updatedRace.distance = distance
        races[raceIndex] = updatedRace
        saveRaces()
    }
    
    func updateCompletedRaceRunnerNumber(for raceId: UUID, runnerId: UUID, number: String) {
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }),
              let runnerIndex = races[raceIndex].runners.firstIndex(where: { $0.id == runnerId }) else {
            return
        }
        
        var updatedRace = races[raceIndex]
        updatedRace.runners[runnerIndex].runnerNumber = number
        races[raceIndex] = updatedRace
        saveRaces()
    }
    
    func updateCompletedRaceRunnerName(for raceId: UUID, runnerId: UUID, name: String) {
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }),
              let runnerIndex = races[raceIndex].runners.firstIndex(where: { $0.id == runnerId }) else {
            return
        }
        
        var updatedRace = races[raceIndex]
        updatedRace.runners[runnerIndex].runnerName = name
        races[raceIndex] = updatedRace
        saveRaces()
    }
    
    func generatePDF(for race: Race) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "RaceTimer",
            kCGPDFContextAuthor: "RaceTimer App",
            kCGPDFContextTitle: race.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = Self.reportPageRect
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            drawRaceReport(race: race, in: pageRect, fillBackground: false)
        }
    }
    
    func generateJPEG(for race: Race) -> Data? {
        let pageRect = Self.reportPageRect
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { _ in
            drawRaceReport(race: race, in: pageRect, fillBackground: true)
        }
        return image.jpegData(compressionQuality: 0.92)
    }
    
    private static let reportPageRect = CGRect(x: 0, y: 0, width: 8.5 * 72.0, height: 11.0 * 72.0)
    
    private enum ReportPalette {
        static let navy = UIColor(red: 0.10, green: 0.16, blue: 0.28, alpha: 1)
        static let forest = UIColor(red: 0.18, green: 0.38, blue: 0.28, alpha: 1)
        static let mistTop = UIColor(red: 0.82, green: 0.90, blue: 0.86, alpha: 1)
        static let mistBottom = UIColor(red: 0.93, green: 0.95, blue: 0.92, alpha: 1)
        static let gold = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1)
        static let silver = UIColor(red: 0.68, green: 0.72, blue: 0.76, alpha: 1)
        static let bronze = UIColor(red: 0.72, green: 0.45, blue: 0.28, alpha: 1)
        static let softGold = UIColor(red: 0.96, green: 0.91, blue: 0.72, alpha: 1)
        static let softSilver = UIColor(red: 0.90, green: 0.92, blue: 0.94, alpha: 1)
        static let softBronze = UIColor(red: 0.95, green: 0.88, blue: 0.80, alpha: 1)
        static let rowAlt = UIColor(red: 0.96, green: 0.97, blue: 0.96, alpha: 1)
        static let muted = UIColor(red: 0.35, green: 0.40, blue: 0.45, alpha: 1)
    }
    
    private func drawRaceReport(race: Race, in pageRect: CGRect, fillBackground: Bool) {
        let pageWidth = pageRect.width
        let margin: CGFloat = 36
        let contentWidth = pageWidth - margin * 2
        let sortedRunners = race.sortedRunners
        
        if fillBackground {
            UIColor.white.setFill()
            UIRectFill(pageRect)
        }
        
        // Soft page wash
        drawVerticalGradient(
            in: pageRect,
            colors: [
                ReportPalette.mistTop.withAlphaComponent(0.55),
                UIColor.white,
                ReportPalette.mistBottom.withAlphaComponent(0.35)
            ]
        )
        
        var cursorY: CGFloat = 28
        
        // MARK: Header
        cursorY = drawReportHeader(
            race: race,
            margin: margin,
            contentWidth: contentWidth,
            startY: cursorY
        )
        
        // MARK: Podium (top 3)
        cursorY = drawPodiumSection(
            runners: Array(sortedRunners.prefix(3)),
            race: race,
            margin: margin,
            contentWidth: contentWidth,
            startY: cursorY + 10
        )
        
        // MARK: Results table
        cursorY = drawResultsTable(
            runners: sortedRunners,
            race: race,
            margin: margin,
            contentWidth: contentWidth,
            startY: cursorY + 16,
            pageBottom: pageRect.maxY - 70
        )
        
        // MARK: Footer
        drawReportFooter(
            margin: margin,
            contentWidth: contentWidth,
            pageRect: pageRect
        )
    }
    
    private func drawReportHeader(
        race: Race,
        margin: CGFloat,
        contentWidth: CGFloat,
        startY: CGFloat
    ) -> CGFloat {
        let pageWidth = margin * 2 + contentWidth
        var y = startY
        
        // Brand / logo
        if let logoImage = UIImage(named: "logo") {
            let logoSize = CGSize(width: 88, height: 44)
            logoImage.draw(in: CGRect(x: margin, y: y, width: logoSize.width, height: logoSize.height))
        } else {
            let brand = NSAttributedString(
                string: "RaceTimer",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: ReportPalette.forest
                ]
            )
            brand.draw(at: CGPoint(x: margin, y: y + 8))
        }
        
        // Right meta
        let dateText = DateFormatter.localizedString(from: race.dateCreated, dateStyle: .medium, timeStyle: .short)
        let meta = "\(String(format: "%.1f", race.distance)) km\n\(dateText)"
        let metaAttr = NSAttributedString(
            string: meta,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: ReportPalette.muted,
                .paragraphStyle: {
                    let p = NSMutableParagraphStyle()
                    p.alignment = .right
                    p.lineSpacing = 2
                    return p
                }()
            ]
        )
        let metaRect = CGRect(x: pageWidth - margin - 160, y: y + 4, width: 160, height: 36)
        metaAttr.draw(in: metaRect)
        
        y += 52
        
        // Main title
        let titleStyle = NSMutableParagraphStyle()
        titleStyle.alignment = .center
        let title = NSAttributedString(
            string: "VÝSLEDKOVÁ LISTINA",
            attributes: [
                .font: UIFont.systemFont(ofSize: 28, weight: .heavy),
                .foregroundColor: ReportPalette.navy,
                .paragraphStyle: titleStyle
            ]
        )
        title.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 34))
        y += 34
        
        let raceTitle = NSAttributedString(
            string: race.name.uppercased(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: ReportPalette.forest,
                .paragraphStyle: titleStyle
            ]
        )
        raceTitle.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 22))
        y += 22
        
        let subtitle = NSAttributedString(
            string: "Všichni běží, někdo zanechá stopu",
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: ReportPalette.muted,
                .paragraphStyle: titleStyle
            ]
        )
        subtitle.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 16))
        y += 18
        
        // Accent line
        ReportPalette.forest.withAlphaComponent(0.35).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin + 40, y: y))
        line.addLine(to: CGPoint(x: pageWidth - margin - 40, y: y))
        line.lineWidth = 1
        line.stroke()
        
        return y + 8
    }
    
    private func drawPodiumSection(
        runners: [Runner],
        race: Race,
        margin: CGFloat,
        contentWidth: CGFloat,
        startY: CGFloat
    ) -> CGFloat {
        let podiumHeight: CGFloat = 168
        let podiumRect = CGRect(x: margin, y: startY, width: contentWidth, height: podiumHeight)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return startY + podiumHeight
        }
        
        context.saveGState()
        
        // Scenic backdrop
        let path = UIBezierPath(roundedRect: podiumRect, cornerRadius: 16)
        path.addClip()
        drawVerticalGradient(
            in: podiumRect,
            colors: [
                UIColor(red: 0.72, green: 0.86, blue: 0.90, alpha: 1),
                UIColor(red: 0.78, green: 0.88, blue: 0.78, alpha: 1),
                UIColor(red: 0.90, green: 0.93, blue: 0.86, alpha: 1)
            ]
        )
        
        // Soft hills / trees suggestion
        drawScenicBackdrop(in: podiumRect)
        
        // Sun
        let sunCenter = CGPoint(x: podiumRect.midX + 110, y: podiumRect.minY + 28)
        UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.85).setFill()
        UIBezierPath(ovalIn: CGRect(x: sunCenter.x - 16, y: sunCenter.y - 16, width: 32, height: 32)).fill()
        
        // Podium order visually: 2 | 1 | 3
        let slots: [(placeIndex: Int, xFactor: CGFloat, blockHeight: CGFloat, color: UIColor)] = [
            (1, 0.18, 58, ReportPalette.silver),
            (0, 0.50, 78, ReportPalette.gold),
            (2, 0.82, 48, ReportPalette.bronze)
        ]
        
        for slot in slots {
            guard slot.placeIndex < runners.count else { continue }
            let runner = runners[slot.placeIndex]
            let place = slot.placeIndex + 1
            let blockWidth: CGFloat = 118
            let centerX = podiumRect.minX + contentWidth * slot.xFactor
            let blockY = podiumRect.maxY - 18 - slot.blockHeight
            let blockRect = CGRect(
                x: centerX - blockWidth / 2,
                y: blockY,
                width: blockWidth,
                height: slot.blockHeight
            )
            
            // Runner silhouette above block
            let symbolName = place == 1 ? "figure.arms.open" : "figure.run"
            let tint = ReportPalette.navy.withAlphaComponent(0.85)
            let iconSize: CGFloat = place == 1 ? 46 : 40
            let icon = symbolImage(named: symbolName, pointSize: iconSize, color: tint)
                ?? symbolImage(named: "figure.run", pointSize: iconSize, color: tint)
            if let icon {
                let iconRect = CGRect(
                    x: centerX - iconSize / 2,
                    y: blockY - iconSize - 8,
                    width: iconSize,
                    height: iconSize
                )
                icon.draw(in: iconRect)
            }
            
            // Podium block
            let blockPath = UIBezierPath(
                roundedRect: blockRect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: 10, height: 10)
            )
            slot.color.setFill()
            blockPath.fill()
            UIColor.white.withAlphaComponent(0.25).setStroke()
            blockPath.lineWidth = 1
            blockPath.stroke()
            
            // Place number
            let placeStyle = NSMutableParagraphStyle()
            placeStyle.alignment = .center
            let placeText = NSAttributedString(
                string: "\(place)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 22, weight: .black),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: placeStyle
                ]
            )
            placeText.draw(in: CGRect(x: blockRect.minX, y: blockRect.minY + 8, width: blockRect.width, height: 26))
            
            // Name + time on block
            let label = podiumLabel(for: runner, race: race)
            let labelAttr = NSAttributedString(
                string: label,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: placeStyle
                ]
            )
            labelAttr.draw(in: CGRect(x: blockRect.minX + 4, y: blockRect.maxY - 28, width: blockRect.width - 8, height: 24))
        }
        
        context.restoreGState()
        
        // Subtle border around podium card
        UIColor.white.withAlphaComponent(0.8).setStroke()
        let border = UIBezierPath(roundedRect: podiumRect, cornerRadius: 16)
        border.lineWidth = 1.5
        border.stroke()
        
        return startY + podiumHeight
    }
    
    private func podiumLabel(for runner: Runner, race: Race) -> String {
        let name: String
        if !runner.runnerName.isEmpty {
            name = runner.runnerName
        } else if !runner.runnerNumber.isEmpty {
            name = "#\(runner.runnerNumber)"
        } else {
            name = "Běžec"
        }
        let time = formatTimeForPDF(runner.finishTime, raceStartTime: race.raceStartTime)
        return "\(name)\n\(time)"
    }
    
    private func drawScenicBackdrop(in rect: CGRect) {
        // Far mountains
        let mountains = UIBezierPath()
        mountains.move(to: CGPoint(x: rect.minX, y: rect.midY + 20))
        mountains.addLine(to: CGPoint(x: rect.minX + 70, y: rect.minY + 40))
        mountains.addLine(to: CGPoint(x: rect.minX + 130, y: rect.midY + 10))
        mountains.addLine(to: CGPoint(x: rect.minX + 200, y: rect.minY + 50))
        mountains.addLine(to: CGPoint(x: rect.minX + 280, y: rect.midY))
        mountains.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 55))
        mountains.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        mountains.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        mountains.close()
        UIColor(red: 0.45, green: 0.58, blue: 0.52, alpha: 0.35).setFill()
        mountains.fill()
        
        // Near treeline
        let trees = UIBezierPath()
        trees.move(to: CGPoint(x: rect.minX, y: rect.maxY - 40))
        var x = rect.minX
        var up = true
        while x < rect.maxX {
            let peakY = rect.maxY - (up ? 70 : 52)
            trees.addLine(to: CGPoint(x: x + 18, y: peakY))
            trees.addLine(to: CGPoint(x: x + 36, y: rect.maxY - 40))
            x += 36
            up.toggle()
        }
        trees.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        trees.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        trees.close()
        UIColor(red: 0.22, green: 0.42, blue: 0.30, alpha: 0.45).setFill()
        trees.fill()
    }
    
    private func drawResultsTable(
        runners: [Runner],
        race: Race,
        margin: CGFloat,
        contentWidth: CGFloat,
        startY: CGFloat,
        pageBottom: CGFloat
    ) -> CGFloat {
        let headers = ["#", "Číslo", "Jméno", "Čas", "Tempo"]
        let columnWidths: [CGFloat] = [
            contentWidth * 0.08,
            contentWidth * 0.14,
            contentWidth * 0.34,
            contentWidth * 0.22,
            contentWidth * 0.22
        ]
        let headerHeight: CGFloat = 28
        let rowHeight: CGFloat = 24
        var y = startY
        
        // Section label
        let section = NSAttributedString(
            string: "Kompletní výsledky",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: ReportPalette.navy
            ]
        )
        section.draw(at: CGPoint(x: margin, y: y))
        y += 20
        
        // Header bar
        let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: headerHeight)
        let headerPath = UIBezierPath(roundedRect: headerRect, cornerRadius: 8)
        ReportPalette.navy.setFill()
        headerPath.fill()
        
        var x = margin + 8
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        for (index, header) in headers.enumerated() {
            NSAttributedString(string: header, attributes: headerAttrs)
                .draw(in: CGRect(x: x, y: y + 7, width: columnWidths[index] - 6, height: 14))
            x += columnWidths[index]
        }
        y += headerHeight + 4
        
        let maxRows = max(0, Int((pageBottom - y) / rowHeight))
        let visibleRunners = Array(runners.prefix(maxRows))
        
        for (index, runner) in visibleRunners.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: contentWidth, height: rowHeight)
            
            let fill: UIColor
            switch index {
            case 0: fill = ReportPalette.softGold
            case 1: fill = ReportPalette.softSilver
            case 2: fill = ReportPalette.softBronze
            default: fill = index.isMultiple(of: 2) ? ReportPalette.rowAlt : UIColor.white
            }
            fill.setFill()
            UIBezierPath(roundedRect: rowRect, cornerRadius: 4).fill()
            
            let textColor = ReportPalette.navy
            let font = UIFont.systemFont(ofSize: 11, weight: index < 3 ? .semibold : .regular)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            
            let values = [
                "\(index + 1)",
                runner.runnerNumber.isEmpty ? "—" : runner.runnerNumber,
                runner.runnerName.isEmpty ? "—" : runner.runnerName,
                formatTimeForPDF(runner.finishTime, raceStartTime: race.raceStartTime),
                formatPaceForPDF(runner.finishTime, raceStartTime: race.raceStartTime, distance: race.distance)
            ]
            
            x = margin + 8
            for (col, value) in values.enumerated() {
                NSAttributedString(string: value, attributes: attrs)
                    .draw(in: CGRect(x: x, y: y + 5, width: columnWidths[col] - 6, height: 14))
                x += columnWidths[col]
            }
            
            y += rowHeight + 2
        }
        
        if runners.count > visibleRunners.count {
            let more = NSAttributedString(
                string: "+ dalších \(runners.count - visibleRunners.count) běžců v aplikaci",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                    .foregroundColor: ReportPalette.muted
                ]
            )
            more.draw(at: CGPoint(x: margin, y: y + 4))
            y += 18
        }
        
        return y
    }
    
    private func drawReportFooter(margin: CGFloat, contentWidth: CGFloat, pageRect: CGRect) {
        let footerTop = pageRect.maxY - 58
        
        ReportPalette.forest.withAlphaComponent(0.25).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: footerTop))
        line.addLine(to: CGPoint(x: margin + contentWidth, y: footerTop))
        line.lineWidth = 1
        line.stroke()
        
        let left = NSAttributedString(
            string: "Běháme pro lepší zítřky",
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: ReportPalette.forest
            ]
        )
        left.draw(at: CGPoint(x: margin, y: footerTop + 12))
        
        let thanksStyle = NSMutableParagraphStyle()
        thanksStyle.alignment = .right
        let thanks = NSAttributedString(
            string: "Děkujeme, že jste běželi s námi!",
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: thanksStyle
            ]
        )
        let badgeWidth: CGFloat = 230
        let badgeRect = CGRect(
            x: margin + contentWidth - badgeWidth,
            y: footerTop + 8,
            width: badgeWidth,
            height: 28
        )
        let badge = UIBezierPath(roundedRect: badgeRect, cornerRadius: 14)
        ReportPalette.forest.setFill()
        badge.fill()
        thanks.draw(in: badgeRect.insetBy(dx: 12, dy: 6))
    }
    
    private func drawVerticalGradient(in rect: CGRect, colors: [UIColor]) {
        guard let context = UIGraphicsGetCurrentContext(), colors.count >= 2 else { return }
        let cgColors = colors.map { $0.cgColor } as CFArray
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: cgColors,
            locations: nil
        ) else { return }
        
        context.saveGState()
        context.addRect(rect)
        context.clip()
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
        context.restoreGState()
    }
    
    private func symbolImage(named name: String, pointSize: CGFloat, color: UIColor) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        return UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }
    
    private func formatTimeForPDF(_ finishTime: Date?, raceStartTime: Date?) -> String {
        guard let finishTime = finishTime, let startTime = raceStartTime else {
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func formatPaceForPDF(_ finishTime: Date?, raceStartTime: Date?, distance: Double) -> String {
        guard let finishTime = finishTime, let startTime = raceStartTime, distance > 0 else {
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        let pacePerKm = elapsedTime / distance
        
        let minutes = Int(pacePerKm) / 60
        let seconds = Int(pacePerKm) % 60
        let milliseconds = Int((pacePerKm.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func saveRaces() {
        if let encoded = try? JSONEncoder().encode(races) {
            userDefaults.set(encoded, forKey: racesKey)
        }
    }
    
    private func loadRaces() {
        if let data = userDefaults.data(forKey: racesKey),
           let decoded = try? JSONDecoder().decode([Race].self, from: data) {
            races = decoded
        }
    }
}
