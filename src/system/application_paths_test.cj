package sdl.system

import sdl.CuiException

@Test
func userFolderCodeMapsSdlValues(): Unit {
    @Expect(userFolderCode(UserFolder.Home), SDL_FOLDER_HOME)
    @Expect(userFolderCode(UserFolder.Desktop), SDL_FOLDER_DESKTOP)
    @Expect(userFolderCode(UserFolder.Documents), SDL_FOLDER_DOCUMENTS)
    @Expect(userFolderCode(UserFolder.Downloads), SDL_FOLDER_DOWNLOADS)
    @Expect(userFolderCode(UserFolder.Music), SDL_FOLDER_MUSIC)
    @Expect(userFolderCode(UserFolder.Pictures), SDL_FOLDER_PICTURES)
    @Expect(userFolderCode(UserFolder.PublicShare), SDL_FOLDER_PUBLICSHARE)
    @Expect(userFolderCode(UserFolder.SavedGames), SDL_FOLDER_SAVEDGAMES)
    @Expect(userFolderCode(UserFolder.Screenshots), SDL_FOLDER_SCREENSHOTS)
    @Expect(userFolderCode(UserFolder.Templates), SDL_FOLDER_TEMPLATES)
    @Expect(userFolderCode(UserFolder.Videos), SDL_FOLDER_VIDEOS)
}

@Test
func preferencePathRejectsEmptyLabels(): Unit {
    @Expect(preferencePathFails("", "Demo"))
    @Expect(preferencePathFails("CUI", ""))
}

@Test
func currentDirectoryReturnsPathLikeValue(): Unit {
    let path = ApplicationPaths.currentDirectory()

    @Expect(path.size > 0)
}

private func preferencePathFails(org: String, app: String): Bool {
    try {
        let _ = ApplicationPaths.preferencePath(org, app)
        false
    } catch (e: CuiException) {
        true
    }
}
