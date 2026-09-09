package sdl.dialogs

import sdl.SdlWindow

/**
 * Entry points for asynchronous native file dialogs (open file, save file, open folder);
 * each call returns immediately with a `FileDialogRequest` to poll per frame.
 */
public class FileDialogs {
    /**
     * Throws `SdlException` when dialog options are invalid.
     */
    public static func openFile(
        options!: FileDialogOptions = FileDialogOptions(),
        window!: ?SdlWindow = None
    ): FileDialogRequest {
        let parent = parentWindowPtr(window)
        let request = createFileDialogRequest(options)
        unsafe {
            SDL_ShowOpenFileDialog(cuiFileDialogCallback, request.userdata(), parent, request.rawFilters(),
                request.filterCount(), request.defaultLocation(), options.allowMany)
        }
        request
    }

    /**
     * Throws `SdlException` when dialog options are invalid.
     */
    public static func saveFile(
        options!: FileDialogOptions = FileDialogOptions(),
        window!: ?SdlWindow = None
    ): FileDialogRequest {
        let parent = parentWindowPtr(window)
        let request = createFileDialogRequest(options)
        unsafe {
            SDL_ShowSaveFileDialog(cuiFileDialogCallback, request.userdata(), parent, request.rawFilters(),
                request.filterCount(), request.defaultLocation())
        }
        request
    }

    /**
     * Throws `SdlException` when dialog options are invalid.
     */
    public static func openFolder(
        options!: FileDialogOptions = FileDialogOptions(),
        window!: ?SdlWindow = None
    ): FileDialogRequest {
        let parent = parentWindowPtr(window)
        let request = createFileDialogRequest(options)
        unsafe {
            SDL_ShowOpenFolderDialog(cuiFileDialogCallback, request.userdata(), parent, request.defaultLocation(),
                options.allowMany)
        }
        request
    }
}
