const seedrandom = require('seedrandom');

const generateRandomID = (prefix, max) => {
    return `${prefix}${Math.floor(Math.random() * max)}`;
};

const generateRandomCoords = (centerX = 0, centerY = 0, sideLength = 100, seed = null) => {
    const rng = seed ? seedrandom(seed) : Math.random;
    const halfSide = sideLength / 2;
    const x = (rng() * sideLength - halfSide + centerX).toFixed(4);
    const y = (rng() * sideLength - halfSide + centerY).toFixed(4);
    return { x, y };
};

const calculateDistance = (x1, y1, x2, y2) => {
    const dx = parseFloat(x2) - parseFloat(x1);
    const dy = parseFloat(y2) - parseFloat(y1);
    return Math.sqrt(dx * dx + dy * dy).toFixed(4);
};

module.exports = { generateRandomID, generateRandomCoords, calculateDistance };
