ledger.managers ?= {}

OperatingSystems =
  Windows: "Windows"
  MacOS: "Mac OS"
  Linux: "Linux"
  Unix: "UNIX"
  Unknown: "Unknown"

class ledger.managers.System extends EventEmitter

  @OperatingSystems: OperatingSystems

  operatingSystemName: ->
    name = OperatingSystems.Unknown
    if navigator.appVersion.indexOf("Win") != -1
      name = OperatingSystems.Windows
    else if navigator.appVersion.indexOf("Mac") != -1
      name = OperatingSystems.MacOS
    else if navigator.appVersion.indexOf("Linux") != -1
      name = OperatingSystems.Linux
    else if navigator.appVersion.indexOf("X11") != -1
      name = OperatingSystems.Unix
    return name

  isWindows: -> @operatingSystemName() is OperatingSystems.Windows

  isMacOS: -> @operatingSystemName() is OperatingSystems.MacOS

  isLinux: -> @operatingSystemName() is OperatingSystems.Linux

  isUnix: -> @operatingSystemName() is OperatingSystems.Unix

  isUnknown: -> @operatingSystemName() is OperatingSystems.Unknown

ledger.managers.system = new ledger.managers.System()