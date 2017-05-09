OscSend xmitters[6];
Track tracks[6];

initNetwork();
main();

fun void main() {
    tracks[0].init(0, xmitters[0], 100);
    tracks[0].play();

    tracks[1].init(1, xmitters[1], 100);
    tracks[1].play();

    tracks[2].init(2, xmitters[2], 100);
    tracks[2].play();

    while (true) 1::second => now;
}

fun void initNetwork() {
    // host name and port
    string HOSTS[0];
    6449 => int port;

    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";

    HOSTS.size() => int nHosts;

    // send object
    OscSend xmit[nHosts];

    // aim the transmitter
    for (0 => int i; i < nHosts; i++) {
        xmit[i].setHost(HOSTS[i], port + i);
    }

    xmit @=> xmitters;
}