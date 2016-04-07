CLASSES = class.interpolator.ck class.sample.ck class.metronome.ck class.channel.ck class.ks.ck class.ks-chord.ck class.gasp.ck

test_classes: 
	chuck $(CLASSES)

music: 
	chuck $(CLASSES) client.ck

multi_music: 
	chuck --out:8 $(CLASSES) client.ck