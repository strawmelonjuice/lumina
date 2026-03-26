-record(spinner, {
    repeater :: repeatedly:repeater(parrot@internal@spinner:state()),
    frames :: glearray:array(binary()),
    current_text :: binary()
}).
