package sdl.system

import sdl.{SdlException, lastSdlError}

/** Names a standard per-user folder that SDL can locate on the current platform. */
public enum UserFolder {
    | Home
    | Desktop
    | Documents
    | Downloads
    | Music
    | Pictures
    | PublicShare
    | SavedGames
    | Screenshots
    | Templates
    | Videos
}

/** Resolves well-known filesystem locations (base, preference, user folders) through SDL. */
public class ApplicationPaths {
    /** Returns the directory containing the application binary, or `None` when SDL cannot determine it. */
    public static func basePath(): ?String {
        borrowedPath(unsafe { SDL_GetBasePath() })
    }

    /**
     * Throws `SdlException` when SDL cannot resolve the current directory.
     */
    public static func currentDirectory(): String {
        ownedPath(unsafe { SDL_GetCurrentDirectory() }, "SDL_GetCurrentDirectory")
    }

    /**
     * Throws `SdlException` when org/app is empty or SDL cannot create the preference directory.
     */
    public static func preferencePath(org: String, app: String): String {
        ensurePathLabel(org, "Organization")
        ensurePathLabel(app, "Application")

        let cOrg = unsafe { LibC.mallocCString(org) }
        let cApp = unsafe { LibC.mallocCString(app) }
        var path = ""
        try (orgResource = cOrg.asResource()) {
            try (appResource = cApp.asResource()) {
                path = ownedPath(unsafe { SDL_GetPrefPath(orgResource.value, appResource.value) }, "SDL_GetPrefPath")
            }
        }
        path
    }

    /** Returns the path of the requested user folder, or `None` when the platform has no such folder. */
    public static func userFolder(folder: UserFolder): ?String {
        borrowedPath(unsafe { SDL_GetUserFolder(userFolderCode(folder)) })
    }
}

internal func userFolderCode(folder: UserFolder): Int32 {
    match (folder) {
        case UserFolder.Home => SDL_FOLDER_HOME
        case UserFolder.Desktop => SDL_FOLDER_DESKTOP
        case UserFolder.Documents => SDL_FOLDER_DOCUMENTS
        case UserFolder.Downloads => SDL_FOLDER_DOWNLOADS
        case UserFolder.Music => SDL_FOLDER_MUSIC
        case UserFolder.Pictures => SDL_FOLDER_PICTURES
        case UserFolder.PublicShare => SDL_FOLDER_PUBLICSHARE
        case UserFolder.SavedGames => SDL_FOLDER_SAVEDGAMES
        case UserFolder.Screenshots => SDL_FOLDER_SCREENSHOTS
        case UserFolder.Templates => SDL_FOLDER_TEMPLATES
        case UserFolder.Videos => SDL_FOLDER_VIDEOS
    }
}

private func borrowedPath(path: CString): ?String {
    if (path.isNull()) {
        None
    } else {
        Some(path.toString())
    }
}

/**
 * Throws `SdlException` when SDL returns a null owned path.
 */
private func ownedPath(path: CString, api: String): String {
    if (path.isNull()) {
        throw SdlException("${api} failed: ${lastSdlError()}")
    }
    let value = path.toString()
    unsafe { SDL_free(path.getChars()) }
    value
}

/**
 * Throws `SdlException` when a preference path label is empty.
 */
private func ensurePathLabel(value: String, name: String): Unit {
    if (value.size <= 0) {
        throw SdlException("${name} name cannot be empty.")
    }
}
