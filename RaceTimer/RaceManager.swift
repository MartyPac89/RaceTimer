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
    
    func updateRunnerGender(for runnerIndex: Int, gender: Gender?) {
        guard var race = currentRace, runnerIndex < race.runners.count else { return }
        race.runners[runnerIndex].gender = gender
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
    
    func updateCompletedRaceRunnerGender(for raceId: UUID, runnerId: UUID, gender: Gender?) {
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }),
              let runnerIndex = races[raceIndex].runners.firstIndex(where: { $0.id == runnerId }) else {
            return
        }
        
        var updatedRace = races[raceIndex]
        updatedRace.runners[runnerIndex].gender = gender
        races[raceIndex] = updatedRace
        saveRaces()
    }
    
    func updateCompletedRaceRunnersGender(for raceId: UUID, runnerIds: Set<UUID>, gender: Gender) {
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }), !runnerIds.isEmpty else {
            return
        }
        
        var updatedRace = races[raceIndex]
        for runnerId in runnerIds {
            guard let runnerIndex = updatedRace.runners.firstIndex(where: { $0.id == runnerId }) else {
                continue
            }
            updatedRace.runners[runnerIndex].gender = gender
        }
        races[raceIndex] = updatedRace
        saveRaces()
    }
    
    /// Amends a completed runner's finish time from an elapsed interval (seconds since race start).
    /// Recalculates finish places for the whole race. Returns false if the race/runner/start time is missing
    /// or the elapsed value is invalid.
    @discardableResult
    func updateCompletedRaceRunnerFinishTime(for raceId: UUID, runnerId: UUID, elapsedSeconds: TimeInterval) -> Bool {
        guard elapsedSeconds >= 0,
              let raceIndex = races.firstIndex(where: { $0.id == raceId }),
              let startTime = races[raceIndex].raceStartTime,
              let runnerIndex = races[raceIndex].runners.firstIndex(where: { $0.id == runnerId }) else {
            return false
        }
        
        var updatedRace = races[raceIndex]
        updatedRace.runners[runnerIndex].finishTime = startTime.addingTimeInterval(elapsedSeconds)
        
        let sortedRunners = updatedRace.sortedRunners
        for (index, runner) in sortedRunners.enumerated() {
            if let placeIndex = updatedRace.runners.firstIndex(where: { $0.id == runner.id }) {
                updatedRace.runners[placeIndex].finishPlace = index + 1
            }
        }
        
        races[raceIndex] = updatedRace
        saveRaces()
        return true
    }
    
    enum ExportListFilter {
        case all
        case women
        case men
        
        func filteredRunners(from race: Race) -> [Runner] {
            let sorted = race.sortedRunners
            switch self {
            case .all: return sorted
            case .women: return sorted.filter { $0.gender == .F }
            case .men: return sorted.filter { $0.gender == .M }
            }
        }
        
        var resultsSectionTitle: String {
            switch self {
            case .all: return "Kompletní výsledky"
            case .women: return "Výsledky žen"
            case .men: return "Výsledky mužů"
            }
        }
    }
    
    func generatePDF(for race: Race, filter: ExportListFilter = .all) -> Data? {
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
            drawRaceReport(race: race, filter: filter, in: pageRect, fillBackground: false)
        }
    }
    
    func generateJPEG(for race: Race, filter: ExportListFilter = .all) -> Data? {
        let pageRect = Self.reportPageRect
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { _ in
            drawRaceReport(race: race, filter: filter, in: pageRect, fillBackground: true)
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
    
    private func drawRaceReport(
        race: Race,
        filter: ExportListFilter,
        in pageRect: CGRect,
        fillBackground: Bool
    ) {
        let pageWidth = pageRect.width
        let margin: CGFloat = 36
        let contentWidth = pageWidth - margin * 2
        let sortedRunners = filter.filteredRunners(from: race)
        
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
            startY: cursorY + 8
        )
        
        // MARK: Results table
        cursorY = drawResultsTable(
            runners: sortedRunners,
            race: race,
            sectionTitle: filter.resultsSectionTitle,
            margin: margin,
            contentWidth: contentWidth,
            startY: cursorY + 12,
            pageBottom: pageRect.maxY - 58
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
        
        // Brand / logo — keep original aspect ratio inside a max box
        if let logoImage = UIImage(named: "logo") {
            let maxLogoSize = CGSize(width: 88, height: 44)
            let aspect = logoImage.size.width / max(logoImage.size.height, 1)
            var logoWidth = maxLogoSize.width
            var logoHeight = logoWidth / aspect
            if logoHeight > maxLogoSize.height {
                logoHeight = maxLogoSize.height
                logoWidth = logoHeight * aspect
            }
            logoImage.draw(in: CGRect(x: margin, y: y, width: logoWidth, height: logoHeight))
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
        
        // Right meta — distance + date (no time)
        let dateText = DateFormatter.localizedString(
            from: race.dateCreated,
            dateStyle: .medium,
            timeStyle: .none
        )
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
        
        // Accent line
        ReportPalette.forest.withAlphaComponent(0.35).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin + 40, y: y))
        line.addLine(to: CGPoint(x: pageWidth - margin - 40, y: y))
        line.lineWidth = 1
        line.stroke()
        
        return y + 6
    }
    
    private func drawPodiumSection(
        runners: [Runner],
        race: Race,
        margin: CGFloat,
        contentWidth: CGFloat,
        startY: CGFloat
    ) -> CGFloat {
        // Compact podium: 3rd place is minimal (place # + 2 text lines); 2nd/1st step up from that.
        let minBlockHeight: CGFloat = 52
        let slots: [(placeIndex: Int, xFactor: CGFloat, blockHeight: CGFloat, color: UIColor)] = [
            (1, 0.18, minBlockHeight + 10, ReportPalette.silver),
            (0, 0.50, minBlockHeight + 20, ReportPalette.gold),
            (2, 0.82, minBlockHeight, ReportPalette.bronze)
        ]
        let bottomPad: CGFloat = 8
        let topPad: CGFloat = 10
        let podiumHeight = (slots.map(\.blockHeight).max() ?? minBlockHeight) + bottomPad + topPad
        let podiumRect = CGRect(x: margin, y: startY, width: contentWidth, height: podiumHeight)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return startY + podiumHeight
        }
        
        context.saveGState()
        
        let path = UIBezierPath(roundedRect: podiumRect, cornerRadius: 12)
        path.addClip()
        drawVerticalGradient(
            in: podiumRect,
            colors: [
                UIColor(red: 0.72, green: 0.86, blue: 0.90, alpha: 1),
                UIColor(red: 0.78, green: 0.88, blue: 0.78, alpha: 1),
                UIColor(red: 0.90, green: 0.93, blue: 0.86, alpha: 1)
            ]
        )
        drawScenicBackdrop(in: podiumRect)
        
        for slot in slots {
            guard slot.placeIndex < runners.count else { continue }
            let runner = runners[slot.placeIndex]
            let place = slot.placeIndex + 1
            let blockWidth: CGFloat = 118
            let centerX = podiumRect.minX + contentWidth * slot.xFactor
            let blockY = podiumRect.maxY - bottomPad - slot.blockHeight
            let blockRect = CGRect(
                x: centerX - blockWidth / 2,
                y: blockY,
                width: blockWidth,
                height: slot.blockHeight
            )
            
            let blockPath = UIBezierPath(
                roundedRect: blockRect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: 8, height: 8)
            )
            slot.color.setFill()
            blockPath.fill()
            UIColor.white.withAlphaComponent(0.25).setStroke()
            blockPath.lineWidth = 1
            blockPath.stroke()
            
            let placeStyle = NSMutableParagraphStyle()
            placeStyle.alignment = .center
            let placeText = NSAttributedString(
                string: "\(place)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 18, weight: .black),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: placeStyle
                ]
            )
            placeText.draw(in: CGRect(x: blockRect.minX, y: blockRect.minY + 4, width: blockRect.width, height: 20))
            
            let label = podiumLabel(for: runner, race: race)
            let labelAttr = NSAttributedString(
                string: label,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: placeStyle
                ]
            )
            labelAttr.draw(in: CGRect(x: blockRect.minX + 4, y: blockRect.maxY - 26, width: blockRect.width - 8, height: 24))
        }
        
        context.restoreGState()
        
        UIColor.white.withAlphaComponent(0.8).setStroke()
        let border = UIBezierPath(roundedRect: podiumRect, cornerRadius: 12)
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
        let mountains = UIBezierPath()
        mountains.move(to: CGPoint(x: rect.minX, y: rect.midY + 8))
        mountains.addLine(to: CGPoint(x: rect.minX + 70, y: rect.minY + 12))
        mountains.addLine(to: CGPoint(x: rect.minX + 130, y: rect.midY + 4))
        mountains.addLine(to: CGPoint(x: rect.minX + 200, y: rect.minY + 16))
        mountains.addLine(to: CGPoint(x: rect.minX + 280, y: rect.midY))
        mountains.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 18))
        mountains.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        mountains.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        mountains.close()
        UIColor(red: 0.45, green: 0.58, blue: 0.52, alpha: 0.30).setFill()
        mountains.fill()
        
        let trees = UIBezierPath()
        trees.move(to: CGPoint(x: rect.minX, y: rect.maxY - 18))
        var x = rect.minX
        var up = true
        while x < rect.maxX {
            let peakY = rect.maxY - (up ? 36 : 26)
            trees.addLine(to: CGPoint(x: x + 16, y: peakY))
            trees.addLine(to: CGPoint(x: x + 32, y: rect.maxY - 18))
            x += 32
            up.toggle()
        }
        trees.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        trees.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        trees.close()
        UIColor(red: 0.22, green: 0.42, blue: 0.30, alpha: 0.40).setFill()
        trees.fill()
    }
    
    private func drawResultsTable(
        runners: [Runner],
        race: Race,
        sectionTitle: String,
        margin: CGFloat,
        contentWidth: CGFloat,
        startY: CGFloat,
        pageBottom: CGFloat
    ) -> CGFloat {
        let headers = ["#", "Číslo", "Jméno", "Pohlaví", "Čas", "Tempo"]
        let columnWidths: [CGFloat] = [
            contentWidth * 0.07,
            contentWidth * 0.12,
            contentWidth * 0.28,
            contentWidth * 0.10,
            contentWidth * 0.21,
            contentWidth * 0.22
        ]
        let headerHeight: CGFloat = 28
        let rowHeight: CGFloat = 24
        var y = startY
        
        // Section label
        let section = NSAttributedString(
            string: sectionTitle,
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
                runner.gender?.rawValue ?? "—",
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
        let footerTop = pageRect.maxY - 48
        
        ReportPalette.forest.withAlphaComponent(0.25).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: footerTop))
        line.addLine(to: CGPoint(x: margin + contentWidth, y: footerTop))
        line.lineWidth = 1
        line.stroke()
        
        let thanksStyle = NSMutableParagraphStyle()
        thanksStyle.alignment = .center
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
            x: margin + (contentWidth - badgeWidth) / 2,
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
