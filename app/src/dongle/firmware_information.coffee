
@ledger ||= {}
@ledger.dongle ||= {}

Firmwares =
  V_B_1_4_11: 0x0001040b
  V_B_1_4_12: 0x0001040c
  V_B_1_4_13: 0x0001040d
  V_L_1_0_0: 0x20010000
  V_L_1_0_1: 0x20010001
  V_L_1_0_2: 0x20010002
  V_L_1_1_0: 0x20010100

@ledger.dongle.Firmwares = Firmwares

###

###
class ledger.dongle.FirmwareInformation

  constructor: (dongle, @version) ->
    @_dongle = dongle

  hasSwappedBip39SetupSupport: -> @hasSubFirmwareSupport() # @getFirmwareModeFlag() & 0x04

  hasSetupFirmwareSupport: -> @getFirmwareModeFlag() & 0x01

  hasOperationFirmwareSupport: -> @getFirmwareModeFlag() & 0x02

  hasSubFirmwareSupport: -> @getIntFirmwareVersion() >= Firmwares.V_L_1_1_0

  getFirmwareModeFlag: -> if @version.length > 7 then @version.byteAt(7) else 0x00

  getIntFirmwareVersion: -> @getArchitecture() << 24 | @getIntSemanticFirmwareVersion()

  getStringFirmwareVersion: -> "#{@getIntFirmwareMajorVersion()}.#{@getIntFirmwareMinorVersion()}.#{@getIntFirmwarePatchVersion()}"

  getFeaturesFlag: -> @version.byteAt(0)

  getArchitecture: -> @version.byteAt(1)

  getIntFirmwareMajorVersion: -> @version.byteAt(2)

  getIntFirmwareMinorVersion: -> @version.byteAt(3)

  getIntFirmwarePatchVersion: -> @version.byteAt(4)

  getIntSemanticFirmwareVersion: -> @getIntFirmwareMajorVersion() << 16 | @getIntFirmwareMinorVersion() << 8 | @getIntFirmwarePatchVersion()

  isUsingDeprecatedBip32Derivation: -> @version.byteAt(2) is 0x01 and @version.byteAt(3) is 0x04 and @version.byteAt(4) < 7

  isUsingDeprecatedSetupKeymap: -> @version.byteAt(2) is 0x01 and @version.byteAt(3) is 0x04 and @version.byteAt(4) < 8

  hasCompressedPublicKeysSupport: -> @getFeaturesFlag() & 0x01

  hasSecureScreen2FASupport: -> @getIntFirmwareVersion() >= Firmwares.V_L_1_0_0

  hasRecoveryFlashingSupport: -> @getIntFirmwareVersion() >= Firmwares.V_L_1_1_0

  isUsingInputFinalizeFull: -> @getIntFirmwareVersion() >= Firmwares.V_L_1_0_2