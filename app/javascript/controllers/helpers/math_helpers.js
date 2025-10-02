// Math helpers for photo grid calculations
export class MathHelpers {
  // Calculate factors of an integer (prime factorization support)
  static factors(num) {
    const result = [];
    for (let i = 1; i <= num; i++) {
      if (num % i === 0) {
        result.push(i);
      }
    }
    return result;
  }

  // Binary search to find best aspect ratio match
  static findNearestAspectFactor(size, targetAspect) {
    const factors = this.factors(size);
    let high = factors.length - 1;
    let low = 0;
    let nearestIndex = 0;
    let nearestDistance = null;

    while (high >= low) {
      const index = Math.floor((low + high) / 2);
      const distance = (factors[index] / (size / factors[index])) - targetAspect;

      if (nearestDistance === null || nearestDistance > Math.abs(distance)) {
        nearestIndex = index;
        nearestDistance = Math.abs(distance);
      }

      if (distance < 0) {
        low = index + 1;
      } else if (distance > 0) {
        high = index - 1;
      } else {
        break;
      }
    }

    return {
      height: factors[nearestIndex],
      width: size / factors[nearestIndex]
    };
  }

  // Calculate default dimensions for a photo
  static calculateDefaultDimensions(size, imageWidth, imageHeight, customAspect = false, currentWidth = 1, currentHeight = 1) {
    const width = currentWidth || 1;
    const height = currentHeight || 1;

    // If dimensions already match size, return as-is
    if (width * height === size) {
      return { width, height };
    }

    // Determine target aspect ratio
    const targetAspect = customAspect
      ? height / width
      : imageHeight / imageWidth;

    // Find nearest factor match
    return this.findNearestAspectFactor(size, targetAspect);
  }
}
