socat -v tcp-l:5556,reuseaddr,fork system:"printf \'HTTP/1.1 200 OK

Response on 5556\'",nofork
