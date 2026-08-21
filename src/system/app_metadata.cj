package sdl.system

import sdl.ensureSdl

/** Classifies the kind of application reported in SDL app metadata; `CustomMetadataType` carries an arbitrary type string. */
public enum AppMetadataType {
    | Application
    | Game
    | MediaPlayer
    | CustomMetadataType(String)
}

/** Identifies a well-known SDL app metadata property; `CustomMetadataProperty` addresses a property by raw name. */
public enum AppMetadataProperty {
    | Name
    | Version
    | Identifier
    | Creator
    | Copyright
    | Url
    | ApplicationType
    | CustomMetadataProperty(String)
}

/** Aggregates the application metadata values applied to SDL in one call. */
public struct AppMetadata {
    public var name: ?String
    public var version: ?String
    public var identifier: ?String
    public var creator: ?String
    public var copyright: ?String
    public var url: ?String
    public var appType: ?AppMetadataType

    public init(name!: ?String = None, version!: ?String = None, identifier!: ?String = None) {
        this.name = name
        this.version = version
        this.identifier = identifier
        this.creator = None
        this.copyright = None
        this.url = None
        this.appType = None
    }
}

/** Sets, updates, and queries the application metadata SDL exposes to the operating system. */
public class ApplicationMetadata {
    /**
     * Throws `SdlException` when SDL cannot apply application metadata.
     */
    public static func apply(metadata: AppMetadata): Unit {
        let cName = optionalMetadataCString(metadata.name)
        let cVersion = optionalMetadataCString(metadata.version)
        let cIdentifier = optionalMetadataCString(metadata.identifier)
        try {
            ensureSdl(unsafe { SDL_SetAppMetadata(cName, cVersion, cIdentifier) }, "SDL_SetAppMetadata")
            setOptionalMetadataProperty(AppMetadataProperty.Creator, metadata.creator)
            setOptionalMetadataProperty(AppMetadataProperty.Copyright, metadata.copyright)
            setOptionalMetadataProperty(AppMetadataProperty.Url, metadata.url)
            setOptionalMetadataType(metadata.appType)
        } finally {
            freeMetadataCString(cName)
            freeMetadataCString(cVersion)
            freeMetadataCString(cIdentifier)
        }
    }

    /**
     * Throws `SdlException` when SDL cannot set the metadata property.
     */
    public static func set(property: AppMetadataProperty, value: String): Unit {
        ensureMetadataName(appMetadataPropertyName(property))
        withMetadataStrings(property, value, hasValue: true)
    }

    /**
     * Throws `SdlException` when SDL cannot remove the metadata property.
     */
    public static func remove(property: AppMetadataProperty): Unit {
        ensureMetadataName(appMetadataPropertyName(property))
        withMetadataStrings(property, "", hasValue: false)
    }

    /**
     * Throws `SdlException` when the property name is empty.
     */
    public static func get(property: AppMetadataProperty): ?String {
        let name = appMetadataPropertyName(property)
        ensureMetadataName(name)
        let cName = unsafe { LibC.mallocCString(name) }
        var result: ?String = None<String>
        try (nameResource = cName.asResource()) {
            let value = unsafe { SDL_GetAppMetadataProperty(nameResource.value) }
            if (value.isNull()) {
                result = None<String>
            } else {
                result = Some(value.toString())
            }
        }
        result
    }
}
