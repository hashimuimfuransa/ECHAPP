// Debug script to check pending payments in the database
const Payment = require('./backend/src/models/Payment');

async function debugPendingPayments() {
    console.log('=== DEBUGGING PENDING PAYMENTS ===');
    
    try {
        // Get ALL pending payments
        const allPending = await Payment.find({ status: 'pending' })
            .populate('userId', 'fullName email')
            .populate('courseId', 'title price')
            .sort({ createdAt: -1 });
        
        console.log(`\nFound ${allPending.length} total pending payments:`);
        
        allPending.forEach((payment, index) => {
            console.log(`\n${index + 1}. Payment ID: ${payment._id}`);
            console.log(`   Transaction ID: ${payment.transactionId}`);
            console.log(`   User: ${payment.userId?.fullName || 'Unknown'} (${payment.userId?.email || 'No email'})`);
            console.log(`   Course: ${payment.courseId?.title || 'Unknown'}`);
            console.log(`   Amount: ${payment.amount} ${payment.currency}`);
            console.log(`   Status: ${payment.status}`);
            console.log(`   Created: ${payment.createdAt}`);
            console.log(`   Payment Method: ${payment.paymentMethod}`);
            console.log(`   Contact Info: ${payment.contactInfo}`);
        });
        
        // Check for payments with different statuses
        const statusCounts = await Payment.aggregate([
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 }
                }
            }
        ]);
        
        console.log('\n=== PAYMENT STATUS BREAKDOWN ===');
        statusCounts.forEach(item => {
            console.log(`${item._id}: ${item.count} payments`);
        });
        
        // Check recent payments (last 24 hours)
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const recentPayments = await Payment.find({ 
            createdAt: { $gte: yesterday }
        }).populate('userId', 'fullName email')
          .populate('courseId', 'title price')
          .sort({ createdAt: -1 });
        
        console.log(`\n=== RECENT PAYMENTS (Last 24 Hours) ===`);
        console.log(`Found ${recentPayments.length} recent payments:`);
        
        recentPayments.forEach((payment, index) => {
            console.log(`\n${index + 1}. ${payment.status.toUpperCase()}: ${payment.transactionId}`);
            console.log(`   User: ${payment.userId?.fullName || 'Unknown'}`);
            console.log(`   Course: ${payment.courseId?.title || 'Unknown'}`);
            console.log(`   Created: ${payment.createdAt}`);
        });
        
    } catch (error) {
        console.error('Debug script error:', error);
    }
    
    process.exit(0);
}

debugPendingPayments();
