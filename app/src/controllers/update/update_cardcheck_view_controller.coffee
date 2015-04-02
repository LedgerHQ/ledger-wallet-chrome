class @UpdateCardcheckViewController extends UpdateViewController

  localizablePageSubtitle: "update.cardcheck.security_card_check"
  localizablePreviousButton: "common.back"
  navigation:
    nextRoute: ""
    previousRoute: "/update/seed"
  view:
    value1: "#value1"
    value2: "#value2"
    value3: "#value3"
    value4: "#value4"

  onAfterRender: ->
    super
    @_generateCharacters()

  navigateNext: ->
    @getRequest().setKeyCardSeed(@params.seed)

  navigatePrevious: ->
    @navigation.previousParams = {seed: @params.seed}
    super

  _generateCharacters: ->
    return if not @params?.seed?
    keycard = ledger.keycard.generateKeycardFromSeed(@params.seed)
    @view.value1.text keycard['3'].toUpperCase()
    @view.value2.text keycard['4'].toUpperCase()
    @view.value3.text keycard['5'].toUpperCase()
    @view.value4.text keycard['6'].toUpperCase()