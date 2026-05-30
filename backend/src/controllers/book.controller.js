const Book = require('../models/Book');
const s3Service = require('../services/s3.service');
const { sendSuccess, sendError } = require('../utils/response.utils');
const pdfParse = require('pdf-parse');

// Create a new book
const createBook = async (req, res) => {
  try {
    const { title, author, description, language, subject, academicCategory, pdfUrl, pdfS3Key, coverUrl, coverS3Key, fileSize, pages, relatedCourses, textContent } = req.body;

    // Validate required fields
    if (!title || !author || !pdfUrl || !pdfS3Key) {
      return sendError(res, 'Missing required fields: title, author, pdfUrl, pdfS3Key', 400);
    }

    const book = await Book.create({
      title,
      author,
      description,
      pdfUrl,
      pdfS3Key,
      coverUrl,
      coverS3Key,
      language: language || 'en',
      subject: subject || 'Other',
      academicCategory,
      relatedCourses: relatedCourses || [],
      uploadedBy: req.user.id,
      fileSize,
      pages,
      textContent,
      isPublished: true
    });

    sendSuccess(res, book, 'Book created successfully');
  } catch (error) {
    console.error('Create book error:', error);
    sendError(res, 'Failed to create book', 500, error.message);
  }
};

// Get all books (for library)
const getAllBooks = async (req, res) => {
  try {
    const { subject, language, search, page = 1, limit = 20 } = req.query;

    const query = { isPublished: true };

    if (subject && subject !== 'All') {
      query.subject = subject;
    }

    if (language && language !== 'All') {
      query.language = language;
    }

    if (search) {
      query.$text = { $search: search };
    }

    const skip = (page - 1) * limit;

    const books = await Book.find(query)
      .populate('uploadedBy', 'fullName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Book.countDocuments(query);

    sendSuccess(res, {
      books,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    }, 'Books retrieved successfully');
  } catch (error) {
    console.error('Get all books error:', error);
    sendError(res, 'Failed to retrieve books', 500, error.message);
  }
};

// Get all books for admin (including unpublished)
const getAllBooksForAdmin = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const skip = (page - 1) * limit;

    const books = await Book.find()
      .populate('uploadedBy', 'fullName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Book.countDocuments();

    sendSuccess(res, {
      books,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    }, 'Books retrieved successfully');
  } catch (error) {
    console.error('Get all books for admin error:', error);
    sendError(res, 'Failed to retrieve books', 500, error.message);
  }
};

// Get a single book by ID
const getBookById = async (req, res) => {
  try {
    const book = await Book.findById(req.params.id).populate('uploadedBy', 'fullName email');

    if (!book) {
      return sendError(res, 'Book not found', 404);
    }

    // Increment download count
    book.downloadCount += 1;
    await book.save();

    sendSuccess(res, book, 'Book retrieved successfully');
  } catch (error) {
    console.error('Get book by ID error:', error);
    sendError(res, 'Failed to retrieve book', 500, error.message);
  }
};

// Update a book
const updateBook = async (req, res) => {
  try {
    const { title, author, description, language, subject, academicCategory, coverUrl, coverS3Key, isPublished, pages } = req.body;

    const book = await Book.findById(req.params.id);

    if (!book) {
      return sendError(res, 'Book not found', 404);
    }

    // Update fields
    if (title) book.title = title;
    if (author) book.author = author;
    if (description !== undefined) book.description = description;
    if (language) book.language = language;
    if (subject) book.subject = subject;
    if (academicCategory !== undefined) book.academicCategory = academicCategory;
    if (coverUrl !== undefined) book.coverUrl = coverUrl;
    if (coverS3Key !== undefined) book.coverS3Key = coverS3Key;
    if (isPublished !== undefined) book.isPublished = isPublished;
    if (pages !== undefined) book.pages = pages;

    await book.save();

    sendSuccess(res, book, 'Book updated successfully');
  } catch (error) {
    console.error('Update book error:', error);
    sendError(res, 'Failed to update book', 500, error.message);
  }
};

