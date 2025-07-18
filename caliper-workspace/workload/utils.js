const generateRandomID = (prefix, max) => {
    return `${prefix}${Math.floor(Math.random() * max)}`;
};

const generateRandomCoords = (centerX = 0, centerY = 0, sideLength = 100) => {
    const halfSide = sideLength / 2;
    const x = (Math.random() * sideLength - halfSide + centerX).toFixed(4); // مختصات x در بازه [centerX - halfSide, centerX + halfSide]
    const y = (Math.random() * sideLength - halfSide + centerY).toFixed(4); // مختصات y در بازه [centerY - halfSide, centerY + halfSide]
    return { x, y };
};

module.exports = { generateRandomID, generateRandomCoords };
