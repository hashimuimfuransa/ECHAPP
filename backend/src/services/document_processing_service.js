const axios = require('axios');
const FormData = require('form-data');
const mammoth = require('mammoth');

// Polyfill for DOMMatrix in Node.js environment
if (typeof DOMMatrix === 'undefined') {
  global.DOMMatrix = require('dommatrix');
}



class DocumentProcessingService {
  /**
   * Extract text content from a document buffer
   * @param {Buffer} buffer - The document buffer
   * @param {string} mimeType - The MIME type of the document
   * @returns {Promise<string>} - The extracted text content
   */
  async extractTextFromDocument(buffer, mimeType) {
    try {
      if (mimeType.includes('pdf')) {
        // Parse PDF document using pdfjs-dist legacy build for Node.js
        const { getDocument } = await import('pdfjs-dist/legacy/build/pdf.mjs');
        
        // Convert Buffer to Uint8Array for pdfjs-dist
        const uint8Array = new Uint8Array(buffer);
        const loadingTask = getDocument({ data: uint8Array });
        const pdf = await loadingTask.promise;

        let text = '';
        for (let i = 1; i <= pdf.numPages; i++) {
          const page = await pdf.getPage(i);
          const content = await page.getTextContent();
          text += content.items.map(item => item.str).join(' ') + '\n';
        }
        return text;
      } else if (mimeType.includes('text/plain')) {
        // For text files, we can directly decode the buffer
        return buffer.toString('utf8');
      } else if (mimeType.includes('application/vnd.openxmlformats-officedocument.wordprocessingml.document') || mimeType.includes('officedocument')) {
        // For DOCX files, use mammoth to extract text
        // Use a more robust extraction that preserves more structure if possible
        const result = await mammoth.extractRawText({buffer: buffer});
        if (result.messages.length > 0) {
          console.warn('Mammoth extraction messages:', result.messages);
        }
        return result.value;
      } else if (mimeType.includes('application/msword') || mimeType.includes('ms-word')) {
        // For older DOC files
        // We attempt to extract what we can using mammoth in case it's actually a docx with a doc extension
        try {
          const result = await mammoth.extractRawText({buffer: buffer});
          return result.value;
        } catch (e) {
          console.warn('Mammoth failed for .doc file, trying string extraction');
          // Fallback: strip most non-printable characters and return what's left
          // This is a crude way to get some text from binary .doc files
          const text = buffer.toString('ascii').replace(/[^\x20-\x7E\n\r\t]/g, ' ');
          return text.replace(/\s\s+/g, ' ');
        }
      } else {
        // For other formats, try to decode as text
        return buffer.toString('utf8');
      }
    } catch (error) {
      console.error('Error extracting text from document:', error);
      throw new Error(`Failed to extract text from document: ${error.message}`);
    }
  }

  /**
   * Get document content from S3 by key
   * @param {string} s3Key - The S3 key of the document
   * @returns {Promise<Object>} - Object containing buffer and metadata
   */
  async getDocumentFromStorage(s3Key) {
    // In a real implementation, you would fetch the document from S3
    // For now, we'll return a mock implementation
    
    // This would normally fetch from S3 and return the buffer
    return {
      buffer: Buffer.from('Mock document content for testing'),
      mimeType: 'application/pdf',
      key: s3Key
    };
  }
}

module.exports = new DocumentProcessingService();