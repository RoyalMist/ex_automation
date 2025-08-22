import sharp from 'sharp';
import fs from 'fs';

async function convertSvgToIco() {
  try {
    // Read the SVG file
    const svgBuffer = fs.readFileSync('./priv/static/images/favicon.svg');
    
    // Convert SVG to ICO with multiple sizes
    const sizes = [16, 24, 32, 48, 64, 128, 256];
    const images = [];
    
    for (const size of sizes) {
      const pngBuffer = await sharp(svgBuffer)
        .resize(size, size)
        .png()
        .toBuffer();
      
      images.push({
        size: size,
        buffer: pngBuffer
      });
    }
    
    // Note: This is a simplified approach. For proper ICO generation,
    // you would need a library like 'to-ico' or similar
    console.log('SVG converted to PNG buffers for ICO creation');
    console.log('Sizes generated:', sizes);
    
    // For now, let's create a 32x32 PNG favicon as fallback
    const favicon32 = await sharp(svgBuffer)
      .resize(32, 32)
      .png()
      .toFile('./priv/static/favicon.png');
      
    console.log('Created favicon.png (32x32)');
    
  } catch (error) {
    console.error('Error converting SVG:', error);
  }
}

convertSvgToIco();