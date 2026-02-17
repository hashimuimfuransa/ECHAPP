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

        // Create PDF document
        const doc = new PDFDocument({
          size: 'A4',
          margin: 50
        });

        // Pipe to a writable stream
        const stream = fs.createWriteStream(filepath);
        doc.pipe(stream);

        // Add background design
        this.addBackground(doc);

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

        // Add footer
        this.addFooter(doc, certificateData);

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

  static addBackground(doc) {
    // Clean minimal background
    doc.fillColor('#ffffff')
       .rect(0, 0, doc.page.width, doc.page.height)
       .fill();
  }

  static async addHeaderWithLogo(doc) {
    // Add Excellence Coaching Hub branding
    doc.fontSize(20)
       .fillColor('#27ae60')
       .font('Helvetica-Bold')
       .text('EXCELLENCE COACHING HUB', {
         align: 'center'
       });

    doc.moveDown(0.5);
    
    doc.fontSize(12)
       .font('Helvetica')
       .fillColor('#7f8c8d')
       .text('Professional Learning & Certification', {
         align: 'center'
       });

    // Add a subtle line separator
    doc.moveDown(1);
    const yPosition = doc.y;
    doc.strokeColor('#ecf0f1')
       .lineWidth(1)
       .moveTo(50, yPosition)
       .lineTo(doc.page.width - 50, yPosition)
       .stroke();
       
    doc.moveDown(1);
  }

  static addTitle(doc) {
    doc.moveDown(2)
       .fontSize(28)
       .font('Helvetica-Bold')
       .fillColor('#2c3e50')
       .text('CERTIFICATE OF COMPLETION', {
         align: 'center'
       })
       .moveDown(1);

    doc.fontSize(14)
       .font('Helvetica')
       .fillColor('#7f8c8d')
       .text('This certificate acknowledges the successful completion of', {
         align: 'center'
       })
       .moveDown(1);
  }

  static addRecipientInfo(doc, data) {
    doc.fontSize(24)
       .font('Helvetica-Bold')
       .fillColor('#27ae60')
       .text(data.studentName || data.userFullName, {
         align: 'center'
       })
       .moveDown(1);

    doc.fontSize(16)
       .font('Helvetica')
       .fillColor('#34495e')
       .text('has demonstrated proficiency in', {
         align: 'center'
       })
       .moveDown(2);
  }

  static addCourseInfo(doc, data) {
    doc.fontSize(18)
       .font('Helvetica-Bold')
       .fillColor('#2980b9')
       .text(data.courseTitle, {
         align: 'center'
       })
       .moveDown(1);

    if (data.courseDescription) {
      doc.fontSize(12)
         .font('Helvetica')
         .fillColor('#7f8c8d')
         .text(data.courseDescription.substring(0, 100) + '...', {
           align: 'center',
           width: 400
         })
         .moveDown(2);
    }
  }

  static addExamScoreInfo(doc, data) {
    doc.moveDown(1);
    
    // Create a box for the score information
    const boxX = (doc.page.width - 250) / 2;
    const boxY = doc.y;
    const boxWidth = 250;
    const boxHeight = 60;
    
    doc.rect(boxX, boxY, boxWidth, boxHeight)
       .lineWidth(1)
       .strokeColor('#bdc3c7')
       .stroke();
       
    doc.fillColor('#f8f9fa')
       .rect(boxX, boxY, boxWidth, boxHeight)
       .fill();
       
    // Score details inside the box
    doc.x = boxX + 10;
    doc.y = boxY + 10;
    
    doc.fontSize(12)
       .font('Helvetica-Bold')
       .fillColor('#2c3e50')
       .text('Achievement Details:', {
         continued: true
       })
       .fillColor('#7f8c8d')
       .text(` Score: ${data.score}/${data.totalPoints} (${data.percentage.toFixed(2)}%)`, {
         continued: true
       })
       .fillColor('#27ae60')
       .text(` Grade: ${this.getGradeFromPercentage(data.percentage)}`);

    doc.x = boxX + 10;
    doc.fontSize(10)
       .fillColor('#7f8c8d')
       .text(`Date: ${new Date(data.issuedDate).toLocaleDateString('en-US', {
         year: 'numeric',
         month: 'short',
         day: 'numeric'
       })}`);

    doc.y = boxY + boxHeight + 20; // Move below the box
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
    doc.moveDown(2);
    
    // Verification section
    doc.fontSize(10)
       .fillColor('#7f8c8d')
       .text('Certificate Verification:', {
         align: 'center'
       });

    doc.moveDown(0.5);
    
    // Generate verification URL
    const verificationUrl = `${process.env.BASE_URL || 'https://excellencecoachinghub.com'}/verify-certificate/${data.serialNumber}`;
    
    // Add QR code if QRCode library is available
    if (QRCode) {
      try {
        // Generate QR code as data URL
        const qrBuffer = await QRCode.toBuffer(verificationUrl, { width: 150, margin: 1 });
        
        // Add QR code to the PDF
        const qrSize = 80;
        const qrX = (doc.page.width - qrSize) / 2;
        const qrY = doc.y + 10;
        
        // Draw the QR code image
        doc.image(qrBuffer, qrX, qrY, { width: qrSize, height: qrSize });
        
        doc.y = qrY + qrSize + 15;
        
        doc.fontSize(8)
           .fillColor('#95a5a6')
           .text('Scan QR code to verify authenticity', {
             align: 'center'
           });
      } catch (qrError) {
        console.log('Error generating QR code:', qrError);
        // If QR code generation fails, just show the URL
        doc.fontSize(8)
           .fillColor('#95a5a6')
           .text(`Verify at: ${verificationUrl}`, {
             align: 'center'
           });
           
        // Add a placeholder for the QR code
        const qrSize = 80;
        const qrX = (doc.page.width - qrSize) / 2;
        const qrY = doc.y + 10;
        
        doc.rect(qrX, qrY, qrSize, qrSize)
           .lineWidth(0.5)
           .strokeColor('#bdc3c7')
           .stroke();
           
        doc.fontSize(6)
           .fillColor('#95a5a6')
           .text('SCAN TO VERIFY', qrX + 10, qrY + 35, {
             width: qrSize - 20,
             align: 'center'
           });
           
        doc.y = qrY + qrSize + 10;
      }
    } else {
      // If QRCode library is not available, just show the URL
      doc.fontSize(8)
         .fillColor('#95a5a6')
         .text(`Verify at: ${verificationUrl}`, {
           align: 'center'
         });
         
      // Add a placeholder for the QR code
      const qrSize = 80;
      const qrX = (doc.page.width - qrSize) / 2;
      const qrY = doc.y + 10;
      
      doc.rect(qrX, qrY, qrSize, qrSize)
         .lineWidth(0.5)
         .strokeColor('#bdc3c7')
         .stroke();
         
      doc.fontSize(6)
         .fillColor('#95a5a6')
         .text('SCAN TO VERIFY', qrX + 10, qrY + 35, {
           width: qrSize - 20,
           align: 'center'
         });
         
      doc.y = qrY + qrSize + 10;
    }
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