// Delete a book
const deleteBook = async (req, res) => {
  try {
    const book = await Book.findById(req.params.id);

    if (!book) {
      return sendError(res, 'Book not found', 404);
    }

    // Delete PDF from S3
    if (book.pdfS3Key) {
      try {
        await s3Service.deleteFile(book.pdfS3Key);
      } catch (s3Error) {
        console.error('Failed to delete PDF from S3:', s3Error);
      }
    }

    // Delete cover from S3 if exists
    if (book.coverS3Key) {
      try {
        await s3Service.deleteFile(book.coverS3Key);
      } catch (s3Error) {
        console.error('Failed to delete cover from S3:', s3Error);
      }
    }

    await Book.findByIdAndDelete(req.params.id);

    sendSuccess(res, null, 'Book deleted successfully');
  } catch (error) {
    console.error('Delete book error:', error);
    sendError(res, 'Failed to delete book', 500, error.message);
  }
};

// Get books by course ID
const getBooksByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { page = 1, limit = 20 } = req.query;

    const skip = (page - 1) * limit;

    const query = {
      isPublished: true,
      relatedCourses: courseId
    };

    const books = await Book.find(query)
      .populate('uploadedBy', 'fullName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Book.countDocuments(query);

    sendSuccess(res, {
      books,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    }, 'Books retrieved successfully');
  } catch (error) {
    console.error('Get books by course error:', error);
    sendError(res, 'Failed to retrieve books', 500, error.message);
  }
};

// Upload book PDF and cover
const uploadBookFiles = async (req, res) => {
  try {
    const multer = require('multer');
    const storage = multer.memoryStorage();
    const upload = multer({
      storage,
      limits: {
        fileSize: 50 * 1024 * 1024 // 50MB limit for PDF
      }
    });

    upload.fields([
      { name: 'pdf', maxCount: 1 },
      { name: 'cover', maxCount: 1 }
    ])(req, res, async function (err) {
      if (err) {
        console.error('Multer error:', err);
        return sendError(res, err.message, 400);
      }

      const pdfFile = req.files['pdf'] ? req.files['pdf'][0] : null;
      const coverFile = req.files['cover'] ? req.files['cover'][0] : null;

      if (!pdfFile) {
        return sendError(res, 'PDF file is required', 400);
      }

      try {
        // Extract text from PDF
        let extractedText = null;
        try {
          const pdfData = await pdfParse(pdfFile.buffer);
          extractedText = pdfData.text;
        } catch (pdfError) {
          console.error('PDF text extraction failed:', pdfError);
          // Continue without text extraction
        }

        // Upload PDF
        const pdfResult = await s3Service.uploadDocument(
          pdfFile.buffer,
          pdfFile.originalname,
          pdfFile.mimetype
        );

        let coverResult = null;
        if (coverFile) {
          coverResult = await s3Service.uploadImage(
            coverFile.buffer,
            coverFile.originalname,
            coverFile.mimetype
          );
        }

        sendSuccess(res, {
          pdfUrl: pdfResult.url,
          pdfS3Key: pdfResult.key,
          coverUrl: coverResult ? coverResult.url : null,
          coverS3Key: coverResult ? coverResult.key : null,
          fileSize: pdfFile.size,
          textContent: extractedText
        }, 'Book files uploaded successfully');
      } catch (s3Error) {
        console.error('S3 upload error:', s3Error);
        sendError(res, 'Failed to upload files to storage', 500, s3Error.message);
      }
    });
  } catch (error) {
    console.error('Upload book files error:', error);
    sendError(res, 'Failed to upload book files', 500, error.message);
  }
};

module.exports = {
  createBook,
  getAllBooks,
  getAllBooksForAdmin,
  getBookById,
  getBooksByCourse,
  updateBook,
  deleteBook,
  uploadBookFiles
};
