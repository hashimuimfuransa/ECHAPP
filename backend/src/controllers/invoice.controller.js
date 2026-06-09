const puppeteer = require('puppeteer');
const Payment = require('../models/Payment');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Generate and download invoice for a payment
const generateInvoice = async (req, res) => {
  try {
    const { paymentId } = req.params;
    
    console.log('generateInvoice called for payment ID:', paymentId);
    console.log('User ID:', req.user?.id);
    console.log('User role:', req.user?.role);

    // Find payment with populated data
    const payment = await Payment.findById(paymentId)
      .populate('userId', 'fullName email phone')
      .populate('courseId', 'title description price')
      .populate('adminApproval.approvedBy', 'fullName email');
    
    if (!payment) {
      console.log('Payment not found with ID:', paymentId);
      return sendNotFound(res, 'Payment not found');
    }

    // Students can only download their own invoice; admins can download any
    const isAdmin = req.user?.role === 'admin';
    const isOwner = payment.userId?._id?.toString() === req.user?.id?.toString() ||
                    payment.userId?.toString() === req.user?.id?.toString();
    if (!isAdmin && !isOwner) {
      console.log('Access denied: user', req.user?.id, 'tried to access invoice for payment owned by', payment.userId);
      return res.status(403).json({ success: false, message: 'Access denied. You can only download your own invoice.' });
    }

    console.log('Payment found:', payment.transactionId, 'Status:', payment.status);

    // Generate PDF invoice
    const pdfBuffer = await generatePDFInvoice(payment);

    // Set response headers for PDF download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="invoice_${payment.transactionId}.pdf"`);
    res.setHeader('Content-Length', pdfBuffer.length);

    // Send the PDF
    res.send(pdfBuffer);
    console.log('Invoice generated successfully for payment:', payment.transactionId);

  } catch (error) {
    console.error('Error in generateInvoice:', error);
    sendError(res, 'Failed to generate invoice', 500, error.message);
  }
};

// Generate PDF invoice using Puppeteer
async function generatePDFInvoice(payment) {
  let browser;
  try {
    browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    
    // Generate HTML content for invoice
    const htmlContent = generateInvoiceHTML(payment);
    
    await page.setContent(htmlContent, { waitUntil: 'networkidle0' });
    
    // Generate PDF
    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: {
        top: '20mm',
        right: '20mm',
        bottom: '20mm',
        left: '20mm'
      }
    });
    
    await browser.close();
    return pdfBuffer;
    
  } catch (error) {
    if (browser) {
      await browser.close();
    }
    throw error;
  }
}

