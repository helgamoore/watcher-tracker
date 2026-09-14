//
//  FolderWatcher.swift
//  WatcherTracker
//
//  Created by Helga Moore on 14/09/2026.
//

import Foundation

final class FolderWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    private var watchedURL: URL?
    private var hasSecurityScope = false

    func start(
        watching folderURL: URL,
        onChange: @escaping () -> Void
    ) {
        stop()

        watchedURL = folderURL

        hasSecurityScope =
            folderURL.startAccessingSecurityScopedResource()

        fileDescriptor = open(
            folderURL.path,
            O_EVTONLY
        )

        guard fileDescriptor >= 0 else {
            if hasSecurityScope {
                folderURL.stopAccessingSecurityScopedResource()
                hasSecurityScope = false
            }

            watchedURL = nil

            print("Unable to watch folder: \(folderURL.path)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [
                .write,
                .delete,
                .rename,
                .attrib,
                .extend
            ],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler {
            DispatchQueue.main.async {
                onChange()
            }
        }

        source.setCancelHandler { [fileDescriptor] in
            close(fileDescriptor)
        }

        self.source = source
        source.resume()
    }

    func stop() {
        source?.cancel()
        source = nil

        fileDescriptor = -1

        if hasSecurityScope,
           let watchedURL {
            watchedURL.stopAccessingSecurityScopedResource()
        }

        hasSecurityScope = false
        watchedURL = nil
    }

    deinit {
        stop()
    }
}
