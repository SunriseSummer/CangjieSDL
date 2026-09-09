package sdl

import sdl.text.NativeInstalledFont

/** An application-supplied static face with explicit matching metadata. */
public struct FontFaceDefinition {
    public let source: FontSource
    public let weight: FontWeight
    public let italic: Bool
    public let widthClass: Int64

    public init(source: FontSource, weight!: FontWeight = FontWeight.normal, italic!: Bool = false,
        widthClass!: Int64 = 5) {
        if (widthClass < 1 || widthClass > 9) {
            throw IllegalArgumentException("Font width class must be 1..9")
        }
        this.source = source
        this.weight = weight
        this.italic = italic
        this.widthClass = widthClass
    }

    internal func native(): NativeInstalledFont {
        NativeInstalledFont(source.native(), "", "", if (italic) {
            Int32(2)
        } else {
            Int32(0)
        }, weight: weight.value, width: widthClass)
    }
}
