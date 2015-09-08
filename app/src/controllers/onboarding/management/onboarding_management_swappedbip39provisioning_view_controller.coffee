class @OnboardingManagementSwappedbip39provisioningViewController extends @OnboardingViewController

  onAfterRender: ->
    super

    # Important part

    ledger.app.dongle.setupFinalizeBip39().then =>
      # Next step flash the dongle in operation firmware
      ledger.app.router.go '/onboarding/management/switch_firmware', _.extend(_.clone(@params), mode: 'operation', pin: @params.pin, on_done: '/onboarding/management/done')
    .fail =>
      # Display Error (Need unplug)
      e "FATAL ERROR SETUP", arguments
    # !Important part


    $('.nyan').click @togglePlay
    deferredTimer = ledger.defer()
    @_countDownInterval = setInterval @_countDown.bind(this), 1000
    @_startTime = new Date().getTime()
    @_timer = deferredTimer.promise
    `
        console.log('Nyan!');

        var NyanCat = function () {
            return {
                init: function () {
                    this.cat = $('#nyan-cat');
                    this.framesAmount = 6;
                    this.currentFrame = 1;
                },

                cycleFrames: function () {
                    var myself = this;
                    this.cat.removeClass('frame' + myself.currentFrame).addClass('frame' + myself.cycleIds(myself.currentFrame));
                    this.currentFrame = this.cycleIds(this.currentFrame);
                },

                cycleIds: function (_currId) {
                    if (_currId >= this.framesAmount) {
                        _currId = 1;
                    } else {
                        _currId += 1;
                    }

                    return _currId;
                }
            }
        }

        var Sparks = function () {
            return {
                init: function (_combo) {
                    var yCombosAmount = Math.ceil($(document).height() / _combo.height()),
                        comboTags = $(document.createElement('div')),
                        newCombo = null;

                    for (var a = 0; a < yCombosAmount-1; a += 1) {
                        newCombo = _combo.clone();
                        comboTags.append(newCombo); // <- still have to improve this crap
                    }

                    $('.nyan').prepend(comboTags.html());
                }
            }
        };

        $(function() {
            var nyancat = new NyanCat(),
                sparks = new Sparks();

            nyancat.init();
            sparks.init($('.sparks-combo'));

            var timer = setInterval(function () {
                nyancat.cycleFrames();
            }, 70);
            deferredTimer.resolve(timer);
        });
    `

  onDetach: ->
    super
    @_timer.then (t) -> clearInterval(t)
    clearInterval(@_countDownInterval)

  togglePlay: ->
    audio = $("audio")[0]
    if audio.paused
      audio.play()
    else
      audio.pause()

  _countDown: ->
    estimatedTime = (4 * 60 + 30) * 1000
    diff = new Date().getTime() - @_startTime
    minutes = Math.floor((estimatedTime - diff) / (60 * 1000))
    seconds = Math.floor((estimatedTime - diff) % (60 * 1000) / 1000)
    $('#countdown').text("#{Math.max(0, minutes)}:#{_.str.lpad(Math.max(0, seconds), 2, '0')}")