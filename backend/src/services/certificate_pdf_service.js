const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

// For QR code functionality, we'll need to install a QR code library
// Since we don't have one installed yet, we'll use a placeholder for now
// Install: npm install qrcode

let QRCode = null;
try {
  QRCode = require('qrcode');
} catch (e) {
  console.log('QRCode library not found. Please install with: npm install qrcode');
}

class CertificatePDFService {
  /**
   * Generate a professional certificate PDF
   * @param {Object} certificateData - Data for the certificate
   * @returns {Promise<string>} Path to the generated PDF file
   */
  static async generateCertificatePDF(certificateData) {
    return new Promise(async (resolve, reject) => {
      try {
        // Create certificates directory if it doesn't exist
        const certsDir = path.join(__dirname, '..', '..', 'certificates');
        if (!fs.existsSync(certsDir)) {
          fs.mkdirSync(certsDir, { recursive: true });
        }

        // Generate unique filename
        const filename = `certificate_${certificateData.userId}_${certificateData.examId}_${Date.now()}.pdf`;
        const filepath = path.join(certsDir, filename);

        // Create PDF document in landscape for a more professional feel
        const doc = new PDFDocument({
          size: 'A4',
          layout: 'landscape',
          margin: 0 // We'll manage margins manually for the border
        });

        // Pipe to a writable stream
        const stream = fs.createWriteStream(filepath);
        doc.pipe(stream);

        // Add background design and borders
        this.addBackgroundAndBorders(doc);

        // Add header with logo
        await this.addHeaderWithLogo(doc);

        // Add certificate title
        this.addTitle(doc);

        // Add recipient information
        this.addRecipientInfo(doc, certificateData);

        // Add course information
        this.addCourseInfo(doc, certificateData);

        // Add exam score information
        this.addExamScoreInfo(doc, certificateData);

        // Add verification section with QR code
        await this.addVerificationSection(doc, certificateData);

        // Finalize PDF
        doc.end();

        stream.on('finish', () => {
          resolve(filepath);
        });

        stream.on('error', (err) => {
          reject(err);
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  static addBackgroundAndBorders(doc) {
    const pageWidth = doc.page.width;
    const pageHeight = doc.page.height;

    // 1. Solid Background
    doc.fillColor('#ffffff')
       .rect(0, 0, pageWidth, pageHeight)
       .fill();

    // 2. Add decorative corner patterns (subtle)
    doc.save();
    doc.fillColor('#f0f4f8');
    
    // Top-left accent
    doc.circle(0, 0, 150).fill();
    // Bottom-right accent
    doc.circle(pageWidth, pageHeight, 150).fill();
    doc.restore();

    // 3. Double Border Design
    // Outer border (Deep Forest Green)
    doc.rect(20, 20, pageWidth - 40, pageHeight - 40)
       .lineWidth(3)
       .strokeColor('#1a3a3a')
       .stroke();

    // Inner decorative border (Gold-ish)
    doc.rect(30, 30, pageWidth - 60, pageHeight - 60)
       .lineWidth(1)
       .strokeColor('#d4af37')
       .stroke();
       
    // Corner ornaments (small gold squares)
    const corners = [
      [30, 30], [pageWidth - 30, 30],
      [30, pageHeight - 30], [pageWidth - 30, pageHeight - 30]
    ];
    
    doc.fillColor('#d4af37');
    corners.forEach(([x, y]) => {
      doc.rect(x - 5, y - 5, 10, 10).fill();
    });
  }

  static async addHeaderWithLogo(doc) {
    const pageWidth = doc.page.width;
    const logoPath = path.join(__dirname, '..', '..', '..', 'frontend', 'assets', 'logo.png');
    
    doc.y = 50;

    try {
      if (fs.existsSync(logoPath)) {
        doc.image(logoPath, (pageWidth - 80) / 2, 50, { width: 80 });
        doc.moveDown(6.5); // Increased space from 4.5 for better visual layout
      } else {
        console.warn('Logo not found at:', logoPath);
        doc.moveDown(2); // Increased from 1
      }
    } catch (err) {
      console.error('Error adding logo to PDF:', err);
      doc.moveDown(1);
    }

    doc.fontSize(22)
       .fillColor('#1a3a3a')
       .font('Helvetica-Bold')
       .text('EXCELLENCE COACHING HUB', {
         align: 'center'
       });

    doc.fontSize(10)
       .font('Helvetica')
       .fillColor('#7f8c8d')
       .text('Professional Learning & Certification Excellence', {
         align: 'center'
       });

    doc.moveDown(1);
  }

  static addTitle(doc) {
    doc.moveDown(0.5)
       .fontSize(36)
       .font('Helvetica-Bold')
       .fillColor('#2c3e50')
       .text('CERTIFICATE OF COMPLETION', {
         align: 'center',
         characterSpacing: 1
       });

    doc.moveDown(0.3)
       .fontSize(14)
       .font('Helvetica-Oblique')
       .fillColor('#7f8c8d')
       .text('This is to certify that', {
         align: 'center'
       })
       .moveDown(0.8);
  }

  static addRecipientInfo(doc, data) {
    const displayName = (data.studentName || data.userFullName || 'Valued Student').toUpperCase();
    
    doc.fontSize(34) // Slightly larger
       .font('Helvetica-Bold')
       .fillColor('#d4af37') // Gold for the name
       .text(displayName, {
         align: 'center',
         characterSpacing: 0.5
       })
       .moveDown(0.4);

    // Subtle underline for the name
    const pageWidth = doc.page.width;
    doc.strokeColor('#bdc3c7')
       .lineWidth(0.5)
       .moveTo(pageWidth/2 - 150, doc.y)
       .lineTo(pageWidth/2 + 150, doc.y)
       .stroke();

    doc.moveDown(0.5)
       .fontSize(16)
       .font('Helvetica')
       .fillColor('#34495e')
       .text('has successfully completed the professional course', {
         align: 'center'
       })
       .moveDown(0.8);
  }

  static addCourseInfo(doc, data) {
    doc.fontSize(24)
       .font('Helvetica-Bold')
       .fillColor('#1a3a3a')
       .text(data.courseTitle, {
         align: 'center'
       })
       .moveDown(0.5);
  }

  static addExamScoreInfo(doc, data) {
    doc.fontSize(12)
       .font('Helvetica')
       .fillColor('#7f8c8d')
       .text(`Achieved a score of ${data.percentage.toFixed(1)}% with Grade ${this.getGradeFromPercentage(data.percentage)}`, {
         align: 'center'
       });

    doc.moveDown(0.5)
       .fontSize(11)
       .fillColor('#95a5a6')
       .text(`Issued on ${new Date(data.issuedDate).toLocaleDateString('en-US', {
         year: 'numeric',
         month: 'long',
         day: 'numeric'
       })}`, {
         align: 'center'
       });
  }

  static getGradeFromPercentage(percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    return 'F';
  }

  static async addVerificationSection(doc, data) {
    const pageWidth = doc.page.width;
    const pageHeight = doc.page.height;
    const qrSize = 60;
    const qrX = (pageWidth - qrSize) / 2;
    const qrY = pageHeight - 110;

    // Generate verification URL - updated to the Flutter app domain
    const verificationUrl = `https://app.excellencecoachinghub.com/verify-certificate/${data.serialNumber}`;
    
    if (QRCode) {
      try {
        const qrBuffer = await QRCode.toBuffer(verificationUrl, { width: 120, margin: 1 });
        doc.image(qrBuffer, qrX, qrY, { width: qrSize, height: qrSize });
      } catch (qrError) {
        console.error('QR Error:', qrError);
      }
    }
    
    doc.fontSize(7)
       .fillColor('#95a5a6')
       .text(`Verify authenticity at: ${verificationUrl}`, 0, pageHeight - 45, { align: 'center' });
  }

  static drawSimpleQRCodePattern(doc, x, y, size) {
    // Draw a simplified QR code pattern
    const blockSize = size / 15; // 15x15 grid for simplicity
    
    // Draw finder patterns (corners)
    this.drawFinderPattern(doc, x, y, blockSize); // Top-left
    this.drawFinderPattern(doc, x + size - 7 * blockSize, y, blockSize); // Top-right
    this.drawFinderPattern(doc, x, y + size - 7 * blockSize, blockSize); // Bottom-left
    
    // Add some random blocks to simulate QR code pattern
    doc.fillColor('#000000');
    for (let row = 2; row < 13; row++) {
      for (let col = 2; col < 13; col++) {
        // Skip finder pattern areas
        if ((row < 7 && col < 7) || (row > 8 && col > 8) || (row < 7 && col > 8)) continue;
        
        // Randomly draw blocks to simulate QR code
        if (Math.random() > 0.7) { // Only draw ~30% of blocks
          doc.rect(x + col * blockSize, y + row * blockSize, blockSize, blockSize);
        }
      }
    }
    doc.fill();
  }
  
  static drawFinderPattern(doc, x, y, blockSize) {
    // Draw the 7x7 finder pattern
    doc.fillColor('#000000');
    for (let row = 0; row < 7; row++) {
      for (let col = 0; col < 7; col++) {
        // Outer square (black)
        if (row === 0 || row === 6 || col === 0 || col === 6) {
          doc.rect(x + col * blockSize, y + row * blockSize, blockSize, blockSize);
        }
        // Inner square (white with black border)
        else if (row > 0 && row < 6 && col > 0 && col < 6) {
          if (row === 1 || row === 5 || col === 1 || col === 5) {
            // White border
          } else if (row > 1 && row < 5 && col > 1 && col < 5) {
            if (row === 2 || row === 4 || col === 2 || col === 4) {
              // White inner
            } else {
              // Black center
              doc.rect(x + col * blockSize, y + row * blockSize, blockSize, blockSize);
            }
          }
        }
      }
    }
    doc.fill();
  }
  
  static addFooter(doc, data) {
    doc.y = doc.page.height - 50;
    doc.fontSize(8)
       .fillColor('#95a5a6')
       .text('© ' + new Date().getFullYear() + ' Excellence Coaching Hub. All rights reserved.', {
         align: 'center'
       })
       .moveDown(0.3)
       .text(`Certificate ID: ${data.serialNumber}`, {
         align: 'center'
       });
  }
}

module.exports = CertificatePDFService;