var music, playBtn, currentTime, duration;

$(function() {
    music = document.querySelector('.music-element')
    playBtn = document.querySelector('.play')
    currentTime = document.querySelector('.current-time')
    duration = document.querySelector('.duration')
});

function handlePlay() {
    if (music.paused) {
        music.play();
        playBtn.className = 'pause'
        playBtn.innerHTML = '<i class="fas fa-pause"></i>'
    } else {
        music.pause();
        playBtn.className = 'play'
        playBtn.innerHTML = '<i class="fas fa-play"></i>'
    }
    music.addEventListener('ended', function () {
        playBtn.className = 'play'
        playBtn.innerHTML = '<i class="fas fa-play"></i>'
        music.currentTime = 0
    });
}

