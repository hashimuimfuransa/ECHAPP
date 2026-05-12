// Debug script to check specific user's payments
const Payment = require('./backend/src/models/Payment');
const User = require('./backend/src/models/User');

async function debugUserPayments() {
    console.log('=== DEBUGGING USER PAYMENTS ===');
    
    try {
        // Find a user who might have multiple payments
        // Let's look for users with multiple payments first
        const userPaymentCounts = await Payment.aggregate([
            {
                $group: {
                    _id: '$userId',
                    count: { $sum: 1 },
                    statuses: { $push: '$status' },
                    latestPayment: { $max: '$createdAt' }
                }
            },
            {
                $match: {
                    count: { $gt: 1 }
                }
            },
            {
                $sort: { count: -1 }
            }
        ]);
        
        console.log(`\nFound ${userPaymentCounts.length} users with multiple payments:`);
        
        for (const userCount of userPaymentCounts.slice(0, 5)) { // Show top 5
            console.log(`\nUser ID: ${userCount._id}`);
            console.log(`Total Payments: ${userCount.count}`);
            console.log(`Statuses: ${userCount.statuses.join(', ')}`);
            console.log(`Latest Payment: ${userCount.latestPayment}`);
            
            // Get all payments for this user
            const userPayments = await Payment.find({ userId: userCount._id })
                .populate('userId', 'fullName email')
                .populate('courseId', 'title price')
                .sort({ createdAt: -1 });
            
            console.log('Payment details:');
            userPayments.forEach((payment, index) => {
                console.log(`  ${index + 1}. ${payment.status.toUpperCase()} - ${payment.transactionId}`);
                console.log(`     Course: ${payment.courseId?.title || 'Unknown'}`);
                console.log(`     Amount: ${payment.amount} ${payment.currency}`);
                console.log(`     Created: ${payment.createdAt}`);
                console.log(`     User: ${payment.userId?.fullName || 'Unknown'} (${payment.userId?.email || 'No email'})`);
                console.log('');
            });
        }
        
        // Also check for any pending payments specifically
        console.log('\n=== ALL PENDING PAYMENTS ===');
        const pendingPayments = await Payment.find({ status: 'pending' })
            .populate('userId', 'fullName email')
            .populate('courseId', 'title price')
            .sort({ createdAt: -1 });
        
        console.log(`Found ${pendingPayments.length} pending payments:`);
        
        pendingPayments.forEach((payment, index) => {
            console.log(`\n${index + 1}. ${payment.transactionId}`);
            console.log(`   User: ${payment.userId?.fullName || 'Unknown'} (${payment.userId?.email || 'No email'})`);
            console.log(`   Course: ${payment.courseId?.title || 'Unknown'}`);
            console.log(`   Amount: ${payment.amount} ${payment.currency}`);
            console.log(`   Created: ${payment.createdAt}`);
            
            // Check if this user has other payments
            const otherPayments = await Payment.find({ 
                userId: payment.userId._id,
                _id: { $ne: payment._id }
            }).sort({ createdAt: -1 });
            
            if (otherPayments.length > 0) {
                console.log(`   User also has ${otherPayments.length} other payment(s):`);
                otherPayments.forEach((other, i) => {
                    console.log(`     ${i + 1}. ${other.status.toUpperCase()} - ${other.transactionId} (${other.createdAt})`);
                });
            }
        });
        
    } catch (error) {
        console.error('Debug script error:', error);
    }
    
    process.exit(0);
}

(async () => {
    await debugUserPayments();
})();
