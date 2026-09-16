//
//  ReportHistoryView.swift
//  WatcherTracker
//
//  Created by Helga Moore on 16/09/2026.
//

import SwiftUI
import AppKit

struct ReportHistoryView: View {
    @State private var reports: [Date: WatcherReport] = [:]
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var selectedReport: WatcherReport?
    @State private var errorMessage: String?

    private let archive = WatcherArchive()
    private let bookmarkStore = BookmarkStore()

    private let calendar = Calendar.current

    private let columns = Array(
        repeating: GridItem(.flexible()),
        count: 7
    )

    var body: some View {
        HStack(spacing: 0) {

            calendarPanel
                .frame(minWidth: 430)

            Divider()

            reportPanel
                .frame(minWidth: 420)
        }
        .frame(
            minWidth: 900,
            minHeight: 600
        )
        .onAppear {
            loadReports()
        }
    }

    // MARK: - Calendar

    private var calendarPanel: some View {
        VStack(spacing: 16) {

            calendarHeader

            weekdayHeader

            LazyVGrid(
                columns: columns,
                spacing: 8
            ) {
                ForEach(calendarDays.indices, id: \.self) { index in

                    if let date = calendarDays[index] {
                        dayView(date)
                    } else {
                        Color.clear
                            .frame(height: 42)
                    }
                }
            }

            Spacer()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }

    private var calendarHeader: some View {
        HStack {

            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!canMovePrevious)

            Spacer()

            Text(monthTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!canMoveNext)
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(
            columns: columns,
            spacing: 8
        ) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dayView(_ date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let report = reports[day]

        Button {
            if let report {
                selectedDate = day
                selectedReport = report
            }
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .frame(
                    maxWidth: .infinity,
                    minHeight: 42
                )
                .background {
                    if report != nil {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.tint.opacity(0.20))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    }
                }
                .overlay {
                    if selectedDate == day {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color.accentColor,
                                lineWidth: 2
                            )
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(report == nil)
        .foregroundStyle(
            report == nil
            ? .secondary
            : .primary
        )
        .help(
            report == nil
            ? "No report for this day"
            : "Open report"
        )
    }

    // MARK: - Report

    private var reportPanel: some View {
        Group {
            if let selectedReport {
                reportContent(selectedReport)
            } else {
                ContentUnavailableView(
                    "Select a Report",
                    systemImage: "calendar",
                    description: Text(
                        "Choose a highlighted day in the calendar."
                    )
                )
            }
        }
    }

    private func reportContent(
        _ report: WatcherReport
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            Text(
                report.date.formatted(
                    date: .long,
                    time: .omitted
                )
            )
            .font(.title2)

            HStack(spacing: 24) {
                Label(
                    "\(report.added.count) added",
                    systemImage: "plus"
                )

                Label(
                    "\(report.removed.count) removed",
                    systemImage: "minus"
                )

                Label(
                    "\(report.total) total",
                    systemImage: "person.2"
                )
            }

            Divider()

            HStack(alignment: .top) {

                VStack(alignment: .leading) {
                    Text("Added Watchers")
                        .font(.headline)

                    List(
                        report.added,
                        id: \.self
                    ) { watcher in
                        profileLink(watcher)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Removed Watchers")
                        .font(.headline)

                    List(
                        report.removed,
                        id: \.self
                    ) { watcher in
                        profileLink(watcher)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Calendar Calculations

    private var calendarDays: [Date?] {
        guard let monthInterval =
            calendar.dateInterval(
                of: .month,
                for: displayedMonth
            )
        else {
            return []
        }

        let firstDay = monthInterval.start

        let numberOfDays =
            calendar.range(
                of: .day,
                in: .month,
                for: firstDay
            )?.count ?? 0

        let firstWeekday =
            calendar.component(
                .weekday,
                from: firstDay
            )

        let leadingEmptyDays =
            (firstWeekday - calendar.firstWeekday + 7) % 7

        var days =
            Array<Date?>(
                repeating: nil,
                count: leadingEmptyDays
            )

        for day in 0..<numberOfDays {
            if let date = calendar.date(
                byAdding: .day,
                value: day,
                to: firstDay
            ) {
                days.append(date)
            }
        }

        return days
    }

    private var weekdaySymbols: [String] {
        let symbols =
            calendar.veryShortStandaloneWeekdaySymbols

        let index =
            calendar.firstWeekday - 1

        return Array(
            symbols[index...] +
            symbols[..<index]
        )
    }

    private var monthTitle: String {
        displayedMonth.formatted(
            .dateTime
                .month(.wide)
                .year()
        )
    }

    // MARK: - Range

    private var firstReportDate: Date? {
        reports.keys.min()
    }

    private var lastReportDate: Date? {
        reports.keys.max()
    }

    private var canMovePrevious: Bool {
        guard let firstReportDate else {
            return false
        }

        return monthStart(displayedMonth) >
            monthStart(firstReportDate)
    }

    private var canMoveNext: Bool {
        guard let lastReportDate else {
            return false
        }

        return monthStart(displayedMonth) <
            monthStart(lastReportDate)
    }

    private func moveMonth(by value: Int) {
        guard let newMonth = calendar.date(
            byAdding: .month,
            value: value,
            to: displayedMonth
        ) else {
            return
        }

        displayedMonth = newMonth
    }

    private func monthStart(_ date: Date) -> Date {
        calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: date
            )
        ) ?? date
    }

    // MARK: - Loading

    private func loadReports() {
        guard let archiveFolderURL =
            bookmarkStore.loadArchiveFolder()
        else {
            errorMessage =
                "Archive folder is not available."
            return
        }

        let accessGranted =
            archiveFolderURL
                .startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                archiveFolderURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {
            reports =
                try archive.reports(
                    in: archiveFolderURL
                )

            errorMessage = nil

            if let lastDate = lastReportDate {
                displayedMonth = lastDate
                selectedDate = lastDate
                selectedReport = reports[lastDate]
            }

        } catch {
            errorMessage =
                "Loading report history error: \(error.localizedDescription)"
        }
    }
    
    @ViewBuilder
    private func profileLink(_ username: String) -> some View {
        if let encoded = username.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ),
           let url = URL(
            string: "https://www.deviantart.com/\(encoded)"
           ) {

            Link(destination: url) {
                Text(username)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.link)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }

        } else {
            Text(username)
        }
    }
}
