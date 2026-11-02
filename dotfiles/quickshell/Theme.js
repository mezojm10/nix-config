.pragma library

// Tokyo Night (night)
const bg = "#1a1b26";
const bgDark = "#16161e";
const bgDeep = "#0f1017";
const surface = "#292e42";
const surfaceAlt = "#3b4261";
const overlay = "#414868";
const fg = "#c0caf5";
const fgDim = "#a9b1d6";
const comment = "#565f89";
const blue = "#7aa2f7";
const blueDark = "#3d59a1";
const cyan = "#7dcfff";
const magenta = "#bb9af7";
const purple = "#9d7cd8";
const green = "#9ece6a";
const teal = "#73daca";
const yellow = "#e0af68";
const orange = "#ff9e64";
const red = "#f7768e";

const font = "JetBrainsMono Nerd Font";
const iconFont = "JetBrainsMono Nerd Font";

function alpha(hex, a) {
    const aa = Math.round(Math.max(0, Math.min(1, a)) * 255)
        .toString(16)
        .padStart(2, "0");
    return "#" + aa + hex.slice(1);
}

function volumeIcon(volume, muted) {
    if (muted || volume <= 0) return "\u{f0581}";
    if (volume < 34) return "\u{f057f}";
    if (volume < 67) return "\u{f0580}";
    return "\u{f057e}";
}

function batteryIcon(percentage, charging) {
    if (charging) return "\u{f0084}";
    if (percentage >= 90) return "\u{f0079}";
    if (percentage >= 70) return "\u{f007a}";
    if (percentage >= 50) return "\u{f007b}";
    if (percentage >= 30) return "\u{f007c}";
    if (percentage >= 10) return "\u{f007d}";
    return "\u{f007e}";
}
