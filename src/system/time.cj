package sdl.system

import sdl.ensureSdl

/** Describes the field order a locale prefers when formatting dates. */
public enum DateFormat {
    | YearMonthDay
    | DayMonthYear
    | MonthDayYear
    | UnknownDateFormat(Int32)
}

/** Describes whether a locale prefers 24-hour or 12-hour clock display. */
public enum ClockFormat {
    | TwentyFourHour
    | TwelveHour
    | UnknownClockFormat(Int32)
}

/** Identifies a day of the week, Sunday through Saturday. */
public enum Weekday {
    | Sunday
    | Monday
    | Tuesday
    | Wednesday
    | Thursday
    | Friday
    | Saturday
}

/** Reports the date and clock formats the current locale prefers. */
public struct DateTimeLocalePreferences {
    public let dateFormat: DateFormat
    public let clockFormat: ClockFormat

    public init(dateFormat: DateFormat, clockFormat: ClockFormat) {
        this.dateFormat = dateFormat
        this.clockFormat = clockFormat
    }
}

/** Holds the low and high 32-bit halves of a Windows FILETIME value. */
public struct WindowsFileTime {
    public let low: UInt32
    public let high: UInt32

    public init(low: UInt32, high: UInt32) {
        this.low = low
        this.high = high
    }
}

/** Represents a calendar date and time broken into fields, with an optional weekday and a UTC offset. */
public struct DateTimeParts {
    public var year: Int32 = 1970
    public var month: Int32 = 1
    public var day: Int32 = 1
    public var hour: Int32 = 0
    public var minute: Int32 = 0
    public var second: Int32 = 0
    public var nanosecond: Int32 = 0
    public var dayOfWeek: ?Weekday = None
    public var utcOffsetSeconds: Int32 = 0
}

/** Queries the realtime clock and converts between nanosecond timestamps and calendar representations. */
public class Time {
    /**
     * Throws `SdlException` when SDL cannot query the system realtime clock.
     */
    public static func currentNanoseconds(): Int64 {
        var ticks: Int64 = 0
        ensureSdl(unsafe { SDL_GetCurrentTime(inout ticks) }, "SDL_GetCurrentTime")
        ticks
    }

    /**
     * Throws `SdlException` when SDL cannot query or convert the system realtime clock.
     */
    public static func currentDateTime(local!: Bool = true): DateTimeParts {
        toDateTime(currentNanoseconds(), local: local)
    }

    /**
     * Throws `SdlException` when SDL cannot convert nanoseconds to calendar fields.
     */
    public static func toDateTime(nanoseconds: Int64, local!: Bool = true): DateTimeParts {
        var raw = SdlDateTime()
        ensureSdl(unsafe { SDL_TimeToDateTime(nanoseconds, inout raw, local) }, "SDL_TimeToDateTime")
        dateTimeFromRaw(raw)
    }

    /**
     * Throws `SdlException` when SDL cannot convert calendar fields to nanoseconds.
     */
    public static func toNanoseconds(parts: DateTimeParts): Int64 {
        var raw = dateTimeToRaw(parts)
        var ticks: Int64 = 0
        ensureSdl(unsafe { SDL_DateTimeToTime(inout raw, inout ticks) }, "SDL_DateTimeToTime")
        ticks
    }

    /** Converts a nanosecond timestamp to a Windows FILETIME value. */
    public static func toWindowsFileTime(nanoseconds: Int64): WindowsFileTime {
        var low: UInt32 = UInt32(0)
        var high: UInt32 = UInt32(0)
        unsafe { SDL_TimeToWindows(nanoseconds, inout low, inout high) }
        WindowsFileTime(low, high)
    }

    /** Converts a Windows FILETIME value to a nanosecond timestamp. */
    public static func fromWindowsFileTime(fileTime: WindowsFileTime): Int64 {
        unsafe { SDL_TimeFromWindows(fileTime.low, fileTime.high) }
    }

    /**
     * Throws `SdlException` when the requested year/month is invalid.
     */
    public static func daysInMonth(year: Int32, month: Int32): Int32 {
        let days = unsafe { SDL_GetDaysInMonth(year, month) }
        ensureNonNegative(days, "SDL_GetDaysInMonth")
    }

    /**
     * Throws `SdlException` when the requested date is invalid.
     */
    public static func dayOfYear(year: Int32, month: Int32, day: Int32): Int32 {
        let dayIndex = unsafe { SDL_GetDayOfYear(year, month, day) }
        ensureNonNegative(dayIndex, "SDL_GetDayOfYear")
    }

    /**
     * Throws `SdlException` when the requested date is invalid.
     */
    public static func dayOfWeek(year: Int32, month: Int32, day: Int32): Weekday {
        let dayIndex = unsafe { SDL_GetDayOfWeek(year, month, day) }
        ensureWeekday(dayIndex, "SDL_GetDayOfWeek")
    }

    /**
     * Throws `SdlException` when SDL cannot query locale date/time preferences.
     */
    public static func localePreferences(): DateTimeLocalePreferences {
        var dateFormat: Int32 = 0
        var timeFormat: Int32 = 0
        ensureSdl(unsafe { SDL_GetDateTimeLocalePreferences(inout dateFormat, inout timeFormat) },
            "SDL_GetDateTimeLocalePreferences")
        DateTimeLocalePreferences(dateFormatFromCode(dateFormat), clockFormatFromCode(timeFormat))
    }
}