// Generate HTML content for invoice
function generateInvoiceHTML(payment) {
  const currentDate = new Date().toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  const paymentDate = payment.paymentDate 
    ? new Date(payment.paymentDate).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      })
    : 'Pending';

  const approvalDate = payment.adminApproval?.approvedAt
    ? new Date(payment.adminApproval.approvedAt).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      })
    : '';

  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Invoice - ${payment.transactionId}</title>
        <style>
            body {
                font-family: 'Arial', sans-serif;
                margin: 0;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .invoice-container {
                max-width: 800px;
                margin: 0 auto;
                background: white;
                padding: 40px;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .invoice-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                border-bottom: 2px solid #3498db;
                padding-bottom: 20px;
                margin-bottom: 30px;
            }
            .invoice-title {
                font-size: 28px;
                font-weight: bold;
                color: #2c3e50;
            }
            .invoice-number {
                font-size: 18px;
                color: #7f8c8d;
            }
            .company-info {
                margin-bottom: 30px;
            }
            .company-name {
                font-size: 24px;
                font-weight: bold;
                color: #2c3e50;
                margin-bottom: 5px;
            }
            .company-details {
                color: #7f8c8d;
                line-height: 1.6;
            }
            .billing-info {
                display: flex;
                justify-content: space-between;
                margin-bottom: 30px;
            }
            .billing-section {
                flex: 1;
            }
            .section-title {
                font-weight: bold;
                color: #2c3e50;
                margin-bottom: 10px;
                font-size: 16px;
            }
            .billing-details {
                color: #34495e;
                line-height: 1.6;
            }
            .invoice-table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 30px;
            }
            .invoice-table th {
                background-color: #3498db;
                color: white;
                padding: 12px;
                text-align: left;
                font-weight: bold;
            }
            .invoice-table td {
                padding: 12px;
                border-bottom: 1px solid #ecf0f1;
            }
            .invoice-table tr:nth-child(even) {
                background-color: #f8f9fa;
            }
            .amount {
                text-align: right;
                font-weight: bold;
                color: #2c3e50;
            }
            .total-section {
                display: flex;
                justify-content: flex-end;
                margin-bottom: 30px;
            }
            .total-box {
                background-color: #f8f9fa;
                padding: 20px;
                border-radius: 8px;
                border: 2px solid #3498db;
                min-width: 250px;
            }
            .total-row {
                display: flex;
                justify-content: space-between;
                margin-bottom: 10px;
            }
            .total-label {
                color: #7f8c8d;
            }
            .total-value {
                font-weight: bold;
                color: #2c3e50;
            }
            .grand-total {
                border-top: 2px solid #3498db;
                padding-top: 10px;
                margin-top: 10px;
            }
            .grand-total .total-label {
                font-weight: bold;
                color: #2c3e50;
            }
            .grand-total .total-value {
                font-size: 18px;
                color: #3498db;
            }
            .payment-info {
                background-color: #fff3cd;
                border: 1px solid #ffeaa7;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
            }
            .payment-status {
                display: inline-block;
                padding: 6px 12px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: bold;
                text-transform: uppercase;
                margin-bottom: 10px;
            }
            .status-pending {
                background-color: #fff3cd;
                color: #856404;
                border: 1px solid #ffeaa7;
            }
            .status-approved {
                background-color: #d4edda;
                color: #155724;
                border: 1px solid #c3e6cb;
            }
            .status-completed {
                background-color: #d1ecf1;
                color: #0c5460;
                border: 1px solid #bee5eb;
            }
            .status-failed {
                background-color: #f8d7da;
                color: #721c24;
                border: 1px solid #f5c6cb;
            }
            .status-cancelled {
                background-color: #e2e3e5;
                color: #383d41;
                border: 1px solid #d6d8db;
            }
            .footer {
                text-align: center;
                color: #7f8c8d;
                margin-top: 40px;
                padding-top: 20px;
                border-top: 1px solid #ecf0f1;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="invoice-container">
            <div class="invoice-header">
                <div>
                    <div class="invoice-title">INVOICE</div>
                    <div class="invoice-number">#${payment.transactionId}</div>
                </div>
                <div>
                    <div class="invoice-number">Date: ${currentDate}</div>
                </div>
            </div>

            <div class="company-info">
                <div class="company-name">Excellence Coaching Hub</div>
                <div class="company-details">
                    Kigali, Rwanda<br>
                    Email: info@excellencecoachinghub.com<br>
                    Phone: +250 788 535 156 / +250 793 828 834
                </div>
            </div>

            <div class="billing-info">
                <div class="billing-section">
                    <div class="section-title">BILL TO:</div>
                    <div class="billing-details">
                        <strong>${payment.userId?.fullName || 'Unknown User'}</strong><br>
                        ${payment.userId?.email || 'No email'}<br>
                        ${payment.userId?.phone || 'No phone'}
                    </div>
                </div>
                <div class="billing-section">
                    <div class="section-title">PAYMENT DETAILS:</div>
                    <div class="billing-details">
                        Payment Method: ${payment.paymentMethod}<br>
                        Payment Date: ${paymentDate}<br>
                        ${approvalDate ? `Approved: ${approvalDate}` : ''}
                    </div>
                </div>
            </div>

            <div class="payment-info">
                <div class="payment-status status-${payment.status}">${payment.status}</div>
                <div><strong>Transaction ID:</strong> ${payment.transactionId}</div>
                ${payment.adminApproval?.adminNotes ? `<div><strong>Admin Notes:</strong> ${payment.adminApproval.adminNotes}</div>` : ''}
            </div>

            <table class="invoice-table">
                <thead>
                    <tr>
                        <th>Description</th>
                        <th>Quantity</th>
                        <th>Unit Price</th>
                        <th class="amount">Total</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>${payment.courseId?.title || 'Unknown Course'}</td>
                        <td>1</td>
                        <td>${payment.amount} ${payment.currency}</td>
                        <td class="amount">${payment.amount} ${payment.currency}</td>
                    </tr>
                </tbody>
            </table>

            <div class="total-section">
                <div class="total-box">
                    <div class="total-row">
                        <span class="total-label">Subtotal:</span>
                        <span class="total-value">${payment.amount} ${payment.currency}</span>
                    </div>
                    <div class="total-row">
                        <span class="total-label">Tax (0%):</span>
                        <span class="total-value">0 ${payment.currency}</span>
                    </div>
                    <div class="total-row grand-total">
                        <span class="total-label">TOTAL:</span>
                        <span class="total-value">${payment.amount} ${payment.currency}</span>
                    </div>
                </div>
            </div>

            ${payment.adminApproval ? `
            <div class="payment-info">
                <div class="section-title">APPROVAL DETAILS:</div>
                <div><strong>Approved By:</strong> ${payment.adminApproval.approvedBy}</div>
                <div><strong>Approved At:</strong> ${approvalDate}</div>
                ${payment.adminApproval.adminNotes ? `<div><strong>Notes:</strong> ${payment.adminApproval.adminNotes}</div>` : ''}
            </div>
            ` : ''}

            <div class="footer">
                <div>Thank you for choosing Excellence Coaching Hub!</div>
                <div>This is a computer-generated invoice and does not require a signature.</div>
            </div>
        </div>
    </body>
    </html>
  `;
}

module.exports = {
  generateInvoice
};
