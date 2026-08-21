package sdl.dialogs

import std.sync.Mutex

/**
 * The observed state of an asynchronous file dialog: still pending, canceled by the user,
 * completed with selected paths (plus the chosen filter index, when available), or failed with an error message.
 */
public enum FileDialogResult {
    | FileDialogPending
    | FileDialogCanceled
    | FileDialogSelected(Array<String>, ?Int32)
    | FileDialogFailed(String)
}

/** A single dialog filter entry: a display name plus a semicolon-separated extension pattern (e.g. "png;jpg"). */
public struct FileDialogFilter {
    public let name: String
    public let pattern: String

    public init(name: String, pattern: String) {
        this.name = name
        this.pattern = pattern
    }
}

/** Configuration for a file dialog: filter list, starting location, and whether multiple selection is allowed. */
public struct FileDialogOptions {
    public var filters: Array<FileDialogFilter>
    public var defaultLocation: ?String
    public var allowMany: Bool

    public init(
        filters!: Array<FileDialogFilter> = [],
        defaultLocation!: ?String = None,
        allowMany!: Bool = false
    ) {
        this.filters = filters
        this.defaultLocation = defaultLocation
        this.allowMany = allowMany
    }
}

/**
 * A handle to an in-flight native file dialog; poll `result()` or `isDone()` each frame
 * until the dialog callback delivers its outcome.
 */
public class FileDialogRequest {
    private let lock = Mutex()
    private var current = FileDialogResult.FileDialogPending
    private var nativeResources: ?FileDialogNativeResources
    internal let id: Int64

    internal init(id: Int64, nativeResources: FileDialogNativeResources) {
        this.id = id
        this.nativeResources = Some(nativeResources)
    }

    /** The current outcome of the dialog; `FileDialogPending` until the user finishes or cancels. */
    public func result(): FileDialogResult {
        var value = FileDialogResult.FileDialogPending
        synchronized(lock) {
            value = current
        }
        value
    }

    /** Whether the dialog has finished, i.e. `result()` is no longer `FileDialogPending`. */
    public func isDone(): Bool {
        match (result()) {
            case FileDialogResult.FileDialogPending => false
            case _ => true
        }
    }

    internal func complete(value: FileDialogResult): Unit {
        synchronized(lock) {
            current = value
        }
    }

    internal func userdata(): CPointer<Unit> {
        match (nativeResources) {
            case Some(resources) => resources.userdata()
            case None => CPointer<Unit>()
        }
    }

    internal func rawFilters(): CPointer<SdlDialogFileFilter> {
        match (nativeResources) {
            case Some(resources) => resources.rawFilters
            case None => CPointer<SdlDialogFileFilter>()
        }
    }

    internal func filterCount(): Int32 {
        match (nativeResources) {
            case Some(resources) => resources.filterCount
            case None => 0
        }
    }

    internal func defaultLocation(): CString {
        match (nativeResources) {
            case Some(resources) => resources.defaultLocation
            case None => nullDialogCString()
        }
    }

    internal func releaseNativeResources(): Unit {
        match (nativeResources) {
            case Some(resources) =>
                resources.close()
                nativeResources = None<FileDialogNativeResources>
            case None => ()
        }
    }
}
