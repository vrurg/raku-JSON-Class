use v6.e.PREVIEW;
unit module JSON::Class::CX:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>);

class Cannot is X::Control {
    method message { "'cannot' control exception" }
}