OscIn oin;

6449 => oin.port;
oin.listenAll();

OscSend send;

setupRelay();

fun void setupRelay() {
    send.setHost("localhost", 12000);
}

OscMsg msg;

while(true)
{
    oin => now;

    while(oin.recv(msg))
    {
        chout <= msg.address <= " ";
        send.startMsg(msg.address, msg.typetag);
        for(int n; n < msg.numArgs(); n++)
        {
            if(msg.typetag.charAt(n) == 'i') {
                chout <= msg.getInt(n) <= " ";
                msg.getInt(n) => send.addInt;
            }
            else if(msg.typetag.charAt(n) == 'f') {
                chout <= msg.getFloat(n) <= " ";
                msg.getFloat(n) => send.addFloat;
            }
            else if(msg.typetag.charAt(n) == 's') {
                chout <= msg.getString(n) <= " ";
                msg.getString(n) => send.addString;
            }
        }

        chout <= IO.nl();
    }


}