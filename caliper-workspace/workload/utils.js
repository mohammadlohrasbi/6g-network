const generateRandomID = (prefix, max) => {
    return `${prefix}${Math.floor(Math.random() * max)}`;
};

const generateRandomCoords = () => {
    const x = (Math.random() * 180 - 90).toFixed(4); // Latitude [-90, 90]
    const y = (Math.random() * 360 - 180).toFixed(4); // Longitude [-180, 180]
    return { x, y };
};

module.exports = { generateRandomID, generateRandomCoords };
