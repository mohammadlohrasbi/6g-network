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

module.exports = { generateRandomID, generateRandomCoords };
