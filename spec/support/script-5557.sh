socat -v tcp-l:5557,reuseaddr,fork system:"printf \'HTTP/1.1 200 OK

Response on 5557\'",nofork
