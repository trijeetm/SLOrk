var config = {
    promptId: false,
    ws: {
        ip: "Trijeet.local",
        port: "8081"
    },
    frameRate: 32,
    audio: {
        env: {
            attackTime: 0.005,
            decayTime: 0.0,
            susPercent: 1,
            releaseTime: 0.2
        },
        noteOffset: 24
    },
    visual: {
        bg: {
            H: 0,
            S: 70,
            B: 100,
            alphaFactor: 0.5,
        },
        stroke: {
            width: 20,
            alpha: 0.2,
            scale: 10
        },
        moveWave: true,
        waveHeight: 200
    },
}
