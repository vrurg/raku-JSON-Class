use v6.e.PREVIEW;
unit role JSON::Class::HOW::JSONified:ver($?DISTRIBUTION.meta<ver>):auth($?DISTRIBUTION.meta<auth>):api($?DISTRIBUTION.meta<api>) [::FROM Mu];

method json-FROM(Mu) is pure is raw { FROM }

method json-FROM-HOW(Mu --> Mu) is pure is raw handles<attributes> { FROM.HOW }