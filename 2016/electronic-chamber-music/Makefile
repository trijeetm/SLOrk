CLASSES = class.interpolator.ck class.sample.ck class.metronome.ck class.channel.ck class.ks.ck class.ks-chord.ck class.snap.ck

test_classes: 
	chuck $(CLASSES)

music: 
	chuck $(CLASSES) client.ck

multi_music: 
	chuck --out:6 $(CLASSES) client.ck

snaps: 
	chuck $(CLASSES) snapstrument.ck

uninstrument: 
	rm -f mic-sample.wav
	chuck class.live-sampler.ck uninstrument.ck